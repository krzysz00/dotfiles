export PYENV_ROOT=$(realpath $HOME/.pyenv)
RBENV_ROOT=$(realpath $HOME/.rbenv)
typeset -U path
path=(~/progs/bin ~/.local/bin $RBENV_ROOT/bin $PYENV_ROOT/bin ~/.cargo/bin $path ~/progs/android/android/tools ~/progs/android/android/platform-tools)

export EDITOR="emacsclient"
export EMAIL="krzysdrewniak@gmail.com"
export ANDROID_HOME="$HOME/progs/android/android"

export GOPATH="$HOME/Programming/go"
export PDFVIEWER=evince

if command -v rustc >&/dev/null 2>&1; then
    export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library"
fi

umask 022

test -r $HOME/.opam/opam-init/variables.sh && . $HOME/.opam/opam-init/variables.sh > /dev/null 2> /dev/null || true

if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
fi

export USER_ZPROFILE_IN_EFFECT=1
