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

HISTFILE=~/.config/zsh-hist
HISTSIZE=10000
SAVEHIST=10000
setopt autocd beep extendedglob correct dvorak inc_append_history
setopt sharehistory hist_ignore_dups hist_expire_dups_first hist_save_no_dups
setopt prompt_subst

typeset -U path
path=(~/progs/bin $path ~/progs/android/android/tools ~/progs/android/android/platform-tools)

bindkey -e

eval "`dircolors -b`"
eval "$(lesspipe)"
alias ls='ls --color=auto'
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
RPROMPT='${vcs_info_msg_0_}'

trunk="$HOME/Programing/lisp/motm/trunk/"
school="$HOME/Dropbox/fall-2015/"
: ~trunk ~school

export EDITOR="/usr/bin/emacs"
alias e='emacsclient -a=""'
export EMAIL="krzysdrewniak@gmail.com"
export ANDROID_HOME="$HOME/progs/android/android"
alias linelength='awk "length > 80 {print FILENAME \"(\" FNR \"): \" \$0}"'
if [[ $TERM = "xterm" ]]; then
    export TERM="xterm-256color"
fi

export GOPATH="$HOME/Programming/go"

umask 022

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

# GPG-agent stuff
# Move to .profile mutandis mutandis
if [[ -f "$HOME/.gnupg/gpg-agent-info-$(hostname)" ]]; then
    source "$HOME/.gnupg/gpg-agent-info-$(hostname)"
    export GPG_AGENT_INFO
fi

GPG_TTY=$(tty)
export GPG_TTY

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
