#!/usr/bin/env bash
f=$(readlink -f ~/.config/herdr/config.toml)
if grep -q '^mouse_capture = false' "$f"; then v=true; else v=false; fi
sed -i "s/^mouse_capture = .*/mouse_capture = $v/" "$f"
herdr server reload-config
