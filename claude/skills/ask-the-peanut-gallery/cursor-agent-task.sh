#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: cursor-task [OPTIONS] --workspace DIR PROMPT...

Run a Cursor agent non-interactively to produce a markdown file.

The agent's stdout is captured into output.md. The agent does not need
write permissions — all file output is handled by this script.

The workspace must contain .cursor/cli.json with a non-empty deny list.

Options:
  --model MODEL       Model to use (default: sonnet-4)
  --workspace DIR     Workspace directory (required)
  --output-dir DIR    Output directory (default: <workspace>/.cursor/tasks)
  --name NAME         Task name for the output subdirectory (default: timestamp)
  --timeout SECS      Timeout in seconds (default: 480)
  -h, --help          Show this help

Examples:
  cursor-task --workspace ~/iree/main \
    "Review the recent changes to the compiler pipeline"

  cursor-task --model gpt-5 --workspace ~/iree/main --name vmvx-analysis \
    "Analyze test failures in the VMVX backend"
EOF
    exit "${1:-0}"
}

model="sonnet-4"
workspace=""
output_dir=""
task_name=""
timeout_secs=480

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)      model="$2"; shift 2 ;;
        --workspace)  workspace="$2"; shift 2 ;;
        --output-dir) output_dir="$2"; shift 2 ;;
        --name)       task_name="$2"; shift 2 ;;
        --timeout)    timeout_secs="$2"; shift 2 ;;
        -h|--help)    usage 0 ;;
        --)           shift; break ;;
        -*)           echo "Error: Unknown option: $1" >&2; usage 1 ;;
        *)            break ;;
    esac
done

prompt="$*"

if [[ -z "$workspace" || -z "$prompt" ]]; then
    echo "Error: --workspace and a prompt are required." >&2
    usage 1
fi

workspace="$(realpath "$workspace")"

if [[ ! -d "$workspace" ]]; then
    echo "Error: workspace does not exist: $workspace" >&2
    exit 1
fi

# --- Validate cli.json ---

cli_json="$workspace/.cursor/cli.json"

if [[ ! -f "$cli_json" ]]; then
    echo "Error: $cli_json not found." >&2
    echo "Create it with appropriate permissions before running cursor-task." >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not found." >&2
    exit 1
fi

deny_count=$(jq '.permissions.deny | length' "$cli_json")
if [[ "$deny_count" -eq 0 ]]; then
    echo "Error: $cli_json has an empty deny list." >&2
    echo "Add deny rules (e.g. Write(**), Delete(**), Shell(**)) for safety." >&2
    exit 1
fi

# --- Create task output directory ---

if [[ -z "$output_dir" ]]; then
    output_dir="$workspace/.cursor/tasks"
fi
if [[ -z "$task_name" ]]; then
    task_name="$(date +%Y%m%d-%H%M%S)"
fi
task_dir="$output_dir/$task_name"
output_file="$task_dir/output.md"
mkdir -p "$task_dir"

# --- Log metadata ---

meta_file="$task_dir/meta.json"
start_time="$(date -Iseconds)"

jq -n \
    --arg model "$model" \
    --arg workspace "$workspace" \
    --arg prompt "$prompt" \
    --arg start "$start_time" \
    --arg timeout "$timeout_secs" \
    '{model: $model, workspace: $workspace, prompt: $prompt, start: $start, timeout: ($timeout | tonumber)}' \
    > "$meta_file"

# --- Run the agent ---

echo "cursor-task" >&2
echo "  Model:     $model" >&2
echo "  Workspace: $workspace" >&2
echo "  Output:    $output_file" >&2
echo "  Timeout:   ${timeout_secs}s" >&2
echo "" >&2

rc=0
timeout "$timeout_secs" cursor-agent --print \
    --model "$model" \
    --force \
    --trust \
    --output-format text \
    --workspace "$workspace" \
    "$prompt" \
    > "$output_file" || rc=$?

end_time="$(date -Iseconds)"
jq --arg end "$end_time" --argjson rc "$rc" '.end = $end | .exit_code = $rc' "$meta_file" > "$meta_file.tmp" \
    && mv "$meta_file.tmp" "$meta_file"

echo "" >&2
if [[ "$rc" -ne 0 ]]; then
    echo "Agent exited with code $rc. Output: $task_dir" >&2
    exit "$rc"
elif [[ -s "$output_file" ]]; then
    echo "Done. Output: $output_file" >&2
else
    echo "Warning: agent finished but output is empty." >&2
    exit 1
fi
