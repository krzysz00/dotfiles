typeset -U path
path=(~/progs/bin ~/.local/bin $path ~/progs/android/android/tools ~/progs/android/android/platform-tools /usr/local/heroku/bin ~/.rvm/bin)

export EDITOR="/usr/bin/emacs"
export EMAIL="krzysdrewniak@gmail.com"
export ANDROID_HOME="$HOME/progs/android/android"

export GOPATH="$HOME/Programming/go"
export PDFVIEWER=evince

umask 022

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

# GPG-agent stuff
# Move to .profile mutandis mutandis
if [[ -f "$HOME/.gnupg/gpg-agent-info-$(hostname)" ]]; then
    source "$HOME/.gnupg/gpg-agent-info-$(hostname)"
    export GPG_AGENT_INFO
fi
