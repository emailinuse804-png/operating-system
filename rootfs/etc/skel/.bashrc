# ═══════════════════════════════════════════════════════════════════════════
# SleekOS Bash Configuration
# ═══════════════════════════════════════════════════════════════════════════

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ─── History ─────────────────────────────────────────────────────────────
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# ─── Shell Options ───────────────────────────────────────────────────────
shopt -s checkwinsize
shopt -s globstar 2>/dev/null
shopt -s cdspell
shopt -s dirspell 2>/dev/null

# ─── Prompt ──────────────────────────────────────────────────────────────
# SleekOS-styled prompt with colors
if [[ $EUID -eq 0 ]]; then
    PS1='\[\033[38;5;196m\]\u\[\033[0m\]@\[\033[38;5;75m\]sleekos\[\033[0m\]:\[\033[38;5;141m\]\w\[\033[0m\]\$ '
else
    PS1='\[\033[38;5;75m\]\u\[\033[0m\]@\[\033[38;5;117m\]sleekos\[\033[0m\]:\[\033[38;5;141m\]\w\[\033[0m\]\$ '
fi

# ─── Aliases ─────────────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

# SleekOS shortcuts
alias ai='sleek-ai'
alias browser='firefox-esr &'
alias files='pcmanfm &'
alias settings='sleekos-settings &'
alias update='sudo apt update && sudo apt upgrade -y'
alias sysinfo='neofetch'

# Ollama shortcuts
alias models='ollama-models'
alias chat='ollama run llama3.2 2>/dev/null || echo "Run: ollama pull llama3.2"'

# ─── Functions ───────────────────────────────────────────────────────────
# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1"    ;;
            *.tar.gz)  tar xzf "$1"    ;;
            *.tar.xz)  tar xJf "$1"    ;;
            *.bz2)     bunzip2 "$1"    ;;
            *.rar)     unrar x "$1"    ;;
            *.gz)      gunzip "$1"     ;;
            *.tar)     tar xf "$1"     ;;
            *.tbz2)    tar xjf "$1"    ;;
            *.tgz)     tar xzf "$1"    ;;
            *.zip)     unzip "$1"      ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1"       ;;
            *)         echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ─── Colored man pages ──────────────────────────────────────────────────
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# ─── PATH ───────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ─── Welcome ────────────────────────────────────────────────────────────
if [[ -z "$SLEEKOS_WELCOMED" ]]; then
    echo -e "\033[38;5;75m"
    echo "  ╭─────────────────────────────────╮"
    echo "  │       Welcome to SleekOS        │"
    echo "  │       Type 'sysinfo' for        │"
    echo "  │       system information        │"
    echo "  ╰─────────────────────────────────╯"
    echo -e "\033[0m"
    export SLEEKOS_WELCOMED=1
fi
