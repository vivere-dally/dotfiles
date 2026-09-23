/**
 * Pi runs through Node, so tmux cannot identify it from the foreground process.
 * Window options give the status line a stable name and a persistent signal that
 * the final agent run has settled and waits for the next user prompt.
 */

type LifecycleEvent =
  | "session_start"
  | "agent_start"
  | "agent_settled"
  | "ui_prompt_start"
  | "ui_prompt_end"
  | "session_shutdown";

export type PiTmux = {
  on(event: LifecycleEvent, handler: () => Promise<void>): void;
  exec(command: string, args: string[], options: { timeout: number }): Promise<unknown>;
};

const TIMEOUT_MS = 1000;

export default function registerTmuxStatus(pi: PiTmux) {
  const pane = process.env.TMUX_PANE;
  // Detached children inherit the pane variable, but only the interactive parent
  // owns the tab and knows when it actually waits for user input.
  if (!pane || process.env.PI_SUBAGENT_CHILD === "1") return;

  let warned = false;
  let agentActive = false;
  const tmux = async (args: string[]) => {
    try {
      await pi.exec("tmux", args, { timeout: TIMEOUT_MS });
    } catch (error) {
      // Status integration must never interrupt the agent if the tmux server exits.
      if (!warned) {
        warned = true;
        console.warn(`pi tmux status: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  };

  const setOption = (args: string[]) => tmux(["set-option", "-w", "-t", pane, "-q", ...args]);
  const setWaiting = (waiting: boolean) => {
    if (!waiting) return setOption(["@llm_agent_waiting", "0"]);
    // The focus hooks in tmux.conf clear the mark only when the user enters the
    // window. A window that is active in an attached session is already in view,
    // thus it gets no mark. tmux evaluates the check and the write as one command,
    // so a window switch between them cannot leave a stale mark.
    const mark = (value: string) => `set-option -w -t ${pane} -q @llm_agent_waiting ${value}`;
    return tmux(["if-shell", "-F", "-t", pane, "#{&&:#{window_active},#{session_attached}}", mark("0"), mark("1")]);
  };

  pi.on("session_start", async () => {
    await setOption(["@llm_agent_name", "pi"]);
    await setWaiting(true);
  });
  pi.on("agent_start", async () => {
    agentActive = true;
    await setWaiting(false);
  });
  pi.on("ui_prompt_start", async () => setWaiting(true));
  pi.on("ui_prompt_end", async () => setWaiting(!agentActive));
  pi.on("agent_settled", async () => {
    agentActive = false;
    await setWaiting(true);
  });
  pi.on("session_shutdown", async () => {
    await setOption(["-u", "@llm_agent_name"]);
    await setOption(["-u", "@llm_agent_waiting"]);
  });
}
