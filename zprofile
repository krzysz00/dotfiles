export PYENV_ROOT="$(realpath $HOME/.pyenv)"
RBENV_ROOT="$(realpath $HOME/.rbenv)"
THEROCK_ROOT="$(realpath $HOME/therock-nightly/install)"
typeset -U path
path=(~/progs/bin ~/.local/bin $THEROCK_ROOT/bin $RBENV_ROOT/bin $PYENV_ROOT/bin ~/therock-build/install/bin ~/.cargo/bin $path ~/progs/android/android/tools ~/progs/android/android/platform-tools)

typeset -T LD_LIBRARY_PATH ld_library_path
typeset -U ld_library_path

if [[ -d "$THEROCK_ROOT" ]]; then
   ld_library_path=($THEROCK_ROOT/lib $ld_library_path)
   export ROCM_CHIP=$($THEROCK_ROOT/bin/rocm_agent_enumerator | head -n 1)
fi
export LD_LIBRARY_PATH

export EDITOR="emacsclient"
export EMAIL="krzysdrewniak@gmail.com"

export PDFVIEWER=evince

if command -v rustc >&/dev/null 2>&1; then
    export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library"
fi

umask 022

export USER_ZPROFILE_IN_EFFECT=1
