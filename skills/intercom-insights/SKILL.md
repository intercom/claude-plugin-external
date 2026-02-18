---
name: intercom-insights
description: >
  This skill should be used when the user asks to "analyze conversations",
  "find support patterns", "search Intercom", "look up a customer",
  "investigate a customer issue", "check contact info", or asks questions
  about their Intercom data such as conversations, contacts, or companies.
---

# Intercom Insights

Use the Intercom MCP server to analyze customer conversations, look up contacts and companies, identify support patterns, and investigate customer issues. You have access to six MCP tools — choose the right one based on the user's question.

## Available MCP Tools

Use these tools from the `intercom` MCP server:

1. **`search`** — General-purpose search across conversations, contacts, and companies. Use this when the user wants to find items matching specific criteria (keywords, filters, states). Supports a query DSL with operators and pagination.

2. **`fetch`** — Retrieve a single object by its ID. Use this when you already have an ID (e.g., `conversation_12345` or `contact_abc123`) and need full details including all metadata and conversation parts.

3. **`search_conversations`** — Search specifically for conversations with conversation-specific filters (state, source type, teammate assignment). Prefer this over `search` when the user is explicitly asking about conversations and needs conversation-specific filtering.

4. **`get_conversation`** — Fetch a single conversation by ID with its full thread of conversation parts (messages, notes, state changes). Use this after finding a conversation via search to get the complete history.

5. **`search_contacts`** — Search specifically for contacts with contact-specific filters (email, name, custom attributes, location). Prefer this over `search` when looking up specific people or filtering by contact attributes.

6. **`get_contact`** — Fetch a single contact by ID with all their attributes, tags, segments, and associated companies. Use this to get the full profile of a known contact.

## Conversation Search Strategies

When searching for conversations, consider these approaches:

### Filter by State
Search for conversations in a specific state to understand workload or find unresolved issues:
- `open` — Currently active conversations requiring attention
- `closed` — Resolved conversations, useful for pattern analysis
- `snoozed` — Temporarily deferred conversations

### Filter by Content
Search conversation content by keywords to find discussions about specific topics, features, or error messages. Combine keyword searches with state filters to narrow results (e.g., find open conversations mentioning "billing error").

### Filter by Source Type
Conversations originate from different channels:
- `email` — Email-based conversations
- `chat` — Live chat / Messenger conversations
- `api` — Programmatically created conversations

### Pagination
Search results return a page at a time. Use the `starting_after` cursor from the response to fetch subsequent pages. Always check if there are more results before summarizing — a single page may not tell the full story.

## Contact Lookup Techniques

When looking up contacts, use the most specific identifier available:

### By Email
The most reliable lookup method. Search for contacts using their exact email address when investigating a specific person's conversations or account status.

### By Domain
Search contacts by their email domain to find all people from a specific company. This is useful for investigating company-wide issues or understanding an organization's support history.

### By Custom Attributes
Contacts may have custom attributes set by the customer's Intercom workspace (e.g., plan type, account ID, role). Use these when the user references workspace-specific identifiers.

### By Location
Search contacts by city, country, or region when investigating geographically scoped issues (e.g., "are customers in Europe seeing more latency?").

## Pattern Analysis Workflow

When the user asks to analyze patterns or trends in their support data, follow this workflow:

1. **Define scope.** Clarify what the user wants to analyze — a time period, topic, customer segment, or conversation state. Ask if unclear.

2. **Fetch a representative sample.** Search for conversations matching the scope. Retrieve at least 10–20 conversations to establish meaningful patterns. Paginate if the first page is insufficient.

3. **Read conversation details.** For each relevant conversation, fetch the full conversation to read the actual messages. Summaries from search results alone are often insufficient for pattern analysis.

4. **Identify recurring themes.** Group conversations by:
   - Common topics or keywords
   - Product areas or features mentioned
   - Error messages or symptoms reported
   - Resolution approaches used
   - Time to resolution

5. **Quantify and summarize.** Present findings with counts and proportions (e.g., "8 of 15 conversations mention timeout errors"). Highlight the most common patterns first.

6. **Recommend actions.** Based on patterns, suggest concrete next steps — knowledge base articles to create, bugs to investigate, or process improvements.

## Issue Investigation Steps

When a user asks you to investigate a specific customer issue or incident:

1. **Identify the customer.** Look up the contact by email, name, or ID. Get their full profile to understand their account context (plan, company, location, custom attributes).

2. **Trace the timeline.** Search for all conversations from this contact, ordered by date. Fetch each conversation to build a chronological narrative of their interactions.

3. **Check for multi-customer impact.** Search for conversations from other contacts mentioning the same symptoms, error messages, or affected feature. This determines if the issue is isolated or widespread.

4. **Examine conversation details.** For the most relevant conversations, read through the full thread including internal notes. Notes from teammates often contain diagnostic information and root cause analysis.

5. **Summarize findings.** Present:
   - A timeline of the customer's interactions
   - The core issue and any error messages
   - What was tried and what resolved it (if anything)
   - Whether other customers are affected
   - Links to the relevant conversations

## Best Practices

- **Start broad, then narrow.** Begin with a general search to understand the landscape, then apply filters to focus on what matters.

- **Always cite conversation links.** When referencing specific conversations, include their IDs so the user can find them in the Intercom inbox. Format as: `Conversation #12345`.

- **State data limitations.** If search results are paginated and you've only seen the first page, say so. If the data doesn't support a conclusion, be explicit about what would be needed to confirm it.

- **Respect data freshness.** The MCP server returns live data from the Intercom workspace. Results reflect the current state — if the user asks about historical trends, note that conversation states may have changed since the events occurred.

- **Combine tools effectively.** A typical workflow involves `search` or `search_conversations` to find relevant items, then `get_conversation` or `get_contact` to get full details. Don't try to answer complex questions from search results alone.

- **Handle empty results gracefully.** If a search returns no results, suggest alternative queries — different keywords, broader filters, or a different object type. The absence of results is itself informative.

Refer to `references/mcp-tools.md` for detailed query DSL syntax, operator reference, and field-level documentation for each MCP tool.
