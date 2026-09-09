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
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

NOW=$(date +%s)
fmt_reset() { local secs=$(( $1 - NOW )); [ "$secs" -lt 0 ] && secs=0; printf '%dh%02dm' $((secs/3600)) $(((secs%3600)/60)); }
FIVEH_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
FIVEH_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
SEVND_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
LIMITS=""
[ -n "$FIVEH_RESET" ] && LIMITS="5h ${YELLOW}${FIVEH_PCT:-0}%${RESET} resets ${YELLOW}$(fmt_reset "$FIVEH_RESET")${RESET}"
[ -n "$SEVND_PCT" ] && LIMITS="${LIMITS:+$LIMITS | }7d ${YELLOW}${SEVND_PCT}%${RESET}"

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH"
COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ${TOK} | ${YELLOW}${COST_FMT}${RESET} | ⏱️ ${MINS}m ${SECS}s${LIMITS:+ | $LIMITS}"

