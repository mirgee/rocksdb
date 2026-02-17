#!/usr/bin/env bash
set -euo pipefail

args=()
for a in "$@"; do
  case "$a" in
    -fno-rtti|-fno-exceptions) continue ;;
  esac
  args+=("$a")
done

# Force policy at the end (last flag wins)
exec /opt/rh/devtoolset-12/root/usr/bin/g++ "${args[@]}" -frtti -fexceptions
