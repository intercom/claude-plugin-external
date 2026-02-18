# Intercom MCP Tools Reference

This document provides detailed parameter and query DSL reference for each MCP tool available through the Intercom MCP server.

## `search` — General-Purpose Search

The `search` tool queries across multiple Intercom object types using a structured query DSL.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | Yes | Search query string or structured filter |
| `object_type` | string | Yes | One of: `conversation`, `contact`, `company` |
| `starting_after` | string | No | Pagination cursor from a previous response |
| `per_page` | number | No | Results per page (default: 20, max: 150) |

### Query DSL Syntax

The query DSL supports structured filters using field-operator-value triples:

```
{
  "field": "<field_name>",
  "operator": "<operator>",
  "value": "<value>"
}
```

### Supported Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `=` | Equals | `{"field": "state", "operator": "=", "value": "open"}` |
| `!=` | Not equals | `{"field": "state", "operator": "!=", "value": "closed"}` |
| `>` | Greater than | `{"field": "created_at", "operator": ">", "value": 1700000000}` |
| `<` | Less than | `{"field": "updated_at", "operator": "<", "value": 1700000000}` |
| `~` | Contains | `{"field": "email", "operator": "~", "value": "@acme.com"}` |
| `!~` | Does not contain | `{"field": "name", "operator": "!~", "value": "test"}` |
| `IN` | In list | `{"field": "state", "operator": "IN", "value": ["open", "snoozed"]}` |
| `NIN` | Not in list | `{"field": "source.type", "operator": "NIN", "value": ["api"]}` |

### Compound Queries

Combine multiple filters with `AND` / `OR`:

```
{
  "operator": "AND",
  "value": [
    {"field": "state", "operator": "=", "value": "open"},
    {"field": "created_at", "operator": ">", "value": 1700000000}
  ]
}
```

### Pagination

When a response includes `"has_more": true`, use the `starting_after` value from the last item to fetch the next page:

```
{
  "query": "...",
  "object_type": "conversation",
  "starting_after": "conversation_67890"
}
```

---

## `fetch` — Fetch Single Object by ID

Retrieve a single Intercom object by its full ID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Full object ID (e.g., `conversation_12345`, `contact_abc123`, `company_xyz789`) |

### ID Formats

| Object Type | ID Format | Example |
|-------------|-----------|---------|
| Conversation | `conversation_<number>` | `conversation_12345` |
| Contact | `contact_<alphanumeric>` | `contact_6543a1b2c3d4` |
| Company | `company_<alphanumeric>` | `company_abc123def456` |

### Returned Metadata

The response includes all object fields. For conversations, this includes the full list of conversation parts. For contacts, this includes all standard and custom attributes. For companies, this includes plan information and user counts.

---

## `search_conversations` — Conversation-Specific Search

Search specifically for conversations with conversation-oriented filters.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | object | Yes | Structured query using the query DSL |
| `starting_after` | string | No | Pagination cursor |
| `per_page` | number | No | Results per page |

### Conversation-Specific Fields

| Field | Type | Description |
|-------|------|-------------|
| `state` | string | `open`, `closed`, `snoozed` |
| `source.type` | string | `email`, `chat`, `api`, `push`, `twitter`, `facebook` |
| `source.author.type` | string | `user`, `admin`, `bot` |
| `assignee.id` | string | ID of assigned teammate |
| `assignee.type` | string | `admin`, `team`, `nobody` |
| `created_at` | timestamp | Unix timestamp of creation |
| `updated_at` | timestamp | Unix timestamp of last update |
| `read` | boolean | Whether the conversation has been read |
| `priority` | string | `priority`, `not_priority` |
| `statistics.time_to_first_response` | number | Seconds until first admin response |
| `statistics.time_to_last_close` | number | Seconds until final close |
| `tags.tag.id` | string | Filter by tag ID |
| `custom_attributes.<key>` | varies | Custom conversation attributes |

---

## `get_conversation` — Fetch Single Conversation

Retrieve a single conversation with its complete thread.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Conversation ID (numeric or prefixed) |

### Conversation Parts

The response includes an array of conversation parts, each with:

| Field | Description |
|-------|-------------|
| `part_type` | `comment`, `note`, `assignment`, `close`, `open`, `state_change` |
| `body` | HTML content of the message |
| `author` | Object with `type` (`user`, `admin`, `bot`) and `name` |
| `created_at` | Unix timestamp |
| `attachments` | Array of attachment objects |

---

## `search_contacts` — Contact-Specific Search

Search specifically for contacts with contact-oriented filters.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | object | Yes | Structured query using the query DSL |
| `starting_after` | string | No | Pagination cursor |
| `per_page` | number | No | Results per page |

### Contact-Specific Fields

| Field | Type | Description |
|-------|------|-------------|
| `email` | string | Contact's email address |
| `name` | string | Contact's full name |
| `phone` | string | Contact's phone number |
| `role` | string | `user` or `lead` |
| `created_at` | timestamp | Unix timestamp |
| `signed_up_at` | timestamp | Unix timestamp of sign-up |
| `last_seen_at` | timestamp | Unix timestamp of last activity |
| `last_contacted_at` | timestamp | Unix timestamp of last outreach |
| `unsubscribed_from_emails` | boolean | Email opt-out status |
| `location.city` | string | City name |
| `location.country` | string | Country name |
| `location.region` | string | State/province/region |
| `tag.id` | string | Filter by tag ID |
| `segment.id` | string | Filter by segment ID |
| `custom_attributes.<key>` | varies | Custom contact attributes |

---

## `get_contact` — Fetch Single Contact

Retrieve a single contact with their full profile.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Contact ID |

### Response Includes

- All standard contact fields (name, email, phone, location)
- Custom attributes set by the workspace
- Tags applied to the contact
- Segments the contact belongs to
- Companies the contact is associated with
- Social profiles (if available)
- Browser/OS information from last session
- Conversation statistics (total count, last interaction)
