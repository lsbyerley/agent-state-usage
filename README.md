# agent-state-usage

Report disk usage for local AI agent state directories.

Run it with `npx`:

```bash
npx agent-state-usage
```

It checks known local agent state directories by default. You can inspect the configured defaults or pass explicit paths to check other locations.

It reports total usage per directory plus the largest regular files, which helps spot session logs, caches, indexes, transcripts, and other state that has grown over time.

## Usage

```bash
npx agent-state-usage
```

Examples:

```bash
npx agent-state-usage
npx agent-state-usage --top 50
npx agent-state-usage --json
npx agent-state-usage --list-defaults
npx agent-state-usage ~/.codex ~/.agents
```

## Supported Environments

macOS and Linux shells with Bash, `du`, `find`, `awk`, and Perl available.

Native Windows shells are not currently supported; use WSL or another Unix-like shell environment instead.

## Options

```text
--json           Emit machine-readable JSON.
--top N          Show the N largest files. Default: 20.
--list-defaults  Show configured default paths.
--version        Show version.
--help           Show help.
```

## Local Development

From the repo:

```bash
npm link
agent-state-usage
```

## Notes

This measures on-disk usage only. It does not inspect running processes, RAM usage, or the semantic contents of an agent's memory.

Output may include local directory and file names from agent state folders. Review results before sharing them publicly, since paths can reveal project names, usernames, session filenames, cache names, or other local context.
