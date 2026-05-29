#!/usr/bin/env zsh
# ═══════════════════════════════════════════════════════════════
# Zoro Linux 10 — Zsh Prompt Theme (zoro-prompt)
# /etc/skel/.zshrc (append) or /etc/zsh/zshrc.d/zoro-prompt.zsh
# ═══════════════════════════════════════════════════════════════
# Powerline-style prompt with ⚔ sword prefix for Zsh
# Pure ANSI — no external dependencies required.
# ═══════════════════════════════════════════════════════════════

# Only set for interactive shells
[[ -o interactive ]] || return

# ── Enable Colours ───────────────────────────────────────────
autoload -U colors && colors

# ── VCS Info (Git) ───────────────────────────────────────────
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '●'
zstyle ':vcs_info:git:*' unstagedstr '○'
zstyle ':vcs_info:git:*' formats ' %F{#A8B5C8}[git:%b %c%u]%f'
zstyle ':vcs_info:git:*' actionformats ' %F{#A8B5C8}[git:%b|%a %c%u]%f'
zstyle ':vcs_info:*' enable git

# ── Prompt Definition ───────────────────────────────────────
# Format: [⚔ user@hostname] [~/path] [git:branch ✓/✗] ❯
PROMPT='%K{#2D6A4F}%F{#F5F5F0}%B ⚔ %n@%m %b%k%f '
PROMPT+='%F{#C9A84C}%B%~%b%f '
PROMPT+='${vcs_info_msg_0_}'
PROMPT+='%(?.%F{#52B788}.%F{#FF5555}✗%?)%f'
PROMPT+='%F{#52B788}❯%f '

# Right prompt: time
RPROMPT='%F{#A8B5C8}%T%f'

# ── Zsh Options ──────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt CORRECT
setopt EXTENDED_GLOB
setopt NOMATCH
setopt NOTIFY
setopt PROMPT_SUBST

# ── History ──────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=20000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# ── Completion ───────────────────────────────────────────────
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── Key Bindings ─────────────────────────────────────────────
bindkey -e  # Emacs key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[3~' delete-char

# ── Aliases ──────────────────────────────────────────────────
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
alias zfetch='zoro-fetch'
alias zharden='sudo zoro-harden'
alias zstatus='sudo zoro-harden --status'
