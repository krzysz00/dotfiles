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
autoload -Uz compinit
compinit

# From picking apart the init.zsh code
test -r $HOME/.opam/opam-init/complete.zsh && . $HOME/.opam/opam-init/complete.zsh > /dev/null 2> /dev/null || true

HISTFILE=~/.config/zsh-hist
HISTSIZE=10000
SAVEHIST=10000
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
PS1="%B%F{yellow}%n@%m %F{red}%~%F{blue} %T %F{green}%#%b%f "
if [[ "$TERM" != eterm* ]]; then
    RPROMPT='${vcs_info_msg_0_}'
fi

if [[ "$TERM" == eterm-256color ]]; then
   PS1="\${vcs_info_msg_0_}$PS1"
fi

alias csedir='sshfs -o reconnect tricycle.cs.washington.edu: $HOME/cse'
alias csedir_down='fusermount -u $HOME/cse'

school="$HOME/Dropbox/spring-2020/"
ssd="/ssdhome/$USER/"
: ~school ~ssd

alias e='emacsclient -a=""'
alias linelength='awk "length > 80 {print FILENAME \"(\" FNR \"): \" \$0}"'
if [[ $TERM = "xterm" ]]; then
    export TERM="xterm-256color"
fi

if [[ -s "$rvm_path/scripts/rvm" ]]; then
    source "$rvm_path/scripts/rvm"
elif [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
fi

if command -v pyenv &>/dev/null; then
    eval "$(pyenv init -)"
fi

if [[ ! -v SSH_AUTH_SOCK ]] && command -v keychain &>/dev/null; then
    eval "$(keychain --eval --quiet)"
fi

if [[ -v WSL_DISTRO_NAME ]] && [[ -v DISPLAY ]] && [[ -f ~/.Xresources ]]; then
    xrdb -merge ~/.Xresources
fi
