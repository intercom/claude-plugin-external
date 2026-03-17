# Fin SDK API Specification

Base URL: `https://api.intercom.io/fin-sdk`

All requests require: `Authorization: Bearer <token>`

The token is an Intercom API access token from a Developer Hub app. The backend infers the workspace from the token — no workspace ID parameter is needed.

## Prerequisites

- Workspace must have `fin-sdk` feature flag enabled
- Token must have sufficient OAuth scopes (a `fin_sdk` scope is being introduced)

---

## Endpoints

### GET /manifest

Returns a complete inventory of the workspace's Fin resources.

**Response:**
```json
{
  "workspace": {
    "app_id": 3478665,
    "app_id_code": "dhafv6dj",
    "name": "My Workspace"
  },
  "procedures": [
    {
      "id": "59731192",
      "name": "hello_world"
    }
  ],
  "tasks": [],
  "data_connectors": [],
  "guidance": []
}
```

Note: `tasks` are the older workflow format being replaced by procedures. Workspaces with more resources may include additional fields on procedure/connector entries (e.g., `display_name`, `simulation_count`), but `id` and `name` are always present.

---

### POST /upload

Uploads a procedure YAML, data connector JSON, attribute JSON, audience JSON, or simulation YAML.

**Request:** `multipart/form-data`
- `file_data`: The file to upload. Content-Type should be `application/x-yaml` for YAML files or `application/json` for JSON files.

**Important:** The filename determines what type of resource is being uploaded:
- `procedure.yaml` or any `.yaml` file in a procedures path → procedure
- `*.json` in a data_connectors path → data connector
- `attributes.json` → attributes
- `audiences.json` → audiences
- Simulation YAML files → simulation test

**Procedure YAML format** — see `references/procedure-format.md` for the full schema.

For a **new** procedure, set `id: new` in the YAML. The API will assign an ID and return it.

For an **existing** procedure, include the `id` and `version` fields from the downloaded YAML.

**Response:**
```json
{
  "message": "Procedure updated successfully",
  "id": 53500001,
  "type": "procedure",
  "new_file_content": "---\nid: 53500001\nstate: draft\nversion: 42542526\nname: ...",
  "new_file_name": "refund_policy/procedure.yaml",
  "new_file_path": "src/procedures/refund_policy/procedure.yaml"
}
```

**Common errors:**
- `422`: Validation failed. Check the error message — common causes:
  - Missing "Complete when" field (enable `answerbot-fin-task-v3` feature flag)
  - Invalid procedure structure
- `401/403`: Bad token, missing feature flag, or insufficient permissions
- `500`: Server error (may be caused by malformed YAML)

---

### POST /data-connectors

Creates a new draft data connector.

**Request:** `application/json`
```json
{
  "name": "order_lookup"
}
```

**Response:**
```json
{
  "id": 70002,
  "name": "order_lookup",
  "web_url": "https://app.intercom.com/a/apps/abc123/automation/...",
  "message": "Data connector created"
}
```

Note: The data connector is created in **draft** state. Configure it via the web UI at `web_url`, or upload a full JSON definition via `/upload`.

---

### GET /procedures/:id/download

Downloads a single procedure as a ZIP archive containing:
- `procedure.yaml` — the procedure definition
- `simulations/*.yaml` — simulation tests (if `?include_simulations=true`)

**Query params:**
- `include_simulations` (boolean, default false) — include simulation files

**Response:** Binary ZIP data.

---

### GET /data-connectors/:id/download

Downloads a single data connector as JSON.

**Response:** JSON data connector definition.

---

### GET /guidance/:id/download

Downloads a single guidance document as a ZIP.

**Response:** Binary ZIP data containing YAML guidance files.

---

### GET /metadata/download

Downloads workspace metadata as a ZIP containing:
- `attributes.json`
- `audiences.json`
- Various `.fin/` state files (actions, tags, admins, teams)

**Response:** Binary ZIP data.

---

### GET /attributes

Lists all workspace attributes.

**Response:** JSON array of attribute definitions.

---

### GET /audiences

Lists all workspace audiences.

**Response:** JSON array of audience definitions.

---

### GET /workflows

Lists all workflows with summary info.

**Response:**
```json
[
  {
    "id": "90001",
    "title": "Support Workflow",
    "trigger_type": "conversation_opened",
    "state": "live",
    "updated_at": "2026-03-01T10:00:00Z"
  }
]
```

---

### GET /workflows/:id

Exports a single workflow with full detail.

**Response:** Full workflow JSON including all paths, conditions, and actions.

---

### POST /preview

Starts an interactive procedure preview session.

**Request:** `application/json`
```json
{
  "procedure": "<raw YAML content of the procedure>"
}
```

**Response:**
```json
{
  "conversation_id": "conv_123",
  "status": "started"
}
```

---

### GET /preview/:conversation_id/status

Polls the status of a preview conversation.

**Response:**
```json
{
  "status": "in_progress",
  "messages": [
    {
      "type": "agent",
      "content": "Hello! How can I help you today?"
    }
  ]
}
```

---

### POST /procedures/:procedure_id/simulations/:test_id/run

Runs a single simulation test for a procedure.

**Response:** `202 Accepted`
```json
{
  "run_id": "run_abc123"
}
```

Poll `/runs/:run_id` for results (the run is asynchronous).

---

### POST /procedures/:procedure_id/simulations/run

Runs all simulations for a procedure.

**Response:** `202 Accepted`
```json
{
  "run_ids": ["run_abc123", "run_def456"]
}
```

---

### GET /runs/:run_id

Gets the result of a simulation run.

**Response:**
```json
{
  "id": "run_abc123",
  "status": "completed",
  "result": "pass",
  "assertions": [
    {
      "type": "contains",
      "expected": "refund",
      "actual": "I can help you with a refund",
      "passed": true
    }
  ]
}
```

Possible `status` values: `pending`, `running`, `completed`, `failed`

---

### POST /procedures/:procedure_id/simulations/generate

AI-generates simulation tests for a procedure.

**Response:**
```json
{
  "simulations": [
    {
      "name": "happy_path",
      "description": "Customer requests a refund for a recent order",
      "messages": [...]
    }
  ]
}
```

---

## Error Responses

All error responses follow this pattern:

```json
{
  "error": "Human-readable error message"
}
```

Or the Intercom standard format:
```json
{
  "type": "error.list",
  "errors": [
    {
      "code": "unauthorized",
      "message": "Access token is invalid or expired"
    }
  ]
}
```

The `x-request-id` response header is useful for debugging — share it with Intercom support.

## Rate Limits

Standard Intercom API rate limits apply. The SDK endpoints are not separately rate-limited today, but this may change with the Fin Config MCP metering proposal.
