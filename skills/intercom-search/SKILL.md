---
name: intercom-search
description: >
  This skill should be used when the user asks to "search Intercom",
  "find conversations about", "look up contacts", "search for a customer",
  or wants to quickly query Intercom conversations or contacts by keyword,
  email, or topic.
argument-hint: "[conversations|contacts] [query]"
---

# Intercom Search

Perform a quick search against the user's Intercom workspace. Parse the user's intent, call the appropriate MCP tool, and return formatted results.

## Parse Arguments

Extract two pieces of information from the user's input:

1. **Object type** — What to search for:
   - `conversations` — If the user mentions conversations, tickets, messages, chats, or support threads
   - `contacts` — If the user mentions contacts, customers, users, leads, people, or emails
   - If ambiguous, default to `conversations` and mention that the user can also search contacts

2. **Query** — The search term:
   - Keywords or phrases (e.g., "billing issue", "timeout error")
   - Email addresses (e.g., "jane@example.com") — implies a contacts search
   - A name (e.g., "Jane Doe") — implies a contacts search
   - A topic (e.g., "pricing", "onboarding") — implies a conversations search

## Execute Search

### For Conversations

Use the `search_conversations` MCP tool. If the user provided keywords, search conversation content. If they specified a state (open, closed, snoozed), apply that as a filter. Default to searching across all states.

### For Contacts

Use the `search_contacts` MCP tool. If the user provided an email address, filter by the `email` field. If they provided a name, filter by the `name` field. For domain searches (e.g., "@acme.com"), use the contains operator on the `email` field.

## Format Results

Present results as a clean, scannable table:

### Conversation Results

| ID | Subject | State | Last Updated |
|----|---------|-------|-------------|
| #12345 | Cannot access billing portal | open | 2 hours ago |
| #12340 | Billing charge question | closed | 1 day ago |
| #12332 | Update payment method | closed | 3 days ago |

### Contact Results

| ID | Name | Email | Last Seen |
|----|------|-------|-----------|
| contact_abc | Jane Doe | jane@example.com | 2 hours ago |
| contact_def | John Smith | john@example.com | 5 days ago |

Use relative timestamps (e.g., "2 hours ago", "3 days ago") for readability.

## Follow-Up

After displaying results, offer to fetch full details for any item:

- "Want me to pull up the full thread for conversation #12345?"
- "I can get the complete profile for Jane Doe — want to see it?"

If the search returned no results, suggest:
- Broadening the query (fewer or different keywords)
- Searching the other object type (contacts instead of conversations, or vice versa)
- Checking for typos in email addresses or names

If results are paginated (more results available), let the user know and offer to fetch the next page.
