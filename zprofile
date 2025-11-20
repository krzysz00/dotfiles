export PYENV_ROOT="$(realpath $HOME/.pyenv)"
RBENV_ROOT="$(realpath $HOME/.rbenv)"
THEROCK_ROOT="$HOME/therock-nightly/install"
typeset -U PATH path
path=(~/progs/bin ~/.local/bin ~/amd-scripts/bin $THEROCK_ROOT/bin $RBENV_ROOT/bin $PYENV_ROOT/bin ~/therock-build/install/bin ~/.cargo/bin $path ~/progs/android/android/tools ~/progs/android/android/platform-tools)

typeset -aUT LD_LIBRARY_PATH ld_library_path

if [[ -d "$THEROCK_ROOT" ]]; then
   ld_library_path=($THEROCK_ROOT/lib $ld_library_path)
   export ROCM_CHIP=$($THEROCK_ROOT/bin/rocm_agent_enumerator | head -n 1)
fi
export LD_LIBRARY_PATH

if [[ -f "$HOME/.amd-llm-api-token" ]]; then
   export AMD_LLM_API_KEY="$(cat "$HOME/.amd-llm-api-token")"
   export ANTHROPIC_API_KEY="dummy"
   export ANTHROPIC_BASE_URL="https://llm-api.amd.com/Anthropic"
   export ANTHROPIC_CUSTOM_HEADERS="Ocp-Apim-Subscription-Key: ${AMD_LLM_API_KEY}"
   export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
   export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4.5
   export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4.5
   export ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4.1
fi

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
