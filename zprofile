export PYENV_ROOT=$(realpath $HOME/.pyenv)
RVM_ROOT=$(realpath $HOME/.rvm)
typeset -U path
path=(~/progs/bin ~/.local/bin ~/.cargo/bin $path ~/progs/android/android/tools ~/progs/android/android/platform-tools $RVM_ROOT/bin $PYENV_ROOT/bin)

export EDITOR="/usr/bin/emacsclient"
export EMAIL="krzysdrewniak@gmail.com"
export ANDROID_HOME="$HOME/progs/android/android"

export GOPATH="$HOME/Programming/go"
export PDFVIEWER=evince

umask 022

test -r $HOME/.opam/opam-init/variables.sh && . $HOME/.opam/opam-init/variables.sh > /dev/null 2> /dev/null || true

if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
# PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
