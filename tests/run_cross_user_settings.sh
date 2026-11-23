#!/bin/sh
# Compile and run the cross-user settings tests against the Delphi generator
# units. Free Pascal 3.2 cannot compile the anonymous method in
# Pkg.Json.StubField, so this builds the Free Pascal trunk compiler and RTL
# when they are not already present.
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
FPC_SRC="${FPC_SRC:-/tmp/fpc-src}"
FPC_UNITS="${FPC_UNITS:-/tmp/fpctrunk-units}"
PPC="$FPC_SRC/compiler/ppcx64"
RTL="$FPC_SRC/rtl/units/x86_64-linux"
OUT="${TMPDIR:-/tmp}/json-to-delphi-settings-tests"

if [ ! -x "$PPC" ] || [ ! -f "$RTL/sysutils.ppu" ]; then
  if ! command -v fpc >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y fpc
  fi
  if [ ! -d "$FPC_SRC/.git" ]; then
    rm -rf "$FPC_SRC"
    git clone --depth 1 https://gitlab.com/freepascal.org/fpc/source.git "$FPC_SRC"
  fi
  make -C "$FPC_SRC" compiler -j"$(nproc)"
  make -C "$FPC_SRC" rtl -j"$(nproc)"
fi

mkdir -p "$FPC_UNITS"
if [ ! -f "$FPC_UNITS/generics.collections.ppu" ]; then
  "$PPC" -Fu"$RTL" -Fu"$FPC_UNITS" -FE"$FPC_UNITS" \
    "$FPC_SRC/packages/rtl-objpas/src/inc/variants.pp"
  "$PPC" -Fu"$RTL" -Fu"$FPC_UNITS" -FE"$FPC_UNITS" \
    "$FPC_SRC/packages/rtl-objpas/src/inc/rtti.pp"
  for unit in generics.strings generics.helpers generics.hashes generics.memoryexpanders generics.defaults generics.collections; do
    "$PPC" -Mdelphi -Fu"$RTL" -Fu"$FPC_UNITS" -FE"$FPC_UNITS" \
      "$FPC_SRC/packages/rtl-generics/src/$unit.pas"
  done
fi

mkdir -p "$OUT"
# The mapper uses Pkg.Json.SubTypes. The source file name differs in case.
ln -sfn "$ROOT/Pkg.JSON.SubTypes.pas" "$OUT/Pkg.Json.SubTypes.pas"

"$PPC" -Mdelphi -Fu"$RTL" -Fu"$FPC_UNITS" -Fu"$ROOT/tests/rtl" -Fu"$ROOT" -Fu"$OUT" \
  -FE"$OUT" "$ROOT/tests/CrossUserSettingsTests.pas"

"$OUT/CrossUserSettingsTests"
