# agent-state-usage

Report disk usage for local AI agent state directories.

The tool is meant for quick checks like:

```bash
npx agent-state-usage
```

It checks known local agent state directories by default. The list lives in [data/agent-paths.txt](data/agent-paths.txt), so adding another known location is a one-line change.

To inspect the configured defaults:

```bash
agent-state-usage --list-defaults
```

It reports total usage per directory plus the largest regular files, which helps spot session logs, caches, indexes, transcripts, and other state that has grown over time.

## Usage

```bash
agent-state-usage
```

Supported environments: macOS and Linux shells with Bash, `du`, `find`, `awk`, and Perl available. Native Windows shells are not currently supported; use WSL or another Unix-like shell environment instead.

Examples:

```bash
npx agent-state-usage
npx agent-state-usage --top 50
npx agent-state-usage --json
npx agent-state-usage ~/.codex ~/.agents
```

## Options

```text
--json     Emit machine-readable JSON.
--top N    Show the N largest files. Default: 20.
--list-defaults
           Show configured default paths.
--version  Show version.
--help     Show help.
```

## Install Locally

From this folder:

```bash
npm link
agent-state-usage
```

Or copy `bin/agent-state-usage` somewhere on your `PATH`.

## Publish

Before publishing:

```bash
npm pack --dry-run
npm publish --access public
```

After publishing, users can run it without a permanent install:

```bash
npx agent-state-usage
```

## Notes

This measures on-disk usage only. It does not inspect running processes, RAM usage, or the semantic contents of an agent's memory.

Output may include local directory and file names from agent state folders. Review results before sharing them publicly, since paths can reveal project names, usernames, session filenames, cache names, or other local context.
