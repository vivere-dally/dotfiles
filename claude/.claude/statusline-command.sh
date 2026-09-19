#!/usr/bin/env bash
# Claude Code status line: model · effort · context% · cost [· rate limit warning]

# Machines with ccstatusline (npm) installed get its richer line; the jq line
# below is the zero-dependency fallback, so settings.json can stay identical
# on every machine.
command -v ccstatusline >/dev/null 2>&1 && exec ccstatusline

jq -r '
  select(.context_window.used_percentage != null) |
  [
    (if .model.display_name then
       (.model.display_name | gsub("^Claude "; "") | ascii_downcase)
     elif .model.id then
       ((.model.id | sub("^claude-"; "") | split("[")[0] | split("-")) as $p |
        if ($p | length) >= 3 then "\($p[0]) \($p[1]).\($p[2])"
        else ($p | join(" ")) end)
     else "claude" end),
    (.effort.level // .model.effort // "-"),
    (.context_window.used_percentage | floor | tostring),
    (.cost.total_cost_usd // 0 | tostring),
    ([(.rate_limits.five_hour.used_percentage // 0),
      (.rate_limits.seven_day.used_percentage // 0)] | max | tostring)
  ] | join("|")
' | {
    IFS='|' read -r model effort ctx cost rl || exit 0
    cost_fmt=$(printf "%.2f" "$cost")
    parts="$model"
    [ "$effort" != "-" ] && parts="$parts · $effort"
    parts="$parts · ctx ${ctx}%"
    parts="$parts · \$${cost_fmt}"
    if [ "${rl%%.*}" -gt 80 ] 2>/dev/null; then
        parts="$parts · RL ${rl%%.*}%"
    fi
    printf "\033[2m%s\033[0m" "$parts"
}
