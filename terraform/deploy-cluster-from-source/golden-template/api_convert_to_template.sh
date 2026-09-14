#!/usr/bin/env bash
set -euo pipefail

PM_API_TOKEN_ID="$1"
shift
PM_API_TOKEN_SECRET="$1"
shift
NODE="$1" # node name
shift
PVE_HOST="$1" #node ip
shift
VMID="$1" #vm id


AUTH="Authorization: PVEAPIToken=${PM_API_TOKEN_ID}=${PM_API_TOKEN_SECRET}"

# 1. Stop the VM — Proxmox requires it to be off before templating
curl -sk -X POST -H "$AUTH" \
  "https://${PVE_HOST}:8006/api2/json/nodes/${NODE}/qemu/${VMID}/status/stop"

# poll until it's actually stopped
until [ "$(curl -sk -H "$AUTH" "https://${PVE_HOST}:8006/api2/json/nodes/${NODE}/qemu/${VMID}/status/current" | jq -r .data.status)" = "stopped" ]; do
  sleep 2
done

# 2. Convert to template (returns a task UPID — it's async)
UPID=$(curl -sk -X POST -H "$AUTH" \
  "https://${PVE_HOST}:8006/api2/json/nodes/${NODE}/qemu/${VMID}/template" | jq -r .data)

# 3. Poll the task until it finishes, then check it actually succeeded
for i in $(seq 1 150); do   # ~5 min at 2s
  TASK=$(curl -sk -H "$AUTH" \
    "https://${PVE_HOST}:8006/api2/json/nodes/${NODE}/tasks/${UPID}/status")
  STATUS=$(echo "$TASK" | jq -r .data.status)
  if [ "$STATUS" = "stopped" ]; then
    EXIT_STATUS=$(echo "$TASK" | jq -r .data.exitstatus)
    [ "$EXIT_STATUS" = "OK" ] || { echo "Template conversion failed: ${EXIT_STATUS}" >&2; exit 1; }
    break
  fi
  sleep 2
done