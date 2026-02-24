#!/usr/bin/env python3
"""Run multiple Cursor agents in parallel with different models, same prompt template.

Each agent gets its own output subdirectory under the task directory.
Uses cursor-agent-task.sh internally.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(
        prog="cursor-agent-multi",
        description="Run multiple Cursor agents in parallel with different models, same prompt template.",
    )
    parser.add_argument(
        "--agents",
        required=True,
        help='JSON array of agent configs (inline or path to file). Each object must have "name" and "model"; other keys are substitution variables.',
    )
    parser.add_argument(
        "--include-dir",
        help="Directory of .md files for {{PLACEHOLDER}} resolution",
    )
    parser.add_argument("--workspace", required=True, help="Workspace directory")
    parser.add_argument(
        "--output-dir",
        help="Output directory (default: <workspace>/.cursor/tasks)",
    )
    parser.add_argument("--task", help="Task name prefix (default: timestamp)")
    parser.add_argument(
        "--timeout", type=int, default=480, help="Per-agent timeout in seconds (default: 480)"
    )
    parser.add_argument("prompt", nargs="*", help="Prompt template (joined with spaces)")
    return parser.parse_args()


def load_agents(arg):
    """Parse inline JSON or load from file. Validate agent configs."""
    text = arg.strip()
    if text.startswith("["):
        agents = json.loads(text)
    else:
        agents = json.loads(Path(text).read_text())

    if not isinstance(agents, list) or len(agents) == 0:
        print("Error: --agents must be a non-empty JSON array.", file=sys.stderr)
        sys.exit(1)

    names_seen = set()
    for i, agent in enumerate(agents):
        if not isinstance(agent, dict):
            print(f"Error: agent[{i}] is not a JSON object.", file=sys.stderr)
            sys.exit(1)
        for key in ("name", "model"):
            if key not in agent:
                print(f"Error: agent[{i}] missing required key '{key}'.", file=sys.stderr)
                sys.exit(1)
        name = agent["name"]
        if name in names_seen:
            print(f"Error: duplicate agent name '{name}'.", file=sys.stderr)
            sys.exit(1)
        names_seen.add(name)

    return agents


def strip_frontmatter(text):
    """Remove YAML frontmatter (--- ... ---) from the beginning of text."""
    if not text.startswith("---"):
        return text
    # Find the closing ---
    end = text.find("---", 3)
    if end == -1:
        return text
    # Skip past the closing --- and any immediately following newline
    rest = text[end + 3 :]
    if rest.startswith("\n"):
        rest = rest[1:]
    return rest


def resolve_file(name, include_dir):
    """Find file by name in include_dir, load and strip frontmatter.

    Returns (content, found). If not found, returns (None, False).
    """
    if include_dir is None:
        return None, False

    path = Path(include_dir) / name
    if path.is_file():
        return strip_frontmatter(path.read_text()), True

    return None, False


def resolve_prompt(template, agent_vars, include_dir):
    """Substitute {{KEY}} placeholders in the template for one agent.

    Resolution order:
    1. If agent_vars has key KEY -> use its value as a filename in include_dir
    2. Otherwise -> look for KEY.md in include_dir (shared include)
    3. If file not found -> warning to stderr, replace with [MISSING: {{KEY}}]
    """

    def replacer(match):
        key = match.group(1)

        # Check agent-specific variable first
        if key in agent_vars:
            filename = agent_vars[key]
            content, found = resolve_file(filename, include_dir)
            if found:
                return content
            print(
                f"Warning: agent variable {key}={filename} not found in include-dir.",
                file=sys.stderr,
            )
            return f"[MISSING: {{{{{key}}}}}]"

        # Fall back to KEY.md in include-dir
        content, found = resolve_file(f"{key}.md", include_dir)
        if found:
            return content

        print(f"Warning: no include found for {{{{{key}}}}}.", file=sys.stderr)
        return f"[MISSING: {{{{{key}}}}}]"

    return re.sub(r"\{\{(\w+)\}\}", replacer, template)


def main():
    # Flush prints immediately so callers see progress in real time.
    sys.stdout.reconfigure(line_buffering=True)

    args = parse_args()

    prompt = " ".join(args.prompt)
    if not prompt:
        print("Error: a prompt is required.", file=sys.stderr)
        sys.exit(1)

    agents = load_agents(args.agents)
    workspace = os.path.realpath(args.workspace)

    if not os.path.isdir(workspace):
        print(f"Error: workspace does not exist: {workspace}", file=sys.stderr)
        sys.exit(1)

    output_dir = args.output_dir or os.path.join(workspace, ".cursor", "tasks")
    task_prefix = args.task or datetime.now().strftime("%Y%m%d-%H%M%S")

    script_dir = os.path.dirname(os.path.abspath(__file__))
    cursor_task = os.path.join(script_dir, "cursor-agent-task.sh")

    include_dir = args.include_dir
    if include_dir and not os.path.isdir(include_dir):
        print(f"Error: --include-dir does not exist: {include_dir}", file=sys.stderr)
        sys.exit(1)

    # Print banner
    agent_names = [a["name"] for a in agents]
    agent_models = [a["model"] for a in agents]
    print("cursor-multi")
    print(f"  Workspace: {args.workspace}")
    print(f"  Output:    {output_dir}/{task_prefix}")
    print(f"  Agents:    {', '.join(f'{n} ({m})' for n, m in zip(agent_names, agent_models))}")
    print(f"  Timeout:   {args.timeout}s")
    if include_dir:
        print(f"  Includes:  {include_dir}")
    print()

    # Launch agents in parallel
    processes = []  # list of (name, model, proc, log_file, start_time)
    for agent in agents:
        name = agent["name"]
        model = agent["model"]
        task_name = f"{task_prefix}/{name}"
        log_dir = os.path.join(output_dir, task_name)
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, "agent.log")

        # Build substitution vars (everything except name and model)
        agent_vars = {k: v for k, v in agent.items() if k not in ("name", "model")}

        # Resolve prompt template for this agent
        if agent_vars or include_dir:
            agent_prompt = resolve_prompt(prompt, agent_vars, include_dir)
        else:
            agent_prompt = prompt

        print(f"Starting: {name} ({model})")

        try:
            with open(log_file, "w") as lf:
                proc = subprocess.Popen(
                    [
                        cursor_task,
                        "--model", model,
                        "--workspace", args.workspace,
                        "--output-dir", output_dir,
                        "--name", task_name,
                        "--timeout", str(args.timeout),
                        agent_prompt,
                    ],
                    stdout=lf,
                    stderr=subprocess.STDOUT,
                )
        except OSError as e:
            print(f"[FAIL] {name} ({model}) - failed to launch: {e}", file=sys.stderr)
            continue
        processes.append((name, model, proc, log_file, time.monotonic()))

    print()
    print(f"All {len(processes)} agents launched. Waiting...")
    print()

    if not processes:
        print("Error: no agents were launched.", file=sys.stderr)
        sys.exit(1)

    # Wait for agents in completion order
    remaining = list(processes)
    failures = 0
    last_status = time.monotonic()
    STATUS_INTERVAL = 30

    while remaining:
        finished = False
        for i, (name, model, proc, log_file, t0) in enumerate(remaining):
            rc = proc.poll()
            if rc is not None:
                remaining.pop(i)
                elapsed = int(time.monotonic() - t0)
                output_file = os.path.join(output_dir, task_prefix, name, "output.md")

                if rc == 0:
                    print(f"[done] {name} ({model}) [{elapsed}s]")
                elif rc == 124:
                    print(f"[TIMEOUT] {name} ({model}) - timed out after {args.timeout}s")
                    failures += 1
                else:
                    print(f"[FAIL] {name} ({model}) - exit code {rc} [{elapsed}s]")
                    failures += 1

                print(f"       Log: {log_file}")

                if os.path.isfile(output_file) and os.path.getsize(output_file) > 0:
                    print("       ---")
                    with open(output_file) as f:
                        lines = f.readlines()
                    for line in lines[:10]:
                        print(f"       {line}", end="")
                    if len(lines) > 10:
                        print(f"       ... ({len(lines) - 10} more lines)")
                    print()

                finished = True
                break  # restart iteration after modifying list

        if not finished:
            # Print periodic status update
            now = time.monotonic()
            if now - last_status >= STATUS_INTERVAL:
                still_running = ", ".join(
                    f"{n} [{int(now - t)}s]" for n, _m, _p, _l, t in remaining
                )
                print(f"[waiting] {len(remaining)} running: {still_running}")
                last_status = now
            time.sleep(0.5)

    print()
    print("Results:")
    for agent in agents:
        name = agent["name"]
        output_file = os.path.join(output_dir, task_prefix, name, "output.md")
        if os.path.isfile(output_file):
            print(f"  {name}: {output_file}")
        else:
            print(f"  {name}: (no output)")

    if failures > 0:
        print()
        print(f"{failures} agent(s) failed. Check logs above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
