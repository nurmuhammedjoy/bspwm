# originally created by https://github.com/Phinixprono123
setopt AUTO_CD INTERACTIVE_COMMENTS PRINT_EIGHT_BIT COMPLETE_IN_WORD \
       NO_BEEP NO_FLOW_CONTROL \
       SHARE_HISTORY EXTENDED_HISTORY HIST_VERIFY HIST_REDUCE_BLANKS \
       HIST_IGNORE_SPACE HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS

HISTFILE=~/.zsh_history
HISTSIZE=12000          # keep above SAVEHIST so dedup has headroom
SAVEHIST=10000

zmodload zsh/parameter zsh/terminfo 2>/dev/null

# Environment
typeset -U path fpath
path=($HOME/.cargo/bin $path)

export STARSHIP_LOG=error
export CARAPACE_BRIDGES='zsh'
export PROOT_NO_SECCOMP=1
# export EDITOR="nvim"

export SKIM_DEFAULT_COMMAND="fd --hidden --follow -j 5 ."
export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude .git -j 5 ."
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git -j 5 ."
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --info=inline \
  --border=rounded \
  --preview-window=right:55%:wrap \
  --color=bg+:-1,bg:-1,spinner:#fe8019,hl:#83a598 \
  --color=fg:#ebdbb2,header:#928374,info:#fabd2f,pointer:#fe8019 \
  --color=marker:#b8bb26,fg+:#fbf1c7,prompt:#fabd2f,hl+:#fb4934"

# Colored man pages
export LESS_TERMCAP_mb=$'\e[1;31m' LESS_TERMCAP_md=$'\e[1;36m' \
       LESS_TERMCAP_me=$'\e[0m'    LESS_TERMCAP_se=$'\e[0m' \
       LESS_TERMCAP_so=$'\e[1;33;44m' LESS_TERMCAP_ue=$'\e[0m' \
       LESS_TERMCAP_us=$'\e[1;32m'

# Cache
_ZC=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
ZCOMPDUMP=$_ZC/zcompdump-$ZSH_VERSION
[[ -d $_ZC ]] || mkdir -p $_ZC

# Plugin settings (must be set before the plugins load)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_STRATEGY=(completion)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1                 # bind once in _zsh_autosuggest_post, not every prompt
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# Aliases and helpers
if (( $+commands[lsd] )); then
  alias ls='lsd' ll='lsd -l' la='lsd -la' lt='lsd --tree'
fi
alias grep='grep --color=auto'
alias reload='exec zsh'
alias zup='zinit self-update && zinit update --all'

mkcd() { mkdir -p -- "$1" && cd -- "$1" }

zcache-clear() {
  command rm -rf -- ${_ZC:?}/*
  print "zsh caches cleared - run: reload"
}

zbench() {
  zmodload -F zsh/datetime p:EPOCHREALTIME
  local n=${1:-10} i t=$EPOCHREALTIME
  for (( i = 0; i < n; i++ )); do command zsh -ic exit; done
  printf '%.0f ms per launch (time to first prompt)\n' $(( (EPOCHREALTIME - t) / n * 1000 ))
}

# Keybindings
bindkey -e
[[ -n ${terminfo[khome]} ]] && bindkey ${terminfo[khome]} beginning-of-line
[[ -n ${terminfo[kend]}  ]] && bindkey ${terminfo[kend]}  end-of-line
bindkey '^[[3~'    delete-char
bindkey '^[[1;5C'  forward-word
bindkey '^[[1;5D'  backward-word

# Cached tool init
# Usage: _eval_cache <name> <command...>
# Regenerates only when the tool binary changes. Wipe with: zcache-clear
_eval_cache() {
  unsetopt WARN_CREATE_GLOBAL            # init scripts assign globals from inside this function
  local name=$1; shift
  (( $+commands[$1] )) || return 1       # skip when the tool is not installed
  local cache=$_ZC/$name.zsh bin=$commands[$1]

  if [[ ! -s $cache || $bin -nt $cache ]]; then
    if ! "$@" >| $cache.tmp 2>/dev/null || [[ ! -s $cache.tmp ]]; then
      command rm -f $cache.tmp
      return 1
    fi
    command mv -f $cache.tmp $cache
    zcompile -UR $cache 2>/dev/null
  fi
  source $cache
}

# Prompt init
# plain starship init zsh only prints a stub that re-runs starship on every
# startup. --print-full-init is the real script, so the cache actually saves a fork.
_eval_cache starship-full starship init zsh --print-full-init \
  || PROMPT='%F{blue}%~%f %# '

# Deferred init (runs right after the first prompt via zinit turbo)
# compinit: reuse the dump (-C), rebuild at most once every 24h
_zsh_compinit() {
  zmodload -F zsh/stat b:zstat 2>/dev/null
  zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null
  local -a st
  ZINIT[ZCOMPDUMP_PATH]=$ZCOMPDUMP
  if zstat -A st +mtime -- $ZCOMPDUMP 2>/dev/null && (( EPOCHSECONDS - st[1] < 86400 )); then
    ZINIT[COMPINIT_OPTS]=-C
    zicompinit
  else
    ZINIT[COMPINIT_OPTS]=-u
    zicompinit
    zcompile -UR $ZCOMPDUMP 2>/dev/null
  fi
  zicdreplay
  _zsh_late_init   # after compinit so fzf/zoxide/carapace compdef registers work
}

_zsh_zstyles() {
  zstyle ':completion:*' matcher-list \
      'm:{a-z}={A-Za-z}' \
      'r:|=*' \
      'l:|=* r:|=*'
  zstyle ':completion:*' menu select
  zstyle ':completion:*' use-cache yes
  zstyle ':completion:*' cache-path $_ZC/zcompcache
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':completion:*:git-checkout:*' sort false
  [[ -n $LS_COLORS ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
}

# Registers fzf, zoxide and carapace plus completion styles.
# Needs compinit first (zoxide/carapace call compdef), so it runs after zicompinit.
_zsh_late_init() {
  unsetopt WARN_CREATE_GLOBAL
  _eval_cache fzf      fzf --zsh
  _eval_cache zoxide   zoxide init zsh
  _eval_cache carapace carapace _carapace zsh
  # Optional: uncomment what you install (pkg install atuin direnv)
  # _eval_cache atuin  atuin init zsh --disable-up-arrow   # SQLite history + fuzzy Ctrl-R
  # _eval_cache direnv direnv hook zsh                     # per-directory env
  _zsh_zstyles    # after carapace so your styles win
}

_hss_bindings() {
  local k
  for k in '^[[A' '^[OA' ${terminfo[kcuu1]}; do bindkey $k history-substring-search-up;   done
  for k in '^[[B' '^[OB' ${terminfo[kcud1]}; do bindkey $k history-substring-search-down; done
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
}

# Termux gh-r binaries are glibc, run them through grun
_patina_activate() {
  if [[ -n $TERMUX_VERSION ]] && (( $+commands[grun] )); then
    zsh-patina() { grun "$(whence -p zsh-patina)" "$@" }
  fi
  eval "$(zsh-patina activate)"
}

# Start autosuggestions, then accept the suggestion with Ctrl-L
_zsh_autosuggest_post() {
  emulate -L zsh
  _zsh_autosuggest_start
  bindkey '^L' autosuggest-accept
}

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -r $ZINIT_HOME/zinit.zsh ]]; then
  command mkdir -p ${ZINIT_HOME:h}
  command git clone --depth=1 https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
fi

if [[ -r $ZINIT_HOME/zinit.zsh ]]; then
  source $ZINIT_HOME/zinit.zsh

  zinit ice wait'0a' lucid blockf atinit'_zsh_compinit' atpull'zinit creinstall -q .'
  zinit light zsh-users/zsh-completions

  zinit ice wait'0c' lucid atload'!_zsh_autosuggest_post'
  zinit light zsh-users/zsh-autosuggestions

  zinit ice wait'0c' lucid atload'_hss_bindings'
  zinit light zsh-users/zsh-history-substring-search

  zinit ice wait'0c' lucid as'program' from'gh-r' pick'zsh-patina-*/zsh-patina' atload'_patina_activate'
  zinit light michel-kraemer/zsh-patina
else
  # zinit unavailable (offline first run?), still provide a working shell
  autoload -Uz compinit && compinit -u -d $ZCOMPDUMP
  _zsh_late_init
fi
