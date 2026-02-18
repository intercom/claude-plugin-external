# Intercom Plugin for Claude Code

Connect your Intercom workspace to Claude Code. Search conversations, analyze customer support patterns, look up contacts and companies, and install the Intercom Messenger — all from your terminal.

## Prerequisites

- An [Intercom](https://www.intercom.com) workspace
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- Your Intercom workspace must be US-hosted (EU and AU support coming soon)

## Installation

Install from the Claude plugin directory:

```
/install intercom@claude-plugin-directory
```

Or manually add the Intercom MCP server:

```bash
claude mcp add --transport http intercom https://mcp.intercom.com/mcp
```

When you first use the plugin, you'll be prompted to authenticate with your Intercom workspace via OAuth.

## Available Skills

| Skill | Invocation | Description |
|-------|-----------|-------------|
| **Intercom Insights** | Auto-triggered | Analyze conversations, find support patterns, investigate customer issues, and look up contacts. Triggers automatically when you ask about your Intercom data. |
| **Install Messenger** | `/intercom:install-messenger [framework]` | Step-by-step guide to install the Intercom Messenger on your website. Supports React, Next.js, Vue.js, and plain JavaScript. |
| **Intercom Search** | `/intercom:intercom-search [type] [query]` | Quick search for conversations or contacts by keyword, email, or topic. Returns formatted results with follow-up options. |

## Usage Examples

**Analyze recent support trends:**
```
Show me the most common topics in open conversations this week
```

**Investigate a customer issue:**
```
Look up all conversations from jane@example.com and summarize her issues
```

**Search for specific conversations:**
```
/intercom:intercom-search conversations billing error
```

**Find contacts at a company:**
```
/intercom:intercom-search contacts @acme.com
```

**Install the Messenger:**
```
/intercom:install-messenger react
```

**Get conversation details:**
```
Pull up conversation #12345 and show me the full thread
```

## Limitations

- **Read-only access** — The plugin can search and retrieve data but cannot create, update, or delete conversations, contacts, or other Intercom objects.
- **US region only** — Currently supports US-hosted Intercom workspaces. EU and Australia region support is planned.
- **Rate limits** — Search operations are subject to Intercom API rate limits. The MCP server handles throttling automatically.

## Resources

- [Intercom Developer Hub](https://developers.intercom.com)
- [Intercom API Reference](https://developers.intercom.com/docs/references/rest-api/api.intercom.io/conversations/conversation/)
- [Intercom Messenger Setup Guide](https://www.intercom.com/help/en/articles/170-install-intercom-on-your-website-or-web-app)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT — see [LICENSE](LICENSE) for details.
