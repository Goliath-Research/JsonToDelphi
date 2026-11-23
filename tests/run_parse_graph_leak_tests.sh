#!/usr/bin/env bash
# Compile Pkg.Json.Mapper and the units it parses with, then run the
# repeated-parse leak tests. Exit status is 1 while the leak is present.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${TMPDIR:-/tmp}/jsontodelphi-parse-graph-tests"
FPC_ROOT="${FPC_ROOT:-/tmp/fpc331}"
PPC="${FPC_ROOT}/lib/fpc/3.3.1/ppcx64"

if [[ ! -x "$PPC" ]]; then
  echo "Fetching Free Pascal 3.3.1 (anonymous methods and Unicode helpers)"
  mkdir -p "$FPC_ROOT"
  curl -fsSL -A "parse-graph-leak-tests" \
    -o "$FPC_ROOT/fpc.tar.gz" \
    "https://downloads.freepascal.org/fpc/snapshot/trunk/x86_64-linux/fpc-3.3.1.x86_64-linux.tar.gz"
  tar -xzf "$FPC_ROOT/fpc.tar.gz" -C "$FPC_ROOT"
  "$FPC_ROOT/lib/fpc/3.3.1/samplecfg" "$FPC_ROOT/lib/fpc/3.3.1" "$FPC_ROOT" >/dev/null
fi

export PPC_CONFIG_PATH="$FPC_ROOT"
rm -rf "$BUILD"
mkdir -p "$BUILD/src"

python3 - "$ROOT" "$BUILD/src" << 'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
dest = pathlib.Path(sys.argv[2])
files = [
    "Pkg.Json.Mapper.pas",
    "Pkg.Json.StubField.pas",
    "Pkg.Json.Lists.pas",
    "Pkg.Json.JSONName.pas",
    "Pkg.Json.JsonValueHelper.pas",
    "Pkg.Json.ReservedWords.pas",
    "Pkg.JSON.SubTypes.pas",
    "Pkg.Json.Settings.pas",
    "Pkg.Json.DTO.pas",
]
replacements = [
    ("System.Generics.Collections", "Generics.Collections"),
    ("System.Generics.Defaults", "Generics.Defaults"),
    ("System.DateUtils", "DateUtils"),
    ("System.Character", "Character"),
    ("System.StrUtils", "StrUtils"),
    ("System.Strutils", "StrUtils"),
    ("System.SysUtils", "SysUtils"),
    ("System.Sysutils", "SysUtils"),
    ("System.Classes", "Classes"),
    ("System.Rtti", "Rtti"),
]
for name in files:
    text = (root / name).read_text(encoding="utf-8")
    original = text
    for old, new in replacements:
        text = text.replace(old, new)
    if name == "Pkg.Json.JSONName.pas":
        text = text.replace(
            "ExtractStrings(['_'], [], PChar(Value), List);",
            "ExtractStrings(['_'], [], PAnsiChar(AnsiString(Value)), List);",
        )
    if name == "Pkg.Json.JsonValueHelper.pas":
        text = text.replace(
            "uses SysUtils, DateUtils;",
            "uses SysUtils, DateUtils, JsonCompat;",
        )
    # Free Pascal's TObject.ToString is not virtual. This method is not on the parse path.
    # ObjectList's generic class constraint does not compile on this Free Pascal.
    # Nothing in the parse or pretty-print path calls it.
    if name == "Pkg.Json.DTO.pas":
        text = text.replace(
            "function ToString: string; override;",
            "function ToString: string;",
        )
        text = text.replace(
            "    function ObjectList<T: class>(var aList: TObjectList<T>; aSource: TArray<T>): TObjectList<T>;\n",
            "",
        )
        start = text.find("function TArrayMapper.ObjectList<T>")
        end = text.find("procedure TArrayMapper.RefreshArray<T>")
        if start < 0 or end < 0:
            raise SystemExit("could not trim ObjectList from DTO copy")
        text = text[:start] + text[end:]
    (dest / name).write_text(text, encoding="utf-8")
stub = dest / "Pkg.Json.StubField.pas"
alias = dest / "Pkg.JSON.StubField.pas"
if not alias.exists():
    alias.symlink_to(stub.name)
sub = dest / "Pkg.JSON.SubTypes.pas"
sub_alias = dest / "Pkg.Json.SubTypes.pas"
if not sub_alias.exists():
    sub_alias.symlink_to(sub.name)
PY

"$PPC" -Mdelphiunicode -gh \
  -Fu"$BUILD/src" \
  -Fu"$ROOT/tests/support" \
  -FE"$BUILD" \
  "$ROOT/tests/ParseGraphLeakTest.pas" \
  -o"$BUILD/ParseGraphLeakTest"

"$BUILD/ParseGraphLeakTest"
