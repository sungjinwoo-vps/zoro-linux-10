#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Zoro Linux 10 — zoro-fetch Login Script
# /etc/profile.d/zoro-fetch.sh
# ═══════════════════════════════════════════════════════════════
# Runs zoro-fetch on interactive login if a display/SSH is present.
# Conditional: only if $DISPLAY, $WAYLAND_DISPLAY set, or SSH session.

# Only for interactive shells
[[ $- != *i* ]] && return

# Only run once per session
[[ -n "$ZORO_FETCH_RAN" ]] && return
export ZORO_FETCH_RAN=1

# Check if we're in a graphical session or SSH
if [[ -n "$DISPLAY" ]] || [[ -n "$WAYLAND_DISPLAY" ]] || [[ -n "$SSH_CONNECTION" ]]; then
    if command -v zoro-fetch &>/dev/null; then
        zoro-fetch
    fi
fi
