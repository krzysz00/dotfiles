export PYENV_ROOT="$(realpath $HOME/.pyenv)"
RBENV_ROOT="$(realpath $HOME/.rbenv)"
typeset -U PATH path
path=(~/progs/bin ~/.local/bin ~/amd-scripts/bin $RBENV_ROOT/bin $PYENV_ROOT/bin ~/therock-build/install/bin ~/.cargo/bin $path ~/progs/android/android/tools ~/progs/android/android/platform-tools)

export EDITOR="emacsclient"
export EMAIL="krzysdrewniak@gmail.com"

export PDFVIEWER=evince

if command -v rustc >&/dev/null 2>&1; then
    export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library"
fi

umask 022

# Trick: drop directories that don't exist from $PATH
path=($^path(-/N))

export USER_ZPROFILE_IN_EFFECT=1
