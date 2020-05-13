typeset -U path
path=(~/progs/bin ~/.local/bin ~/.cargo/bin $path ~/progs/android/android/tools ~/progs/android/android/platform-tools /usr/local/heroku/bin ~/.rvm/bin)

export EDITOR="/usr/bin/emacsclient"
export EMAIL="krzysdrewniak@gmail.com"
export ANDROID_HOME="$HOME/progs/android/android"

export GOPATH="$HOME/Programming/go"
export PDFVIEWER=evince

umask 022

test -r $HOME/.opam/opam-init/variables.sh && . $HOME/.opam/opam-init/variables.sh > /dev/null 2> /dev/null || true

# PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
