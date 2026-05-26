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

  ${lib.getExe gnused} "s|DEV_DIR|$devDir|g" "$devDir/state.template.json" > "$devDir/state.json"
  ${lib.getExe gnused} "s|WORKER_ID|$(cat "$devDir/worker.id")|g" "$devDir/state.template.json" > "$devDir/state.json"
  export GRADIENT_STATE_FILE="$devDir/state.json"
  export GRADIENT_CREDENTIALS_DIR="$devDir"

''
