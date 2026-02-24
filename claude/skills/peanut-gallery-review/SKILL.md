---
name: peanut-gallery-review
description: Multi-model code review with two rounds — initial review, triage/fix, then rebuttal review. Orchestrates cursor agents to review your active changes from multiple perspectives. Use when the user says "let the peanut gallery review", "peanut gallery review", "cross-review", "multi-review", "multi-model review", or asks for a review from multiple agents/models.
---

# Peanut Gallery Code Review

Persona-driven two-round code review using multiple AI models as Cursor agents.
Each reviewer adopts a specific persona (from the `personas/` subdirectory) with
distinct expertise, review style, and priorities. Round 1 collects reviews, you
triage and fix, then Round 2 validates your rebuttals.

This skill reuses `cursor-agent-multi.py` from the `ask-the-peanut-gallery`
skill directory. Locate that sibling skill directory to find the script.
For details on script usage, flags, and prerequisites, see
[ask-the-peanut-gallery/SKILL.md](../ask-the-peanut-gallery/SKILL.md).

## Prerequisites

The target workspace must have a `.cursor/cli.json` file that controls what the
Cursor agents are allowed to do. If it is missing, tell the user and show them
the path to `cli.sample.json` (in the `ask-the-peanut-gallery` skill directory)
so they can copy and customize it:

```bash
mkdir -p <workspace>/.cursor
cp /path/to/cli.sample.json <workspace>/.cursor/cli.json
```

The sample allows read-only access and git commands, with all writes denied.
The agents don't need write permissions — their stdout is captured into output
files by the script.

## Steps

### Step 1 — Determine what to review

Figure out what the "active change" is — staged changes, uncommitted work,
or recent commits on a feature branch. Use your judgment; check multiple repos
if it's a multi-repo setup.

**Before proceeding, tell the user exactly what you are reviewing** — show the
diff stat and confirm. Record the exact git commands (repo paths, SHAs, diff
arguments) needed to reproduce the diff — you will pass these to the review
agents in Steps 2 and 4 so they can inspect the changes themselves.

### Step 1.5 — Select reviewers

Select a diverse panel of 4 reviewer personas from the `personas/` subdirectory
of this skill.

1. **Read all `*.md` files** in the `personas/` subdirectory. Parse the YAML
   frontmatter from each file to extract `name` and `models` (list of compatible
   model IDs).

2. **Classify personas**: A persona is an "expert" if their `models` list
   includes `opus` or `gpt-5.3-codex-high` variants (e.g., `opus-4.6-thinking`,
   `opus-4.6`, `gpt-5.3-codex-high`). All others are "generic."

3. **Auto-pick 4 personas** for diversity:
   - Pick 1 random expert persona + 3 random generic personas.
   - For each persona, pick one model from their `models` list, avoiding
     duplicate models across the panel where possible.

4. If the user requested specific personas by name, use those instead of
   auto-picking.

5. **Show the panel to the user** before proceeding:
   ```
   Reviewers: Merlin (opus-4.6-thinking), Petra (composer-1.5), Vera (gemini-3-flash), Soren (sonnet-4.6-thinking)
   ```

6. Build the `--agents` JSON array for use in Steps 2 and 4. Each entry needs
   `name`, `model`, and `PERSONA` (the persona filename). Example:
   ```json
   [
     {"name": "merlin", "model": "opus-4.6-thinking", "PERSONA": "merlin.md"},
     {"name": "petra",  "model": "composer-1.5",      "PERSONA": "petra.md"},
     {"name": "vera",   "model": "gemini-3-flash",    "PERSONA": "vera.md"},
     {"name": "soren",  "model": "sonnet-4.6-thinking","PERSONA": "soren.md"}
   ]
   ```

### Step 1.8 — Ensure the project builds

Before launching the review agents, make sure the project builds successfully.
The review agents have limited permissions and may not be able to build from
scratch — they need fresh build artifacts to run tests and check compilation.

Build the project yourself (or spawn a subagent to do it). If the build fails,
**stop and report the failure to the user** — don't run reviews against code
that doesn't compile.

### Step 2 — Round 1: Initial review

Run `cursor-agent-multi.py` with `--task review-round1`, passing the `--agents`
JSON array built in Step 1.5 and `--include-dir` pointing to the `personas/`
subdirectory:

```bash
/path/to/cursor-agent-multi.py \
  --workspace <WORKSPACE> \
  --task review-round1 \
  --include-dir /path/to/personas \
  --agents '<AGENTS_JSON>' \
  "=== REVIEWER PERSONA ===
You are reviewing code as the following reviewer. Adopt their expertise,
review style, priorities, and feedback patterns throughout your review.

{{PERSONA}}

=== END PERSONA ===

<REVIEW_INSTRUCTIONS>"
```

The `{{PERSONA}}` placeholder is resolved per-agent from the `PERSONA` key in
the agents JSON — each agent gets their own persona content substituted in.

The review instructions part of the prompt MUST include:
- The exact git commands to obtain the diff (repo paths, SHAs, diff arguments
  from Step 1) so the agents can run them themselves
- Clear instruction: "Review this diff. For each issue found, state: the file
  and line(s), the problem, the severity (critical / suggestion / nit), and a
  concrete fix. Also note anything done well."

Do NOT paste the full diff into the prompt — the agents have read-only git
access and can run the commands themselves.

After the script finishes, **read every `output.md`** file it produced.

### Step 3 — Triage and fix

Read all Round 1 reviews and process them:

1. **Group** suggestions by theme (e.g. error handling, naming, performance,
   correctness, style).
2. **For each suggestion**, decide: apply or disregard.
   - **Apply**: Edit the file(s) directly to make the fix. Track what you changed.
   - **Disregard**: Write a clear, specific rebuttal explaining why (e.g.
     "false positive — the null check exists on line 42", "intentional design
     choice because …", "out of scope for this change").
3. **Present a summary to the user** before continuing:

   ## Round 1 Triage

   ### Changes Applied
   - Bullet list of fixes made, with file:line references

   ### Suggestions Disregarded
   - Bullet list with the suggestion and your rebuttal

   Wait for the user to review. If they disagree with any decision, adjust
   before proceeding to Round 2.

4. **Ask the user whether to commit the fixes.** Committing creates a clean
   history that Round 2 agents can diff against: base -> original change ->
   review fixes. This lets them see exactly what was changed in response to
   Round 1 feedback vs the original code. If the user declines, proceed
   anyway — Round 2 will just work off the unstaged changes.

### Step 4 — Round 2: Rebuttal review

Run `cursor-agent-multi.py` again with `--task review-round2`, using the same
`--agents` JSON and `--include-dir` from Step 2:

```bash
/path/to/cursor-agent-multi.py \
  --workspace <WORKSPACE> \
  --task review-round2 \
  --include-dir /path/to/personas \
  --agents '<AGENTS_JSON>' \
  "=== REVIEWER PERSONA ===
You are reviewing code as the following reviewer. Adopt their expertise,
review style, priorities, and feedback patterns throughout your review.

{{PERSONA}}

=== END PERSONA ===

<REBUTTAL_REVIEW_INSTRUCTIONS>"
```

The prompt MUST include all of the following (clearly separated with headers):
- **Git commands to obtain the original diff** (same as Round 1)
- **Git commands to obtain the review-fix diff** (if fixes were committed,
  provide the SHA range so agents can diff base->fix separately from the
  original change)
- **All raw Round 1 reviews** (verbatim content from each model's output.md)
- **Changes applied** (list from Step 3)
- **Rebuttals** for disregarded suggestions (from Step 3)
- **Instruction**: "You are reviewing the triage of a code review. Given the
  original reviews, the fixes applied, and the rebuttals for dismissed
  suggestions — do you agree with the dismissals? Are there any remaining
  issues? For each rebuttal you disagree with, explain why the original
  suggestion should be reconsidered."

After the script finishes, **read every `output.md`** file.

If any Round 2 reviewer makes a convincing case for additional changes:
- Apply the change
- Note it in the final summary

### Final output

Present the final summary:

## Peanut Gallery Review: Complete

### Changes Applied (Round 1)
- List of fixes from triage

### Changes Applied (Round 2)
- Any additional fixes, or "None"

### Dismissed Suggestions (upheld)
- Rebuttals that Round 2 reviewers agreed with (or didn't contest)

### Dismissed Suggestions (overturned)
- Any rebuttals that Round 2 convinced you to reconsider

## Important

- This skill DOES modify files in the workspace (that's the point — it applies
  fixes). The Cursor review agents themselves are read-only.
- If some models fail, still proceed with results from the ones that succeeded
  and note which failed.
- If `cursor-agent-multi.py` fails (e.g., missing cli.json), report the error.
- Keep prompts to the agents concise but complete. If the diff is very large,
  consider summarizing or splitting the review.
- The user can pass `--agents` or `--timeout` flags; forward them to both
  `cursor-agent-multi.py` invocations.
- The user can request specific personas by name (e.g., "use Merlin and Irene").
  In that case, skip auto-picking and use the requested personas.
- **Always include this line in every prompt sent to agents:**
  "You are running non-interactively. No human will see your questions or
  reply. Never ask for clarification. Make reasonable assumptions and state
  them. If a tool call fails, try alternative invocations before giving up.
  Provide a complete answer no matter what."
