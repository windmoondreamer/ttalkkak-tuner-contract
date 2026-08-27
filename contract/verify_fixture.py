#!/usr/bin/env python3
"""계약 ↔ 생성물 ↔ 골든 헤더 ↔ 실제 앱 출력이 전부 일치하는지 검사한다.

    python3 contract/verify_fixture.py

무엇을 보는가:
  1. 계약 자체의 정합성 (액션 매크로 중복, 감도 범위, 프로필/버튼 구성)
  2. generated/ 가 계약과 최신인지
  3. 골든 헤더가 계약의 기준 구현과 같은지
  4. macOS(Swift) 구현이 골든과 byte-for-byte 같은지  ← 실제 컴파일·실행
  5. 골든 헤더가 펌웨어에서 실제로 컴파일되는지        ← arduino-cli
"""
import io as _io, sys as _sys
# Windows 콘솔은 기본이 cp1252 라 한글 출력에서 죽는다. 직접 돌릴 때도 되게 여기서 고친다.
for _s in (_sys.stdout, _sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

import json, shutil, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).parent
# 이 저장소에서는 HERE.parent 가 루트다. 펌웨어 트리는 없을 수도 있고,
# 없으면 5번 단계를 건너뛴다 (실패가 아니다).
ROOT = HERE.parent
FW = ROOT / "firmware"
fails: list[str] = []
skips: list[str] = []


def check(name, ok, detail=""):
    print(f"  {'✅' if ok else '❌'} {name}" + (f"  — {detail}" if detail and not ok else ""))
    if not ok:
        fails.append(name)


def skip(name, why):
    print(f"  ⏭  {name}  — {why}")
    skips.append(f"{name}: {why}")


C = json.loads((HERE / "settings-contract.json").read_text(encoding="utf-8"))

print("1) 계약 정합성")
macros = [a["macro"] for a in C["actions"]]
check("액션 매크로 중복 없음", len(macros) == len(set(macros)),
      f"중복 {len(macros) - len(set(macros))}건")
check("액션 라벨 중복 없음", len({a["label"] for a in C["actions"]}) == len(macros))
check(f"프로필 {C['maxProfiles']}개", len(C["profiles"]) == C["maxProfiles"])
check("기본 프로필 개수가 범위 안", 1 <= C["defaultProfileCount"] <= C["maxProfiles"])
check("버튼 16개", len(C["buttons"]) == 16)
check("비트 0~15 빠짐없음", sorted(b["bit"] for b in C["buttons"]) == list(range(16)))
check("편집 가능 버튼 14개", len(C["editableButtons"]) == 14)
check("보호 버튼이 편집 목록에 없음",
      not (set(C["protectedButtons"]) & set(C["editableButtons"])))
ok = True
for p in C["profiles"]:
    if set(p["defaultMapping"]) != set(C["editableButtons"]):
        ok = False
    for m in p["defaultMapping"].values():
        if m not in set(macros):
            ok = False
check("모든 프로필 기본 배치가 계약 액션만 사용", ok)
for k, spec in C["sensitivity"].items():
    if not spec["min"] <= spec["default"] <= spec["max"]:
        fails.append(f"감도 기본값 범위 밖: {k}")
check("감도 기본값이 전부 범위 안", not any(f.startswith("감도 기본값") for f in fails))

print("2) 생성물 최신 여부")
r = subprocess.run([sys.executable, str(HERE / "generate.py"), "--check"],
                   capture_output=True, text=True)
check("generated/ 와 골든이 계약과 최신", r.returncode == 0, r.stdout.strip())

print("3) macOS(Swift) 구현 ↔ 골든 헤더")
swiftc = shutil.which("swiftc")
if not swiftc:
    skip("Swift 출력 비교", "swiftc 없음")
else:
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td / "main.swift").write_text('''import Foundation
@main struct G {
  static func main() {
    let sens = Dictionary(uniqueKeysWithValues: Contract.sensitivity.map { ($0.key, $0.value.def) })
    let names = Dictionary(uniqueKeysWithValues: Contract.profiles.map { ($0.tag, $0.defaultName) })
    let d = CommandLine.arguments[1]
    try! Contract.sensitivityHeader(sens).write(toFile: d + "/sensitivity_override.h", atomically: true, encoding: .utf8)
    try! Contract.mappingHeader(profileCount: Contract.defaultProfileCount, names: names,
                                mappings: Contract.defaultMappings).write(
        toFile: d + "/mapping_override.h", atomically: true, encoding: .utf8)
  }
}''', encoding="utf-8")
        build = subprocess.run([swiftc, "-parse-as-library", "-O",
                                str(HERE / "generated/Contract.swift"), str(td / "main.swift"),
                                "-o", str(td / "g")], capture_output=True, text=True)
        if build.returncode != 0:
            check("Contract.swift 컴파일", False, build.stderr.strip()[:200])
        else:
            subprocess.run([str(td / "g"), str(td)], check=True)
            for f in C["headerFiles"]:
                same = (td / f).read_text(encoding="utf-8") == \
                       (HERE / "fixtures/golden" / f).read_text(encoding="utf-8")
                check(f"Swift {f} 가 골든과 동일", same)

print("4) Windows(C#) 구현 ↔ 골든 헤더")
if shutil.which("dotnet"):
    CS_MAIN = "\n".join([
        "class G {",
        "  static void Main(string[] a) {",
        "    var sens = new Dictionary<string, double>();",
        "    foreach (var kv in Contract.Sensitivity) sens[kv.Key] = kv.Value.Default;",
        "    var names = Contract.Profiles.ToDictionary(p => p.Tag, p => p.DefaultName);",
        "    File.WriteAllText(Path.Combine(a[0], \"sensitivity_override.h\"),",
        "        Contract.SensitivityHeader(sens), new System.Text.UTF8Encoding(false));",
        "    File.WriteAllText(Path.Combine(a[0], \"mapping_override.h\"),",
        "        Contract.MappingHeader(Contract.DefaultProfileCount, names, Contract.DefaultMappings),",
        "        new System.Text.UTF8Encoding(false));",
        "  }",
        "}",
    ])
    CS_PROJ = ('<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
               '<OutputType>Exe</OutputType><TargetFramework>net8.0</TargetFramework>'
               '<ImplicitUsings>enable</ImplicitUsings><Nullable>enable</Nullable>'
               '</PropertyGroup><ItemGroup><Compile Include="{src}" /></ItemGroup></Project>')
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td / "p.csproj").write_text(
            CS_PROJ.format(src=HERE / "generated/Contract.cs"), encoding="utf-8")
        (td / "Main.cs").write_text(CS_MAIN, encoding="utf-8")
        r = subprocess.run(["dotnet", "run", "--project", str(td / "p.csproj"), "--", str(td)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            check("Contract.cs 컴파일·실행", False, (r.stderr or r.stdout).strip()[:200])
        else:
            for f in C["headerFiles"]:
                same = ((td / f).read_text(encoding="utf-8")
                        == (HERE / "fixtures/golden" / f).read_text(encoding="utf-8"))
                check(f"C# {f} 가 골든과 동일", same)
else:
    skip("C# 출력 비교",
         "dotnet 없음 — Windows 머신에서 build_windows.ps1 전에 이 스크립트를 돌릴 것")

print("5) 골든 헤더가 펌웨어에서 컴파일되는지")
if not (FW / "build.sh").exists():
    # 계약만 떼어 낸 저장소에는 펌웨어가 없다. 그건 실패가 아니다.
    skip("펌웨어 컴파일", "펌웨어 트리 없음 (계약 단독 저장소)")
elif not shutil.which("arduino-cli"):
    skip("펌웨어 컴파일", "arduino-cli 없음")
else:
    dest = FW / "ttalkkak"
    backup = {}
    try:
        for f in C["headerFiles"]:
            tgt = dest / f
            if tgt.exists():
                backup[f] = tgt.read_text(encoding="utf-8")   # 사용자 파일을 덮지 않는다
            shutil.copy(HERE / "fixtures/golden" / f, tgt)
        r = subprocess.run(["./build.sh", "diagpcf"], cwd=FW, capture_output=True, text=True)
        check("골든 헤더로 diagpcf 빌드", r.returncode == 0,
              (r.stdout + r.stderr).strip().splitlines()[-1] if r.returncode else "")
    finally:
        for f in C["headerFiles"]:
            tgt = dest / f
            if f in backup:
                tgt.write_text(backup[f], encoding="utf-8")
            elif tgt.exists():
                tgt.unlink()

print()
if skips:
    print("건너뜀:")
    for s in skips:
        print(f"  · {s}")
if fails:
    print(f"\n실패 {len(fails)}건: " + ", ".join(fails))
    sys.exit(1)
print("계약 검증 통과" + (f" (건너뜀 {len(skips)}건)" if skips else ""))
