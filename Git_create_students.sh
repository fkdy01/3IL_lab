#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIG
# =========================
GITLAB_URL="${GITLAB_URL:-https://dvp-srv-gitlab.campus12avenue.fr}"
GITLAB_TOKEN="${GITLAB_TOKEN:-CHANGE_ME_TOKEN}"

ROOT_GROUP_FULLPATH="${ROOT_GROUP_FULLPATH:-tp-devops-2526}"   # le groupe racine dÃ©jÃ  crÃ©Ã©
EMAIL_DOMAIN="${EMAIL_DOMAIN:-3il.fr}"                         # adapte si besoin

# 10 Ã©tudiants
STUDENTS=(s01 s02 s03 s04 s05 s06 s07 s08 s09 s10)

# GitLab access levels: 40 = Maintainer
MAINTAINER_LEVEL=40

# sortie
OUT_CSV="${OUT_CSV:-students_credentials.csv}"

log(){ echo >&2 -e "$*"; }

API_BODY=""
API_STATUS=""

api_call() {
  local method="$1"; shift
  local path="$1"; shift

  local tmp
  tmp="$(mktemp)"

  API_STATUS="$(curl -sS -o "$tmp" -w "%{http_code}" \
    -X "$method" \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    -H "Accept: application/json" \
    "$GITLAB_URL/api/v4$path" "$@")"

  API_BODY="$(cat "$tmp")"
  rm -f "$tmp"
}

require_json() {
  local ctx="$1"
  if ! echo "$API_BODY" | jq -e . >/dev/null 2>&1; then
    log "âŒ $ctx: not JSON (HTTP $API_STATUS)"
    log "$API_BODY"
    exit 1
  fi
}

urlencode() {
  python3 - <<'PY' "$1"
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=''))
PY
}

# ---------- GitLab helpers ----------

get_user_by_username() {
  local username="$1"
  # GET /users?username=... returns array
  api_call GET "/users?username=$(urlencode "$username")"
  require_json "get_user_by_username($username)"
  echo "$API_BODY" | jq -r '.[0].id // empty'
}

create_user() {
  local username="$1"
  local name="$2"
  local email="$3"
  local password="$4"

  api_call POST "/users" \
    --data-urlencode "username=$username" \
    --data-urlencode "name=$name" \
    --data-urlencode "email=$email" \
    --data-urlencode "password=$password" \
    --data-urlencode "skip_confirmation=true" \
    --data-urlencode "reset_password=false" \
    --data-urlencode "force_random_password=false" \
    --data-urlencode "projects_limit=0" \
    --data-urlencode "can_create_group=false" \
    --data-urlencode "confirm=false" \
    --data-urlencode "external=false" \
    --data-urlencode "private_profile=true" \
    --data-urlencode "theme_id=3" \
    --data-urlencode "color_scheme_id=1" \
    --data-urlencode "note=TP DevOps 25-26" \
    --data-urlencode "password_expires_at=" \
    --data-urlencode "change_password_at_next_sign_in=true" \
    --data-urlencode "admin=false"

  require_json "create_user($username)"
  local id
  id="$(echo "$API_BODY" | jq -r '.id // empty')"
  if [[ -z "$id" || "$id" == "null" ]]; then
    log "âŒ create_user($username) failed (HTTP $API_STATUS)"
    log "$API_BODY"
    exit 1
  fi
  echo "$id"
}

get_group_id_by_fullpath() {
  local fullpath="$1"
  local enc
  enc="$(urlencode "$fullpath")"
  api_call GET "/groups/$enc"
  # 200 expected
  if [[ "$API_STATUS" != "200" ]]; then
    log "âŒ group not found: $fullpath (HTTP $API_STATUS)"
    log "$API_BODY"
    exit 1
  fi
  require_json "get_group_id_by_fullpath($fullpath)"
  local gid
  gid="$(echo "$API_BODY" | jq -r '.id // empty')"
  if [[ -z "$gid" || "$gid" == "null" ]]; then
    log "âŒ could not read group id for $fullpath"
    log "$API_BODY"
    exit 1
  fi
  echo "$gid"
}

add_user_to_group_maintainer() {
  local group_id="$1"
  local user_id="$2"

  # Try add; if already member, update
  api_call POST "/groups/$group_id/members" \
    --data-urlencode "user_id=$user_id" \
    --data-urlencode "access_level=$MAINTAINER_LEVEL"

  # 201 created, 409 already exists, or 400 with message
  if [[ "$API_STATUS" == "201" ]]; then
    return 0
  fi

  # If already exists, update membership
  api_call PUT "/groups/$group_id/members/$user_id" \
    --data-urlencode "access_level=$MAINTAINER_LEVEL"

  if [[ "$API_STATUS" != "200" ]]; then
    log "âŒ failed to add/update member user_id=$user_id in group_id=$group_id (HTTP $API_STATUS)"
    log "$API_BODY"
    exit 1
  fi
}

gen_password() {
  # 18 chars base64 urlsafe-ish
  python3 - <<'PY'
import secrets, string
alphabet = string.ascii_letters + string.digits + "-_@#"
#print("".join(secrets.choice(alphabet) for _ in range(18)))
print("bienvenue")
PY
}

# =========================
# MAIN
# =========================
command -v jq >/dev/null || { echo "jq is required"; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required"; exit 1; }
command -v curl >/dev/null || { echo "curl is required"; exit 1; }

# Sanity token
api_call GET "/user"
if [[ "$API_STATUS" != "200" ]]; then
  log "âŒ Token invalid (HTTP $API_STATUS)"
  log "$API_BODY"
  exit 1
fi
require_json "GET /user"
log "[OK] API as: $(echo "$API_BODY" | jq -r '.username')"

# Header CSV
echo "username,email,password,user_id,group_fullpath,group_id" > "$OUT_CSV"

for s in "${STUDENTS[@]}"; do
  log "==============================="
  log "[STUDENT] $s"

  # 1) ensure group exists
  group_fullpath="${ROOT_GROUP_FULLPATH}/${s}"
  group_id="$(get_group_id_by_fullpath "$group_fullpath")"
  log "[OK] group: $group_fullpath (id=$group_id)"

  # 2) ensure user exists
  user_id="$(get_user_by_username "$s" || true)"
  if [[ -n "${user_id:-}" ]]; then
    log "[OK] user exists: $s (id=$user_id)"
    password=""  # we don't know it
    email="$(api_call GET "/users/$user_id"; require_json "GET user $user_id"; echo "$API_BODY" | jq -r '.email')"
  else
    email="${s}@${EMAIL_DOMAIN}"
    password="$(gen_password)"
    user_id="$(create_user "$s" "Student ${s}" "$email" "$password")"
    log "[OK] user created: $s (id=$user_id, email=$email)"
  fi

  # 3) add to group as maintainer
  add_user_to_group_maintainer "$group_id" "$user_id"
  log "[OK] added/updated membership: $s => Maintainer on $group_fullpath"

  # 4) output csv
  echo "${s},${email},${password},${user_id},${group_fullpath},${group_id}" >> "$OUT_CSV"
done

log "==============================="
log "[ALL DONE] Credentials written to: $OUT_CSV"
log "Note: if password column is empty => user already existed."
