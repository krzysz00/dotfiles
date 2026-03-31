---
name: peanut-gallery-review
description: Multi-model code review with two rounds — initial review, triage/fix, then rebuttal review. Orchestrates cursor agents to review your active changes from multiple perspectives. Use when the user says "let the peanut gallery review", "peanut gallery review", "cross-review", "multi-review", "multi-model review", or asks for a review from multiple agents/models.
---

# Peanut Gallery Code Review

Persona-driven two-round code review using Cursor agents. Round 1 collects
reviews, you triage and fix, Round 2 validates rebuttals.

Uses `cursor-agent-multi.py` from the sibling `ask-the-peanut-gallery` skill
directory. See its SKILL.md for script usage and prerequisites.

## Prerequisites

The workspace needs `.cursor/cli.json`. If missing, copy `cli.sample.json`
from the `ask-the-peanut-gallery` skill directory into
`<workspace>/.cursor/cli.json`. If it already exists, diff it against
`cli.sample.json` and update it if the sample has newer entries.

**Before launching agents**, verify that `cli.json` actually covers what the
project needs. Check that:
- Test runners the project uses (e.g. `ctest`, `pytest`, `ninja check-*`) are
  in the allow list
- Build directory paths in the allow list match the project's actual build
  directory layout (e.g. `./build/**` won't help if the build dir is
  `../build-release/`)
- The `--workspace` passed to `cursor-agent-multi.py` sets the agents'
  working directory. It should be a parent that covers both the repo and
  build directories. Tell agents in the prompt which subdirectory is the
  repo root (for `git -C`) and where the build directory is

## Prompt boilerplate

Every prompt sent to agents MUST include all three of these elements:

**Persona preamble** (at the start of each prompt):
```
=== REVIEWER PERSONA ===
You are reviewing code as the following reviewer. Adopt their expertise,
review style, priorities, and feedback patterns throughout your review.

{{PERSONA}}

=== END PERSONA ===
```

The `{{PERSONA}}` placeholder is resolved per-agent from the `PERSONA` key in
the `--agents` JSON — each agent gets their own persona content injected.

**Test execution reporting** (append after round-specific instructions):
```
At the end of your review, include a section titled '## Test Execution'.
Report what tests you attempted to run (commands, file paths), whether they
succeeded or failed, and any output. If you could not run tests (e.g.
permission errors, missing build tools, missing build artifacts), say so
explicitly and explain what blocked you. If you chose not to run any tests,
state that and why. This section is mandatory.
```

**Non-interactive notice** (include verbatim in every prompt):
```
You are running non-interactively. No human will see your questions or reply.
Never ask for clarification. Make reasonable assumptions and state them. If a
tool call fails, try alternative invocations before giving up. Provide a
complete answer no matter what.
```

## Steps

### Step 1A — Review directory

Create a uniquely-named directory under `/tmp/` for this review session. All
intermediate files go here. Do not create it inside the git working tree.
Referenced as `<REVIEW_DIR>` below.

### Step 1B — Determine what to review

Figure out the active change — staged changes, uncommitted work, or recent
commits on a feature branch. Check multiple repos if needed.

Show the user the diff stat and confirm. Record the exact git commands needed
to reproduce the diff — agents will need these in Steps 2 and 3.

### Step 1C — Select reviewers

Pick 4 personas from `personas/`. **Do NOT read full persona files** — only
read YAML frontmatter (`head -10`) to extract `name` and `models`.

1. **Classify**: a persona is "expert" if their `models` list includes any
   `opus` or high-tier `gpt` variant (e.g. `gpt-5.*-high`, `gpt-5.*-xhigh`).
   All others are "generic."
2. **Auto-pick**: 1 expert + 3 generic. For each persona, pick one model
   from their list, avoiding duplicate models across the panel.
3. Override with user-requested personas if specified.
4. Show the panel before proceeding.
5. Build the `--agents` JSON array. Each entry needs `name`, `model`, and
   `PERSONA` (the persona filename):
   ```json
   [
     {"name": "merlin", "model": "opus-4.6-thinking", "PERSONA": "merlin.md"},
     {"name": "petra",  "model": "composer-1.5",      "PERSONA": "petra.md"},
     ...
   ]
   ```

### Step 1D — Ensure project builds

Build the project before launching agents — they have limited permissions and
need fresh build artifacts. If the build fails, stop and report.

### Step 2 — Round 1: Initial review

Run `cursor-agent-multi.py` with `--task review-round1`, `--output-dir
<REVIEW_DIR>`, the agents JSON, and `--include-dir` pointing to `personas/`.

Round-specific instructions to include in the prompt:
- The exact git commands to obtain the diff (from Step 1B)
- "Review this diff. For each issue: file and line(s), problem, severity
  (critical / suggestion / nit), concrete fix. Note anything done well."

Do NOT paste the diff — agents have git access and will run the commands.
After completion, read every `output.md`.

### Step 3 — Triage and fix

Read all Round 1 reviews and process them:

1. **Group** suggestions by theme.
2. **For each**, decide: apply or disregard.
   - **Apply**: make the fix, track what changed.
   - **Disregard**: write a specific rebuttal.
3. **Present to the user** and **write to `<REVIEW_DIR>/triage.md`**:

   ## Round 1 Triage

   ### Test Execution Summary
   Per reviewer: what tests ran, results, or why they couldn't/didn't.

   ### Changes Applied
   - Fixes with file:line references

   ### Suggestions Disregarded
   - **\<Reviewer\> — \<description\>**: \<rebuttal\>

   Wait for user review before continuing.

4. **Ask whether to commit fixes.** Committing lets Round 2 agents diff
   review fixes separately from the original change.

### Step 4 — Round 2: Rebuttal review

Run `cursor-agent-multi.py` with `--task review-round2`, same output dir,
agents, and include-dir.

Round-specific instructions to include in the prompt:
- Git commands for the original diff (same as Round 1)
- Git commands for the review-fix diff (if committed, provide SHA range)
- File paths to Round 1 reviews (`<REVIEW_DIR>/review-round1/<name>/output.md`)
  and triage (`<REVIEW_DIR>/triage.md`)
- "Read all files above. Assess: given the original reviews, fixes, and
  rebuttals — do you agree with the dismissals? Any remaining issues? For
  each rebuttal you disagree with, explain why."

Do NOT paste reviews or triage inline. After completion, read every
`output.md`. Apply any convincing additional changes.

### Final output

Present the final summary:

## Peanut Gallery Review: Complete

### Test Execution Summary
Per reviewer across both rounds: tests run, results, blockers.

### Changes Applied (Round 1)
### Changes Applied (Round 2)
### Dismissed Suggestions (upheld)
### Dismissed Suggestions (overturned)

## Notes

- This skill modifies workspace files. The Cursor review agents are read-only.
- If some models fail, proceed with the rest and note failures.
- Keep prompts concise — write large content to files under `<REVIEW_DIR>/`
  and point agents to file paths instead of pasting inline.
- Forward user-provided `--agents` or `--timeout` flags to both invocations.
