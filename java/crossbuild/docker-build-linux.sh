#!/usr/bin/env bash
# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.

set -euo pipefail
set -x

: "${J:=1}"

mkdir -p /rocksdb-local-build

rm -rf /rocksdb-local-build/*
cp -r /rocksdb-host/* /rocksdb-local-build
cd /rocksdb-local-build

export GETDEPS_SCRATCH_PATH="${GETDEPS_SCRATCH_PATH:-/getdeps-scratch}"
PY="${PYTHON:-python3}"

TOOLSET=""
if hash scl 2>/dev/null; then
  for ts in devtoolset-12 devtoolset-11 devtoolset-8 devtoolset-7 devtoolset-2; do
    if scl --list 2>/dev/null | grep -q "$ts"; then
      TOOLSET="$ts"
      break
    fi
  done
fi

run() {
  local cmd="GETDEPS_SCRATCH_PATH='${GETDEPS_SCRATCH_PATH}' PYTHON='${PY}' $*"

  if [[ -n "${TOOLSET}" ]]; then
    scl enable "${TOOLSET}" "${cmd}"
  else
    bash -lc "${cmd}"
  fi
}

get_folly_path() {
  (
    cd third-party/folly
    "${PY}" build/fbcode_builder/getdeps.py show-inst-dir \
      --scratch-path "${GETDEPS_SCRATCH_PATH}"
  )
}

have_folly() {
  local p="$1"
  [[ -d "$p/include/folly" && -f "$p/lib/libfolly.a" ]]
}

run "make clean-not-downloaded"

FOLLY_PATH="$(get_folly_path)"
export FOLLY_PATH
echo "Using FOLLY_PATH=$FOLLY_PATH"

BUILD_VARS=(
  "GETDEPS_SCRATCH_PATH=$GETDEPS_SCRATCH_PATH"
  "FOLLY_PATH=$FOLLY_PATH"
  "LIB_MODE=static"
  "DISABLE_JEMALLOC=1"
  "USE_RTTI=1"
  "DISABLE_WARNING_AS_ERROR=1"
  "ROCKSDB_USE_IO_URING=1"
  "USE_COROUTINES=1"
  "EXTRA_CFLAGS=-Wno-error"
  "PORTABLE=1"
  "J=$J"
)

if have_folly "$FOLLY_PATH"; then
  echo "Reusing prebuilt folly at $FOLLY_PATH"
else
  run "make checkout_folly"
  run "GETDEPS_SCRATCH_PATH=$GETDEPS_SCRATCH_PATH make build_folly"

  FOLLY_PATH="$(get_folly_path)"
  export FOLLY_PATH
  echo "Using FOLLY_PATH=$FOLLY_PATH"

  have_folly "$FOLLY_PATH" || { echo "Bad FOLLY_PATH: $FOLLY_PATH"; exit 1; }
fi

run "${BUILD_VARS[*]} make -j${J} rocksdbjavastatic"

cp java/target/librocksdbjni-linux*.so \
   java/target/rocksdbjni-*-linux*.jar \
   java/target/rocksdbjni-*-linux*.jar.sha1 \
   /rocksdb-java-target
