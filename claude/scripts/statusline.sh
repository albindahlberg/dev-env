#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TOK_USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOK_MAX=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
fmt_k() { awk -v n="$1" 'BEGIN{ if(n>=1000) printf "%.0fk", n/1000; else printf "%d", n }'; }
TOK="$(fmt_k "$TOK_USED")/$(fmt_k "$TOK_MAX")"

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

NOW=$(date +%s)
fmt_reset() { local secs=$(( $1 - NOW )); [ "$secs" -lt 0 ] && secs=0; printf '%dh%02dm' $((secs/3600)) $(((secs%3600)/60)); }
FIVEH_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
FIVEH_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
SEVND_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
LIMITS=""
[ -n "$FIVEH_RESET" ] && LIMITS="5h ${YELLOW}${FIVEH_PCT:-0}%${RESET} resets ${YELLOW}$(fmt_reset "$FIVEH_RESET")${RESET}"
[ -n "$SEVND_PCT" ] && LIMITS="${LIMITS:+$LIMITS | }7d ${YELLOW}${SEVND_PCT}%${RESET}"

CACHE_T=""
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
LAST=$([ -f "$TRANSCRIPT" ] && tac "$TRANSCRIPT" | grep -m1 '"type":"assistant"')
if [ -n "$LAST" ]; then
  TS=$(echo "$LAST" | jq -r '.timestamp')
  TTL=$(echo "$LAST" | jq -r 'if (.message.usage.cache_creation.ephemeral_1h_input_tokens // 0) > 0 then 3600 else 300 end')
  LEFT=$(( $(date -d "$TS" +%s) + TTL - NOW ))
  if [ "$LEFT" -gt 0 ]; then
    CACHE_T="🔥 $((LEFT / 60))m$(printf '%02d' $((LEFT % 60)))s"
  else
    CACHE_T="🧊 cold"
  fi
fi

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

# Issues the branch's PR closes. gh is slow: read a cache, refresh stale ones in the background.
TIMEOUT=$(command -v timeout || command -v gtimeout)
PR=""; ISSUE_LABEL="🎫"
if [ -n "$BRANCH" ] && command -v gh > /dev/null; then
  KEY=$(printf '%s' "$DIR $(git -C "$DIR" branch --show-current 2>/dev/null)" | cksum | cut -d' ' -f1)
  CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/$KEY"
  mkdir -p "${CACHE%/*}"
  if [ ! -e "$CACHE" ] || [ $((NOW - $(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE"))) -gt 60 ]; then
    touch "$CACHE"  # ponytail: mark fresh first so concurrent renders don't pile up gh calls
    ( cd "$DIR" && ${TIMEOUT:+$TIMEOUT 10} gh pr view --json closingIssuesReferences -q \
        '[.closingIssuesReferences[]|"#\(.number)"]|join(", ")' \
        > "$CACHE.tmp" 2>/dev/null; mv -f "$CACHE.tmp" "$CACHE" ) > /dev/null 2>&1 &
  fi
  P=$(cat "$CACHE" 2>/dev/null)
  [ -n "$P" ] && PR=" | $ISSUE_LABEL $P"
fi

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH$PR"
COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ${TOK} | ${YELLOW}${COST_FMT}${RESET}${CACHE_T:+ | $CACHE_T}${LIMITS:+ | $LIMITS}"

