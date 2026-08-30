#!/usr/bin/env bash

set -euo pipefail

readonly project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly local_log_directory="${project_root}/.local"
readonly local_dex_log="${local_log_directory}/dexcli.log"

started_dex=false
dex_process_id=""

cleanup() {
  if [[ "${started_dex}" == true ]] && kill -0 "${dex_process_id}" 2>/dev/null; then
    kill "${dex_process_id}"
    wait "${dex_process_id}" 2>/dev/null || true
  fi
}

wait_for_dex() {
  local attempt
  for attempt in {1..60}; do
    if dexcli health >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

trap cleanup EXIT

cd "${project_root}"
docker compose up -d --wait postgres

if ! dexcli health >/dev/null 2>&1; then
  mkdir -p "${local_log_directory}"
  dexcli dev >"${local_dex_log}" 2>&1 &
  dex_process_id=$!
  started_dex=true
  if ! wait_for_dex; then
    cat "${local_dex_log}" >&2
    exit 1
  fi
fi

export DATABASE_URL="${DATABASE_URL:-postgres://dataset_deal:dataset_deal@127.0.0.1:15432/dataset_deal?sslmode=disable}"
export HTTP_ADDRESS="${HTTP_ADDRESS:-127.0.0.1:8080}"
export DEX_WORKER_BIND_ADDRESS="${DEX_WORKER_BIND_ADDRESS:-127.0.0.1:8803}"

"${project_root}/bin/dataset-deal-webapp"
