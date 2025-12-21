#!/usr/bin/env zsh
set -euo pipefail

TAB=$'\t'

# hidden target fields (used only for switching)
TARGET_SPEC="#{session_name}${TAB}#{window_id}${TAB}#{pane_id}"

# visible display column (ORDER MATTERS HERE)
DISPLAY="[#{window_id}] | #{pane_current_command} | #{pane_current_path} | #{pane_title}"

LINE=$(
  tmux list-panes -a -F "${TARGET_SPEC}${TAB}${DISPLAY}" |
  fzf-tmux -p --delimiter=$'\t' --with-nth=4 --color=hl:2
) || exit 0

# split on tabs (safe)
local -a parts
parts=("${(@ps:\t:)LINE}")

session="${parts[1]}"
window="${parts[2]}"
pane="${parts[3]}"

# switch (order matters across sessions)
tmux switch-client -t "$session" \
  && tmux select-window -t "$window" \
  && tmux select-pane -t "$pane"
