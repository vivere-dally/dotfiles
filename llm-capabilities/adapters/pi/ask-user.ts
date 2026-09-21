/**
 * Pi keeps questions out of its core. This local tool gives the shared skills a
 * structured prompt without adding a skill that changes when they ask.
 */

type Option = {
  label: string;
  description?: string;
};

export type AskUserParams = {
  question: string;
  options: Option[];
};

export type AskUserResult = {
  content: Array<{ type: "text"; text: string }>;
  details: { question: string; answer: string | null; custom: boolean };
};

export type AskUserContext = {
  hasUI: boolean;
  ui: {
    select(title: string, options: string[]): Promise<string | undefined>;
    input(title: string, placeholder?: string): Promise<string | undefined>;
  };
};

export type AskUserTool = {
  name: string;
  label: string;
  description: string;
  parameters: object;
  executionMode: string;
  execute(
    toolCallId: string,
    params: AskUserParams,
    signal: AbortSignal | undefined,
    onUpdate: unknown,
    ctx: AskUserContext,
  ): Promise<AskUserResult>;
};

type Pi = {
  registerTool(tool: AskUserTool): void;
};

const parameters = {
  type: "object",
  properties: {
    question: { type: "string", description: "The question to ask" },
    options: {
      type: "array",
      minItems: 2,
      maxItems: 3,
      items: {
        type: "object",
        properties: {
          label: { type: "string", description: "Short option label" },
          description: { type: "string", description: "Effect of this option" },
        },
        required: ["label"],
        additionalProperties: false,
      },
    },
  },
  required: ["question", "options"],
  additionalProperties: false,
};

const result = (question: string, answer: string | null, custom: boolean): AskUserResult => ({
  content: [{ type: "text", text: answer === null ? "User cancelled the question" : `User answered: ${answer}` }],
  details: { question, answer, custom },
});

export default function registerAskUser(pi: Pi) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask user",
    description: "Ask one necessary question with choices and an optional free-form answer.",
    parameters,
    executionMode: "sequential",
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!ctx.hasUI) return result(params.question, null, false);

      const displayed = params.options.map((option) =>
        option.description ? `${option.label} — ${option.description}` : option.label,
      );
      const customLabel = displayed.includes("Type something") ? "Write another answer" : "Type something";
      const selected = await ctx.ui.select(params.question, [...displayed, customLabel]);
      if (selected === undefined) return result(params.question, null, false);

      if (selected === customLabel) {
        const answer = (await ctx.ui.input(params.question, "Your answer"))?.trim();
        return result(params.question, answer || null, true);
      }

      const index = displayed.indexOf(selected);
      return result(params.question, index >= 0 ? params.options[index].label : selected, false);
    },
  });
}
