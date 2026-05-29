#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Zoro Linux 10 — Bash Prompt Theme (zoro-prompt)
# /etc/skel/.bashrc (append) or /etc/profile.d/zoro-prompt.sh
# ═══════════════════════════════════════════════════════════════
# Powerline-style prompt with ⚔ sword prefix
# Pure ANSI — no external dependencies required.
#
# Colours: Green bg for user, Gold for path, Silver for git
# ═══════════════════════════════════════════════════════════════

# Only set prompt for interactive shells
[[ $- != *i* ]] && return

# ── Colour Definitions (ANSI) ────────────────────────────────
__ZORO_FG_GREEN="\[\033[38;2;82;183;136m\]"     # #52B788 Blade Green
__ZORO_FG_DARK_GREEN="\[\033[38;2;45;106;79m\]"  # #2D6A4F Forest Green
__ZORO_FG_GOLD="\[\033[38;2;201;168;76m\]"       # #C9A84C Katana Gold
__ZORO_FG_SILVER="\[\033[38;2;168;181;200m\]"    # #A8B5C8 Blade Silver
__ZORO_FG_RED="\[\033[38;2;255;85;85m\]"         # Error red
__ZORO_FG_WHITE="\[\033[38;2;245;245;240m\]"     # #F5F5F0 Rice Paper
__ZORO_BG_GREEN="\[\033[48;2;45;106;79m\]"       # #2D6A4F Forest Green bg
__ZORO_BG_GOLD="\[\033[48;2;139;105;20m\]"       # #8B6914 Polished Steel bg
__ZORO_BG_SILVER="\[\033[48;2;50;50;60m\]"       # Dark bg for git segment
__ZORO_BOLD="\[\033[1m\]"
__ZORO_RESET="\[\033[0m\]"

# ── Git Status Function ─────────────────────────────────────
__zoro_git_info() {
    if ! command -v git &>/dev/null; then
        return
    fi

    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    if [[ -z "$branch" ]]; then
        return
    fi

    # Check for uncommitted changes
    local status_icon
    if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
        status_icon="✓"
    else
        status_icon="✗"
    fi

    echo " git:${branch} ${status_icon}"
}

# ── Prompt Command ───────────────────────────────────────────
__zoro_prompt_command() {
    local exit_code=$?

    # Exit code indicator
    local exit_indicator=""
    if [[ $exit_code -ne 0 ]]; then
        exit_indicator="${__ZORO_FG_RED}✗${exit_code} "
    fi

    # Git info
    local git_info
    git_info=$(__zoro_git_info)
    local git_segment=""
    if [[ -n "$git_info" ]]; then
        git_segment="${__ZORO_FG_SILVER}[${git_info}]${__ZORO_RESET} "
    fi

    # Shorten path (keep last 3 components)
    local short_path
    short_path=$(dirs +0)

    # Build prompt
    # Format: [⚔ user@hostname] [~/path] [git:branch ✓/✗] $
    PS1=""
    PS1+="${__ZORO_BG_GREEN}${__ZORO_FG_WHITE}${__ZORO_BOLD}"
    PS1+=" ⚔ \u@\h "
    PS1+="${__ZORO_RESET}"
    PS1+="${__ZORO_FG_DARK_GREEN}${__ZORO_RESET}"
    PS1+=" ${__ZORO_FG_GOLD}${__ZORO_BOLD}${short_path}${__ZORO_RESET} "
    PS1+="${git_segment}"
    PS1+="${exit_indicator}"
    PS1+="${__ZORO_FG_GREEN}❯${__ZORO_RESET} "
}

# ── Activate ─────────────────────────────────────────────────
PROMPT_COMMAND="__zoro_prompt_command"

# ── Zoro Aliases ─────────────────────────────────────────────
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'

# Zoro Linux specific aliases
alias zfetch='zoro-fetch'
alias zharden='sudo zoro-harden'
alias zstatus='sudo zoro-harden --status'

# ── History Configuration ────────────────────────────────────
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# ── Shell Options ────────────────────────────────────────────
shopt -s checkwinsize
shopt -s globstar 2>/dev/null || true
shopt -s autocd 2>/dev/null || true
