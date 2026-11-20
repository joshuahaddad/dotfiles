#!/usr/bin/env bash
# PostToolUse Edit|Write hook: flag leftover merge-conflict markers in the edited file (/insights 2026-11-07).
# Needs both <<<<<<< and >>>>>>> so markdown ======= underlines don't trip it. Exit 2 feeds stderr to Claude.
# With --copilot (Copilot CLI postToolUse on edit/create) it returns the message as additionalContext instead.
input=$(cat)
f=$(jq -r '(.toolArgs | if type == "string" then (fromjson? // {}) else . end) as $a
  | .tool_input.file_path // .tool_input.path // $a.path // .tool_response.filePath // empty' <<<"$input" 2>/dev/null)
[ -f "$f" ] || exit 0
# Copilot hooks have no matcher, so skip reads (view also carries a path)
[ "${1:-}" = --copilot ] && ! jq -e '.toolName | IN("edit", "create")' <<<"$input" >/dev/null && exit 0
if grep -qE '^<<<<<<< ' "$f" && grep -qE '^>>>>>>> ' "$f"; then
  msg="Conflict markers left in $f:
$(grep -nE '^(<<<<<<< |=======$|>>>>>>> )' "$f" | head -20)"
  if [ "${1:-}" = --copilot ]; then
    jq -n --arg m "$msg" '{additionalContext: $m}'
  else
    echo "$msg" >&2
    exit 2
  fi
fi
