# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Intercom plugin for Claude Code — a skill-based integration (not compiled code). Skills are pure Markdown files that Claude reads at runtime to interact with Intercom workspaces via a remote MCP server.

## Architecture

```
User → Claude Code CLI → Skill (SKILL.md) → MCP Server (https://mcp.intercom.com/mcp) → Intercom API
```

- **No build step, no dependencies, no tests.** The plugin is entirely declarative.
- `.mcp.json` routes the `intercom` namespace to the remote HTTP-based MCP server.
- `.claude-plugin/plugin.json` is the plugin manifest for Claude Code's plugin registry.
- `.claude/settings.local.json` manages local permissions (currently allows WebFetch from raw.githubusercontent.com).

## Skills

Three skills live under `skills/`, each in its own directory:

| Skill               | Trigger                                              | Key Files                                    |
| ------------------- | ---------------------------------------------------- | -------------------------------------------- |
| `install-messenger` | Explicit: `/intercom:install-messenger [framework]`  | `SKILL.md`, `references/framework-guides.md` |
| `intercom-insights` | Auto-triggered by keywords                           | `SKILL.md`, `references/mcp-tools.md`        |
| `intercom-search`   | Explicit: `/intercom:intercom-search [type] [query]` | `SKILL.md`                                   |

### Skill File Structure

Each skill directory contains:

- `SKILL.md` — Main skill file with YAML frontmatter (`name`, `description`, optional `disable-model-invocation`, `argument-hint`) followed by Markdown instructions Claude reads at runtime.
- `references/` — Supplementary docs loaded on demand for progressive disclosure (keeps SKILL.md concise).

### Invocation Modes

- **Auto-triggered:** No `disable-model-invocation` in frontmatter. Claude activates the skill when the user's intent matches the `description` field.
- **Explicit:** `disable-model-invocation: true` in frontmatter. Only invoked via `/intercom:<skill-name>`.

## Key Conventions

- **Security-first:** `install-messenger` defaults to JWT-based identity verification (HS256). Insecure mode requires explicit user opt-in. Never default to insecure installation.
- **Progressive disclosure:** Keep SKILL.md focused on workflow logic. Move API references, framework-specific code, and tool documentation into `references/` subdirectories.
- **Read-only access:** The MCP server only supports search and retrieval operations — no create, update, or delete.
- **Regional awareness:** Intercom supports US, EU (Ireland), and Australia data residency. Currently US-only; EU/AU planned.

## Development Workflow

1. Edit SKILL.md files or reference documents
2. Test by running skills in Claude Code CLI (e.g., `/intercom:install-messenger react`)
3. For auto-triggered skills, test by typing natural language that matches the skill's `description` field
4. Push to GitHub — the plugin registry picks up changes from the repository
