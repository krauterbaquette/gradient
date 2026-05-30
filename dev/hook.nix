# dev shell hook
{
  lib,
  libargon2,
  openssl,
  gnused,
}:
''
  devDir="$(git rev-parse --show-toplevel)/dev"
  printf %s "password" | ${lib.getExe libargon2} "$(${lib.getExe openssl} rand -hex 16)" -id -e -m 15 -t 2 -p 1 > "$devDir/gradient_user_admin_password"

  WORKER_ID="$(cat "$devDir/worker/worker-id")"

  ${lib.getExe gnused} "s|DEV_DIR|$devDir|g" "$devDir/state.template.json" > "$devDir/state.json"
  ${lib.getExe gnused} "s|WORKER_ID|$WORKER_ID|g" "$devDir/state.template.json" > "$devDir/state.json"
  export GRADIENT_STATE_FILE="$devDir/state.json"
  export GRADIENT_CREDENTIALS_DIR="$devDir"

  # worker config
  export GRADIENT_WORKER_SERVER_URL=ws://localhost:3030/proto
  export GRADIENT_WORKER_PEERS="*:$(cat "$devDir"/gradient_worker_"$WORKER_ID"_token)"
  export GRADIENT_WORKER_DATA_DIR="$devDir/worker_data"

''
