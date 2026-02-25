---
name: ask-the-peanut-gallery
description: Asks multiple AI models the same question via Cursor agents and synthesizes their answers. Use when you want diverse perspectives on a codebase question, architecture exploration, or code review.
---

# Ask the Peanut Gallery

Delegate a question to multiple AI models (GPT, Claude/Sonnet, Gemini Pro,
Gemini Flash) running as Cursor agents, then synthesize their responses.

The `cursor-agent-multi.py`, `cursor-agent-task.sh`, and `cli.sample.json` files
are in the same directory as this skill file. Find them by looking in the skill
directory.

## Prerequisites

The target workspace must have a `.cursor/cli.json` file that controls what the
Cursor agents are allowed to do. If it is missing, tell the user and show them
the path to `cli.sample.json` (in this skill's directory) so they can copy and
customize it:

```bash
mkdir -p <workspace>/.cursor
cp /path/to/cli.sample.json <workspace>/.cursor/cli.json
```

The sample allows read-only access and git commands, with all writes denied.
The agents don't need write permissions — their stdout is captured into output
files by the script. Users should add project-specific shell commands (e.g.
`Shell(ninja **)`, `Shell(pytest **)`) as needed.

## Steps

1. **Locate the scripts.** Find the directory containing this skill's files
   and use the `cursor-agent-multi.py` script there.

2. **Run cursor-agent-multi.py** with the user's question. Default the workspace
   to the current working directory.

   ```bash
   /path/to/cursor-agent-multi.py \
     --workspace <WORKSPACE> \
     --task <short-kebab-case-name> \
     --agents '<AGENTS_JSON>' \
     "<THE QUESTION>"
   ```

   Pick a short descriptive `--task` name based on the question (e.g.
   `vmvx-architecture`, `flag-review`).

   The `--agents` flag takes a JSON array of agent configs. Each object must
   have `name` and `model`. Example with default models:

   ```json
   [
     {"name": "gpt",          "model": "gpt-5.3-codex-fast"},
     {"name": "claude",       "model": "sonnet-4.6"},
     {"name": "gemini-pro",   "model": "gemini-3.1-pro"},
     {"name": "gemini-flash", "model": "gemini-3-flash"}
   ]
   ```

   Additional options (pass through from the user if specified):
   - `--include-dir DIR` — directory of .md files for `{{PLACEHOLDER}}` resolution
   - `--timeout SECS` — per-agent timeout (default: 480)

   Run `cursor-agent --list-models` to see all available models.

3. **Read all output files.** After cursor-multi finishes, it prints the paths.
   Read every `output.md` file.

4. **Return a synthesis** in the following format:

   ## Peanut Gallery: <short title>

   ### Synthesis
   Summarize the consensus across models. Note any disagreements or unique
   findings that only one model surfaced. Be specific — cite file paths,
   function names, PR numbers, etc. when the models provide them.

   ### Individual Responses

   For each model that produced output, include a section with the model name
   and the verbatim content of its output.md.

## Important

- Do NOT modify any files in the workspace.
- If some models fail, still return results from the ones that succeeded and
  note which failed.
- If cursor-agent-multi.py itself fails (e.g., missing cli.json), report the error.
- **Always include this line in every prompt sent to agents:**
  "You are running non-interactively. No human will see your questions or
  reply. Never ask for clarification. Make reasonable assumptions and state
  them. If a tool call fails, try alternative invocations before giving up.
  Provide a complete answer no matter what."
