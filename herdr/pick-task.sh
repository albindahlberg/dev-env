#!/usr/bin/env bash
# herdr: fuzzy-pick a recipe/task/target from justfile, Taskfile or Makefile in
# $PWD (first found wins, in that order) and run it. Bound to prefix+j.
export PATH="$HOME/.cargo/bin:$PATH"
fz() { fzf -1 --bind=j:down,k:up,q:abort,one:accept; }

if   [[ -f justfile || -f Justfile || -f .justfile ]]; then
  just --chooser "fzf -1 --bind=j:down,k:up,q:abort,one:accept" --choose
  rc=$?
elif [[ -f Taskfile.yml || -f Taskfile.yaml || -f taskfile.yml || -f taskfile.yaml ]]; then
  t=$(task --list-all --json | jq -r '.tasks[].name' | fz) && task "$t"
  rc=$?
elif [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
  # ponytail: greps literal targets only, skips dot-targets and pattern rules
  t=$(make -pRrq : 2>/dev/null | awk -F: '/^[a-zA-Z0-9][^$#\/\t=%]*:([^=]|$)/{print $1}' | grep -vxE '[Mm]akefile|GNUmakefile' | sort -u | fz) && make "$t"
  rc=$?
else
  echo "no justfile/Taskfile/Makefile in $PWD"; rc=1
fi
[[ $rc -eq 0 ]] || read -rp 'press enter to close' _
