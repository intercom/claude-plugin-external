#!/usr/bin/env bash
#
# fin-api.sh — Thin HTTP client for the Intercom Fin SDK API
#
# Usage:
#   fin-api.sh <command> [options]
#
# Environment:
#   FIN_API_TOKEN  - Bearer token (required, or pass --token)
#   FIN_API_URL    - API base URL (default: https://api.intercom.io)
#
# Commands:
#   manifest                          - List all workspace resources
#   download-procedure <id>           - Download a procedure (returns ZIP, extracts to stdout as YAML)
#   download-data-connector <id>      - Download a data connector (JSON)
#   download-metadata                 - Download workspace metadata (attributes, audiences, etc.)
#   download-guidance <id>            - Download guidance (YAML)
#   upload <file>                     - Upload a procedure YAML, data connector JSON, or simulation
#   create-data-connector <name>      - Create a new draft data connector
#   list-attributes                   - List all attributes
#   list-audiences                    - List all audiences
#   list-workflows                    - List all workflows
#   show-workflow <id>                - Export a single workflow
#   preview <procedure_file>          - Start an interactive preview session
#   preview-status <conversation_id>  - Poll preview status
#   run-simulation <proc_id> <test_id> - Run a single simulation
#   run-all-simulations <proc_id>     - Run all simulations for a procedure
#   simulation-result <run_id>        - Get simulation run result
#   generate-simulations <proc_id>    - AI-generate simulations for a procedure
#
set -euo pipefail

# --- Config ---
TOKEN="${FIN_API_TOKEN:-}"
BASE_URL="${FIN_API_URL:-https://api.intercom.io}"
COMMAND=""
VERBOSE=0

# --- Arg parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)  TOKEN="$2"; shift 2 ;;
    --url)    BASE_URL="$2"; shift 2 ;;
    --verbose|-v) VERBOSE=1; shift ;;
    --help|-h)
      head -30 "$0" | grep '^#' | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$COMMAND" ]]; then
        COMMAND="$1"; shift
      else
        break  # remaining args are command-specific
      fi
      ;;
  esac
done

if [[ -z "$TOKEN" ]]; then
  echo "Error: No API token. Set FIN_API_TOKEN or pass --token <token>" >&2
  exit 1
fi

if [[ -z "$COMMAND" ]]; then
  echo "Error: No command specified. Run with --help for usage." >&2
  exit 1
fi

# --- Helpers ---
auth_header="Authorization: Bearer ${TOKEN}"

# Check HTTP response and print error details on failure
check_response() {
  local http_code="$1"
  local body="$2"
  local url="$3"
  if [[ "$http_code" -ge 400 ]]; then
    echo "Error: HTTP ${http_code} from ${url}" >&2
    case "$http_code" in
      401) echo "Authentication failed. Check your API token." >&2 ;;
      403) echo "Access forbidden. The fin-sdk feature flag may not be enabled on this workspace." >&2 ;;
      404) echo "Endpoint not found. Check the API URL and resource ID." >&2 ;;
      422) echo "Validation error." >&2 ;;
      500) echo "Server error." >&2 ;;
    esac
    if [[ -n "$body" ]]; then
      echo "Response: $body" >&2
    fi
    return 1
  fi
}

api_get() {
  local endpoint="$1"
  local url="${BASE_URL}/fin-sdk/${endpoint}"
  if [[ $VERBOSE -eq 1 ]]; then echo "GET $url" >&2; fi
  local tmpfile
  tmpfile=$(mktemp)
  local http_code
  http_code=$(curl -sS -w '%{http_code}' -o "$tmpfile" \
    -H "$auth_header" \
    -H "Accept: application/json" \
    "$url")
  local body
  body=$(cat "$tmpfile")
  rm -f "$tmpfile"
  check_response "$http_code" "$body" "$url" || return 1
  echo "$body"
}

api_post_json() {
  local endpoint="$1"
  local body="${2:-"{}"}"
  local url="${BASE_URL}/fin-sdk/${endpoint}"
  if [[ $VERBOSE -eq 1 ]]; then echo "POST $url" >&2; echo "$body" >&2; fi
  local tmpfile
  tmpfile=$(mktemp)
  local http_code
  http_code=$(curl -sS -w '%{http_code}' -o "$tmpfile" \
    -H "$auth_header" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$body" \
    "$url")
  local resp
  resp=$(cat "$tmpfile")
  rm -f "$tmpfile"
  check_response "$http_code" "$resp" "$url" || return 1
  echo "$resp"
}

api_post_file() {
  local endpoint="$1"
  local filepath="$2"
  local url="${BASE_URL}/fin-sdk/${endpoint}"
  local filename
  filename=$(basename "$filepath")
  local content_type="application/x-yaml"
  if [[ "$filename" == *.json ]]; then content_type="application/json"; fi

  if [[ $VERBOSE -eq 1 ]]; then echo "POST $url (file: $filepath)" >&2; fi
  local tmpfile
  tmpfile=$(mktemp)
  local http_code
  http_code=$(curl -sS -w '%{http_code}' -o "$tmpfile" \
    -H "$auth_header" \
    -H "Accept: application/json" \
    -F "file_data=@${filepath};type=${content_type};filename=${filename}" \
    "$url")
  local resp
  resp=$(cat "$tmpfile")
  rm -f "$tmpfile"
  check_response "$http_code" "$resp" "$url" || return 1
  echo "$resp"
}

api_get_binary() {
  local endpoint="$1"
  local url="${BASE_URL}/fin-sdk/${endpoint}"
  if [[ $VERBOSE -eq 1 ]]; then echo "GET $url (binary)" >&2; fi
  local tmpfile
  tmpfile=$(mktemp)
  local http_code
  http_code=$(curl -sS -w '%{http_code}' -o "$tmpfile" \
    -H "$auth_header" \
    "$url")
  if [[ "$http_code" -ge 400 ]]; then
    local body
    body=$(cat "$tmpfile")
    rm -f "$tmpfile"
    check_response "$http_code" "$body" "$url" || return 1
  fi
  cat "$tmpfile"
  rm -f "$tmpfile"
}

# Extract a ZIP from stdin and print the contents of YAML/JSON files
extract_zip_contents() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT
  cat > "$tmpdir/archive.zip"
  unzip -q -o "$tmpdir/archive.zip" -d "$tmpdir/out" 2>/dev/null || true
  find "$tmpdir/out" -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.txt' \) | sort | while read -r f; do
    local relpath="${f#$tmpdir/out/}"
    echo "--- FILE: ${relpath} ---"
    cat "$f"
    echo ""
  done
}

# --- Pretty-print JSON helper (never hangs) ---
pretty_json() {
  local input="$1"
  echo "$input" | python3 -m json.tool 2>/dev/null || echo "$input"
}

# --- Commands ---
case "$COMMAND" in

  manifest)
    result=$(api_get "manifest") && pretty_json "$result"
    ;;

  download-procedure)
    proc_id="${1:?Usage: download-procedure <procedure_id>}"
    api_get_binary "procedures/${proc_id}/download?include_simulations=true" | extract_zip_contents
    ;;

  download-data-connector)
    dc_id="${1:?Usage: download-data-connector <data_connector_id>}"
    result=$(api_get "data-connectors/${dc_id}/download") && pretty_json "$result"
    ;;

  download-metadata)
    api_get_binary "metadata/download" | extract_zip_contents
    ;;

  download-guidance)
    guidance_id="${1:?Usage: download-guidance <guidance_id>}"
    api_get_binary "guidance/${guidance_id}/download" | extract_zip_contents
    ;;

  upload)
    filepath="${1:?Usage: upload <file_path>}"
    if [[ ! -f "$filepath" ]]; then
      echo "Error: File not found: $filepath" >&2; exit 1
    fi
    result=$(api_post_file "upload" "$filepath") && pretty_json "$result"
    ;;

  create-data-connector)
    name="${1:?Usage: create-data-connector <name>}"
    json_body=$(python3 -c "import sys,json; print(json.dumps({'name': sys.argv[1]}))" "$name")
    result=$(api_post_json "data-connectors" "$json_body") && pretty_json "$result"
    ;;

  list-attributes)
    result=$(api_get "attributes") && pretty_json "$result"
    ;;

  list-audiences)
    result=$(api_get "audiences") && pretty_json "$result"
    ;;

  list-workflows)
    result=$(api_get "workflows") && pretty_json "$result"
    ;;

  show-workflow)
    wf_id="${1:?Usage: show-workflow <workflow_id>}"
    result=$(api_get "workflows/${wf_id}") && pretty_json "$result"
    ;;

  preview)
    proc_file="${1:?Usage: preview <procedure_file>}"
    if [[ ! -f "$proc_file" ]]; then
      echo "Error: File not found: $proc_file" >&2; exit 1
    fi
    proc_content=$(cat "$proc_file")
    result=$(api_post_json "preview" "{\"procedure\": $(echo "$proc_content" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}") && pretty_json "$result"
    ;;

  preview-status)
    conv_id="${1:?Usage: preview-status <conversation_id>}"
    result=$(api_get "preview/${conv_id}/status") && pretty_json "$result"
    ;;

  run-simulation)
    proc_id="${1:?Usage: run-simulation <procedure_id> <test_id>}"
    test_id="${2:?Usage: run-simulation <procedure_id> <test_id>}"
    result=$(api_post_json "procedures/${proc_id}/simulations/${test_id}/run") && pretty_json "$result"
    ;;

  run-all-simulations)
    proc_id="${1:?Usage: run-all-simulations <procedure_id>}"
    result=$(api_post_json "procedures/${proc_id}/simulations/run") && pretty_json "$result"
    ;;

  simulation-result)
    run_id="${1:?Usage: simulation-result <run_id>}"
    result=$(api_get "runs/${run_id}") && pretty_json "$result"
    ;;

  generate-simulations)
    proc_id="${1:?Usage: generate-simulations <procedure_id>}"
    result=$(api_post_json "procedures/${proc_id}/simulations/generate") && pretty_json "$result"
    ;;

  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Run with --help for usage." >&2
    exit 1
    ;;
esac
