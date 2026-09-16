# Name the herdr tab after the running program (nvim, claude, ...), "zsh" when idle.
# Source from ~/.zshrc. No-op outside herdr.
[[ -n $HERDR_TAB_ID ]] || return

_herdr_tab_title() { herdr tab rename "$HERDR_TAB_ID" "$1" &>/dev/null &! }
_herdr_tab_title_preexec() { local w=(${(z)1}); _herdr_tab_title "${w[1]:t}" }
_herdr_tab_title_precmd() { _herdr_tab_title zsh }

autoload -Uz add-zsh-hook
add-zsh-hook preexec _herdr_tab_title_preexec
add-zsh-hook precmd _herdr_tab_title_precmd
