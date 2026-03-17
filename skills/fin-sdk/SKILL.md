---
name: fin-sdk
description: >
  Manage Intercom Fin AI agent configuration via the Fin SDK REST API.
  Provides a shell-based HTTP client for procedures, data connectors,
  guidance, workflows, attributes, audiences, and simulations — no
  npm or external dependencies required. This skill should be used when
  the user asks to "configure Fin", "create a procedure", "upload a
  procedure", "pull my Fin workspace", "set up Fin", "manage procedures",
  "run simulations", "test a procedure", "list my procedures", "download
  procedures", "create a data connector", "preview a procedure", "list
  workflows", "list attributes", or any task involving Fin workspace
  management.
license: MIT
---

# Fin SDK — Intercom AI Agent Configuration

Manage Fin AI agent configuration directly via the Intercom Fin SDK REST API. This skill provides a lightweight HTTP client and complete API reference — no external CLI tools or npm dependencies required.

## Prerequisites

An API token is required. Obtain one from the Intercom Developer Hub:
- Navigate to `https://app.intercom.com/a/apps/_/developer-hub`
- Create a Developer App and copy the Access Token
- The workspace must have the `fin-sdk` feature flag enabled

Store the token in the environment:
```bash
export FIN_API_TOKEN="<your_token>"
```

Optionally set a custom API URL (defaults to `https://api.intercom.io`):
```bash
export FIN_API_URL="https://api.intercom.io"
```

## Core Tool: fin-api.sh

All Fin SDK operations go through `scripts/fin-api.sh` — a bash wrapper around curl that handles authentication, file uploads, and ZIP extraction.

### Quick Reference

| Command | What it does |
|---------|-------------|
| `fin-api.sh manifest` | List all procedures, data connectors, guidance in the workspace |
| `fin-api.sh download-procedure <id>` | Download a procedure as YAML |
| `fin-api.sh download-data-connector <id>` | Download a data connector as JSON |
| `fin-api.sh download-metadata` | Download attributes, audiences, workspace config |
| `fin-api.sh upload <file>` | Upload a procedure YAML, data connector JSON, or simulation |
| `fin-api.sh create-data-connector <name>` | Create a new draft data connector |
| `fin-api.sh list-attributes` | List all workspace attributes |
| `fin-api.sh list-audiences` | List all workspace audiences |
| `fin-api.sh list-workflows` | List all workflows |
| `fin-api.sh show-workflow <id>` | Export a single workflow |
| `fin-api.sh download-guidance <id>` | Download a guidance document |
| `fin-api.sh preview <procedure_file>` | Start an interactive preview session |
| `fin-api.sh preview-status <conversation_id>` | Poll preview conversation status |
| `fin-api.sh run-simulation <proc_id> <test_id>` | Run one simulation test |
| `fin-api.sh run-all-simulations <proc_id>` | Run all simulation tests for a procedure |
| `fin-api.sh simulation-result <run_id>` | Get simulation run result (poll until completed) |
| `fin-api.sh generate-simulations <proc_id>` | AI-generate simulation tests |

Pass `--token <token>` to override `FIN_API_TOKEN`. Pass `--url <url>` to override `FIN_API_URL`. Pass `--verbose` for request debugging.

## Common Workflows

### 1. Explore a Workspace

Start by fetching the manifest to see what exists:

```bash
bash scripts/fin-api.sh manifest
```

This returns all procedures, data connectors, and guidance with their IDs. Use the IDs to download specific resources.

### 2. Download and Edit a Procedure

```bash
# Download procedure YAML
bash scripts/fin-api.sh download-procedure 53500001 > procedure.yaml

# Edit the file, then upload
bash scripts/fin-api.sh upload procedure.yaml
```

The upload response includes the new `version` number. Download the latest version before editing to avoid conflicts.

### 3. Create a New Procedure

Write a procedure YAML file with `id: new`, then upload it. See `references/procedure-format.md` for the full schema.

```bash
# Create a temp file with the procedure
cat > /tmp/my_procedure.yaml << 'EOF'
name: Order Tracking
id: new
trigger_description: Customer asks about order status or tracking
targeting:
  channels:
    - web
  audience: everyone
procedure:
  main:
    - instructions: Ask the customer for their order number.
    - instructions: Look up the order and provide the current status.
    - instructions: If the order is delayed, apologize and offer next steps.
EOF

# Upload it
bash scripts/fin-api.sh upload /tmp/my_procedure.yaml
```

The response includes the assigned `id` — save it for future updates.

### 4. Run Simulations

```bash
# Run all simulations for a procedure
bash scripts/fin-api.sh run-all-simulations 53500001

# Poll for results (simulations are async)
bash scripts/fin-api.sh simulation-result run_abc123
```

### 5. Bulk Operations

To update multiple procedures, download each one, modify them, and re-upload:

```bash
# Get all procedure IDs from manifest
bash scripts/fin-api.sh manifest | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data['procedures']:
    print(p['id'], p['name'])
"

# Download each, edit, re-upload
for id in 53500001 53500002 53500003; do
  bash scripts/fin-api.sh download-procedure $id > "/tmp/proc_${id}.yaml"
done

# ... edit files ...

for f in /tmp/proc_*.yaml; do
  bash scripts/fin-api.sh upload "$f"
done
```

## Writing Procedures

When creating or editing procedures, consult `references/procedure-format.md` for:
- Complete YAML schema with all fields
- Temporary attributes (scoped variables)
- Read/write attribute syntax (`<read attr="..." />`, `<write attr="...">...</write>`)
- Condition blocks with operators
- Sub-procedure calls
- Data connector references
- Handoff to human agents
- Simulation test format

Key rules:
- Every procedure must have a `procedure.main` entry point
- Use `id: new` for new procedures, include `id` and `version` for updates
- `trigger_description` is critical — it determines when Fin activates this procedure
- `targeting.channels` and `targeting.audience` are required

## API Reference

For the complete endpoint specification, consult `references/api-spec.md`. It covers:
- All 20+ endpoints with request/response formats
- Authentication details
- Error response formats
- Rate limiting notes

## Troubleshooting

**401/403 errors:** Verify the token is correct and the `fin-sdk` feature flag is enabled on the workspace. The error message may say "Authentication failed" even when the real issue is a missing feature flag.

**422 errors on upload:** Usually a validation issue. Common cause: workspace needs the `answerbot-fin-task-v3` feature flag enabled. Check the error message for specifics.

**500 errors on download:** Some workspaces with many resources can timeout. Try downloading individual procedures instead of the full workspace.

**Procedures can't be edited in UI after SDK upload:** Known issue with `validation_source` mismatch. The procedure works correctly but the UI save button may fail. Re-upload via the SDK to make changes.
