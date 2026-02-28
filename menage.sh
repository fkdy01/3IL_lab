#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================
GITLAB_URL="${GITLAB_URL:https://dvp-srv-gitlab.campus12avenue.fr}"
TOKEN="${GITLAB_TOKEN:-}"
OUT_DIR="${OUT_DIR:-./gitlab_inventory}"
PER_PAGE="${PER_PAGE:-100}"

# Si true, on liste aussi les branches (1 appel API par projet => peut être long)
LIST_BRANCHES="${LIST_BRANCHES:-false}"

if [[ -z "${TOKEN}" ]]; then
  echo "ERROR: set GITLAB_TOKEN env var (Personal Access Token with read_api)."
  exit 1
fi

mkdir -p "${OUT_DIR}"

api() {
  local endpoint="$1"
  shift || true
  curl -sS --fail \
    --header "PRIVATE-TOKEN: ${TOKEN}" \
    --header "Accept: application/json" \
    "${GITLAB_URL}/api/v4/${endpoint}" "$@"
}

# Pagination helper: fetch all pages for a GET endpoint returning a JSON array
fetch_all_pages() {
  local endpoint="$1"
  local page=1
  local tmp

  while :; do
    tmp="$(api "${endpoint}" --get \
      --data-urlencode "per_page=${PER_PAGE}" \
      --data-urlencode "page=${page}")"

    # Stop if empty array
    if [[ "$(echo "${tmp}" | jq 'length')" -eq 0 ]]; then
      break
    fi

    echo "${tmp}"
    page=$((page + 1))
  done
}

# Merge paginated arrays into one array
fetch_all_pages_as_array() {
  local endpoint="$1"
  fetch_all_pages "${endpoint}" | jq -s 'add'
}

echo "==> Export users..."
# Requires admin token to list all users on many GitLab setups
fetch_all_pages_as_array "users" > "${OUT_DIR}/users.raw.json"

# A safer/cleaner view
jq 'map({
  id, username, name,
  state,
  is_admin,
  created_at,
  last_sign_in_at,
  email: (.email // null)
})' "${OUT_DIR}/users.raw.json" > "${OUT_DIR}/users.json"

echo "==> Export proj
