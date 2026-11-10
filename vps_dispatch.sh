#!/usr/bin/env bash
# 在甲骨文 VPS 上运行：采集状态并触发 GitHub Actions 代推 PushDeer
# 不依赖 Mac 在线。需要 .env 中的 GH_DISPATCH_TOKEN（repo 权限 PAT）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "${SCRIPT_DIR}/.env"
  set +a
fi

GH_DISPATCH_TOKEN="${GH_DISPATCH_TOKEN:-}"
GITHUB_REPO="${GITHUB_REPO:-cafefrappe/o}"
EVENT_TYPE="${EVENT_TYPE:-vps_status}"

if [[ -z "${GH_DISPATCH_TOKEN}" ]]; then
  echo "错误：未设置 GH_DISPATCH_TOKEN（GitHub PAT，需有 repo 权限）" >&2
  exit 1
fi

chmod +x "${SCRIPT_DIR}/collect_status.sh"
status_out="$("${SCRIPT_DIR}/collect_status.sh")"
title="$(printf '%s\n' "${status_out}" | head -n 1)"
desp="$(printf '%s\n' "${status_out}" | tail -n +2)"

payload="$(TITLE="${title}" DESP="${desp}" EVENT_TYPE="${EVENT_TYPE}" python3 - <<'PY'
import json, os
print(json.dumps({
  "event_type": os.environ["EVENT_TYPE"],
  "client_payload": {
    "title": os.environ["TITLE"],
    "desp": os.environ["DESP"],
  },
}, ensure_ascii=False))
PY
)"

resp="$(curl -fsS --max-time 30 \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GH_DISPATCH_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${GITHUB_REPO}/dispatches" \
  -d "${payload}")"

echo "已触发 GitHub Actions 代推: ${title}"
if [[ -n "${resp}" ]]; then
  echo "响应: ${resp}"
fi
