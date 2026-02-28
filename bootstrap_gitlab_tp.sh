ensure_project() {
  local group_id="$1"
  local project_name="$2"
  local project_path="$3"
  local subgroup_fullpath="$4"

  api_call GET "/groups/$group_id/projects?per_page=100"
  [[ "$API_STATUS" == "200" ]] || { log "❌ List projects failed (HTTP $API_STATUS)"; log "$API_BODY"; exit 1; }
  require_json "List projects"
  echo "$API_BODY" | jq -e 'type=="array"' >/dev/null || { log "❌ List projects not array"; log "$API_BODY"; exit 1; }

  local existing_id
  existing_id="$(echo "$API_BODY" | jq -r --arg p "$project_path" '.[] | select(.path==$p) | .id' | head -n1 || true)"
  if [[ -n "${existing_id:-}" && "${existing_id}" != "null" ]]; then
    log "[OK] Project exists: $subgroup_fullpath/$project_path (id=$existing_id)"
    return
  fi

  log "[..] Creating project: $subgroup_fullpath/$project_path"
  api_call POST "/projects" \
    --data-urlencode "name=$project_name" \
    --data-urlencode "path=$project_path" \
    --data-urlencode "namespace_id=$group_id" \
    --data-urlencode "visibility=$VISIBILITY" \
    --data-urlencode "initialize_with_readme=true"

  [[ "$API_STATUS" == "201" ]] || { log "❌ Create project failed (HTTP $API_STATUS)"; log "$API_BODY"; exit 1; }

  local id
  id="$(require_id "POST project $subgroup_fullpath/$project_path")"
  log "[OK] Project created: $subgroup_fullpath/$project_path (id=$id)"
}

# ---- MAIN ----
command -v jq >/dev/null || { echo "jq is required"; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required"; exit 1; }

api_call GET "/user"
[[ "$API_STATUS" == "200" ]] || { log "❌ Token invalid (HTTP $API_STATUS)"; log "$API_BODY"; exit 1; }
require_json "GET /user"
log "[OK] token user: $(echo "$API_BODY" | jq -r '.username')"

ROOT_ID="$(ensure_root_group)"
log "[OK] Root group id: $ROOT_ID"

for s in "${STUDENTS[@]}"; do
  log "==============================="
  log "[STUDENT] $s"
  SUB_ID="$(ensure_subgroup "$s" "$ROOT_ID")"
  SUB_PATH="$ROOT_GROUP_PATH/$s"

  ensure_project "$SUB_ID" "infra"  "infra"  "$SUB_PATH"
  ensure_project "$SUB_ID" "api"    "api"    "$SUB_PATH"
  ensure_project "$SUB_ID" "gitops" "gitops" "$SUB_PATH"

  log "[DONE] $s"
done

log "==============================="
log "[ALL DONE] Provisioned under: $ROOT_GROUP_PATH"
