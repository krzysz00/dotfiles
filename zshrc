if [[ "$USER_ZPROFILE_IN_EFFECT" != 1 ]]; then
    source $HOME/.zprofile
fi

zstyle ':completion:*' auto-description 'arg is %d'
zstyle ':completion:*' completer _complete _ignored _correct _approximate _prefix
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*' file-sort name
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=** r:|=**' 'l:|=* r:|=*'
zstyle ':completion:*' max-errors 4 numeric
zstyle ':completion:*' preserve-prefix '//[^/]##/'
zstyle ':completion:*' prompt 'Corrected input (found %e errors)'
zstyle ':completion:*' verbose true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.config/zsh-cache

if [[ -d ~/amd-scripts/completions ]]; then
    fpath+=(~/amd-scripts/completions)
fi

autoload -Uz compinit
compinit
autoload -Uz bashcompinit
bashcompinit

# From picking apart the init.zsh code
test -r $HOME/.opam/opam-init/complete.zsh && . $HOME/.opam/opam-init/complete.zsh > /dev/null 2> /dev/null || true

HISTFILE=~/.config/zsh-hist
HISTSIZE=100000
SAVEHIST=100000
setopt autocd beep extendedglob correct dvorak inc_append_history
setopt sharehistory hist_ignore_dups hist_expire_dups_first hist_save_no_dups
setopt prompt_subst

bindkey -e

if whence dircolors >/dev/null; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
elif [[ "$TERM" != "dumb" ]]; then
    CLICOLOR=1
fi

eval "$(lesspipe)"
alias grep='grep --color=auto'
#alias ttyter='ttyter -readline -ansi -ssl -verify -vcheck -dostream'

autoload -U colors && colors
# VCS status
autoload -Uz vcs_info
zstyle ':vcs_info:*' actionformats "%{$fg[cyan]%}(%b|$a %{$bold_color$fg[red]%}%u%{$reset_color$fg[green]%}%c%{$fg[cyan]%})%m%{$reset_color%}"
zstyle ':vcs_info:*' formats "%{$fg[cyan]%}(%b%{$bold_color$fg[red]%}%u%{$reset_color$fg[green]%}%c%{$fg[cyan]%})%m%{$reset_color%}"
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b:%r'
zstyle ':vcs_info:*' unstagedstr '!'
zstyle ':vcs_info:*' stagedstr '*'
zstyle ':vcs_info:*' enable git cvs svn hg
zstyle ':vcs_info:git*' check-for-changes true
precmd () { vcs_info }

##prompt
function {
    local username=$(id -u -n)
    local user_part="%n@"
    if [[ "$username" == "krzys" || "$username" == "kdrewnia" ]]; then
        user_part=""
    fi
    PS1="%B%F{yellow}${user_part}%m %F{red}%~%F{blue} %T %F{green}%#%b%f "
}

# Directory alias factory
# Usage: [prefix] [suffix] [short name] [desc] [zsh mode] [zsh input]
# Note: no trailing / on prefix or suffix
kd__alias_branched_directory_factory() {
    emulate -L zsh
    setopt extendedglob
    local -a match mbegin mend
    local prefix="$1"
    local suffix="$2"
    local abbrev="$3"
    local desc="$4"
    shift 4
    if [[ $1 = d ]]; then
        if [[ $2 = (#b)($prefix/)([^/]##)/($suffix)(/*|) ]]; then
            typeset -ga reply
            reply=($abbrev:$match[2] $(( ${mend[3]} - ${mbegin[1]} + 1 )))
        else
            return 1
        fi
    elif [[ $1 = n ]]; then
        [[ $2 != (#b)($abbrev:(?*)) ]] && return 1
        typeset -ga reply
        reply=($prefix/$match[2]/$suffix)
    elif [[ $1 = c ]]; then
        local exp1
        local -a dirs
        dirs=($prefix/*/$suffix(/:s@$suffix@@:t))
        # Special-case workaround for iree/*/iree
        if [[ $suffix == "iree" ]]; then
          dirs=($prefix/*/$suffix(/:h:t))
        fi
        dirs=(${abbrev}:${^dirs})
        _wanted dynamic-dirs exp1 "dynamic $desc directory" compadd -S\] -a dirs
        return
    else
        return 1
    fi
    return 0
}

kd__alias_iree_compiler() {
    kd__alias_branched_directory_factory "$HOME/iree" "iree/compiler/src/iree/compiler" "ic" "IREE compiler source" "$1" "$2"
}
kd__alias_iree_source() {
    kd__alias_branched_directory_factory "$HOME/iree" "iree" "is" "IREE source tree" "$1" "$2"
}
kd__alias_iree_build() {
    kd__alias_branched_directory_factory "$HOME/iree" "build" "ib" "IREE build tree" "$1" "$2"
}
kd__alias_llvm_source() {
    kd__alias_branched_directory_factory "$HOME/llvm" "llvm-project" "ls" "LLVM source tree" "$1" "$2"
}
kd__alias_llvm_build() {
    kd__alias_branched_directory_factory "$HOME/llvm" "build" "lb" "LLVM build tree" "$1" "$2"
}

typeset -a zsh_directory_name_functions
if [[ -d "$HOME/iree/main/iree" ]]; then
    zsh_directory_name_functions+=(kd__alias_iree_compiler kd__alias_iree_source)
fi
if [[ -d "$HOME/iree/main/build" ]]; then
    zsh_directory_name_functions+=kd__alias_iree_build
fi
if [[ -d "$HOME/llvm/main/llvm-project" ]]; then
    zsh_directory_name_functions+=kd__alias_llvm_source
fi
if [[ -d "$HOME/llvm/main/build" ]]; then
    zsh_directory_name_functions+=kd__alias_llvm_build
fi


if [[ "$TERM" != eterm* ]]; then
    RPROMPT='${vcs_info_msg_0_}'
fi

if [[ "$TERM" == eterm-256color ]]; then
   PS1="\${vcs_info_msg_0_}$PS1"
fi

alias e='emacsclient -a=""'
alias linelength='awk "length > 80 {print FILENAME \"(\" FNR \"): \" \$0}"'
function llcmake() {
    pushd llvm && { cmake "$@" ; popd; }
}

if [[ $TERM = "xterm" ]]; then
    export TERM="xterm-direct"
fi

if [[ ! -v SSH_AUTH_SOCK ]] && command -v keychain &>/dev/null; then
    eval "$(keychain --eval --quiet)"
fi

export GPG_TTY=$(tty)

if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source $NVM_DIR/nvm.sh
    source $NVM_DIR/bash_completion
fi
