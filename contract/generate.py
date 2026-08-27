#!/usr/bin/env python3
"""settings-contract.json 하나에서 macOS·Windows 소스와 골든 헤더를 만든다.

앱 소스에 액션 목록·프로필·기본 배치를 손으로 적어 두면 반드시 어긋난다.
실제로 2026-08-28 시점에 macOS 70개 · Windows 8개 · 계약 16개로 셋 다 달랐다.
그래서 그 세 곳을 전부 이 스크립트의 출력으로 바꾼다.

    python3 generate.py          # 생성
    python3 generate.py --check  # 생성물이 최신인지만 확인 (CI/검증용)
"""
import io as _io, sys as _sys
# Windows 콘솔은 기본이 cp1252 라 한글 출력에서 죽는다. 직접 돌릴 때도 되게 여기서 고친다.
for _s in (_sys.stdout, _sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

import json, sys
from pathlib import Path

HERE = Path(__file__).parent
C = json.loads((HERE / "settings-contract.json").read_text(encoding="utf-8"))
BANNER = "// settings-contract.json 에서 자동 생성됨 — 직접 고치지 마세요.\n// 고치려면 contract/settings-contract.json 을 바꾸고 generate.py 를 돌리세요.\n"


def swift_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def gen_swift() -> str:
    out = [BANNER, "import Foundation\n"]
    out.append("struct ContractAction: Identifiable, Hashable {")
    out.append("    let label: String")
    out.append("    let macro: String")
    out.append("    var id: String { macro }")
    out.append("}\n")
    out.append("enum Contract {")
    out.append(f"    static let schemaVersion = {C['schemaVersion']}")
    out.append(f"    static let maxProfiles = {C['maxProfiles']}")
    out.append(f"    static let defaultProfileCount = {C['defaultProfileCount']}\n")

    out.append("    static let actions: [ContractAction] = [")
    for a in C["actions"]:
        out.append(f"        .init(label: {swift_str(a['label'])}, macro: {swift_str(a['macro'])}),")
    out.append("    ]\n")

    out.append("    static let editableButtons = [" +
               ", ".join(swift_str(b) for b in C["editableButtons"]) + "]\n")
    out.append("    /// btnev 마스크의 비트 순서 (pins.h BTN_* 열거와 동일)")
    out.append("    static let bitOrder = [" +
               ", ".join(swift_str(b["id"]) for b in sorted(C["buttons"], key=lambda x: x["bit"])) + "]\n")

    out.append("    struct ButtonInfo { let id: String; let subtitle: String; let group: String; let slot: String }")
    out.append("    static let buttons: [ButtonInfo] = [")
    for b in C["buttons"]:
        out.append(f"        .init(id: {swift_str(b['id'])}, subtitle: {swift_str(b['subtitle'])}, "
                   f"group: {swift_str(b['group'])}, slot: {swift_str(b['slot'])}),")
    out.append("    ]\n")

    out.append("    struct ProfileInfo { let tag: String; let defaultName: String; let builtin: Bool }")
    out.append("    static let profiles: [ProfileInfo] = [")
    for p in C["profiles"]:
        out.append(f"        .init(tag: {swift_str(p['tag'])}, defaultName: {swift_str(p['defaultName'])}, "
                   f"builtin: {'true' if p['builtin'] else 'false'}),")
    out.append("    ]\n")

    out.append("    static let defaultMappings: [String: String] = [")
    for p in C["profiles"]:
        for btn in C["editableButtons"]:
            out.append(f"        {swift_str(p['tag'] + '_' + btn)}: {swift_str(p['defaultMapping'][btn])},")
    out.append("    ]\n")

    out.append("    struct Range { let min: Double; let max: Double; let step: Double; let def: Double }")
    out.append("    static let sensitivity: [String: Range] = [")
    for k, v in C["sensitivity"].items():
        out.append(f"        {swift_str(k)}: .init(min: {v['min']}, max: {v['max']}, "
                   f"step: {v['step']}, def: {v['default']}),")
    out.append("    ]\n")

    # 프리셋 파일 규격 — 키 순서·자릿수를 계약이 못박는다.
    P = C["preset"]
    out.append(f"    static let fileSchemaVersion = {P['fileSchemaVersion']}")
    out.append("    static let sensOrder = [" +
               ", ".join(swift_str(k) for k in P["precision"]) + "]")
    out.append("    static let presetPrecision: [String: Int] = [")
    for k, v in P["precision"].items():
        out.append(f"        {swift_str(k)}: {v},")
    out.append("    ]")
    out.append((HERE / "templates/preset.swift.in").read_text(encoding="utf-8"))

    # 헤더 생성기도 계약에서 만든다. 앱마다 손으로 쓰면 반드시 어긋난다.
    out.append('''    /// 감도 헤더. 골든 fixture 와 byte-for-byte 같아야 한다.
    static func sensitivityHeader(_ s: [String: Double]) -> String {
        func f2(_ k: String) -> String { String(format: "%.2ff", s[k] ?? 0) }
        func f1(_ k: String) -> String { String(format: "%.1ff", s[k] ?? 0) }
        return \"\"\"
        // 딸깍 감도 조절기에서 생성됨 — 직접 편집하지 마세요.
        // 이 파일을 firmware/ttalkkak/sensitivity_override.h 로 저장한 뒤 빌드하세요.
        #pragma once
        #define DEADZONE_GIMBAL \\(f2("gdz"))
        #define DEADZONE_THUMB \\(f2("tdz"))
        #define SATURATE_GIMBAL \\(f2("gsat"))
        #define SATURATE_THUMB \\(f2("tsat"))
        #define MOUSE_GAMMA \\(f1("gamma"))
        #define MOUSE_SPEED_FPS \\(f1("fps"))
        #define MOUSE_SPEED_MOBA \\(f1("moba"))
        #define MOUSE_SPEED_DESK \\(f1("desk"))
        #define WASD_THRESHOLD \\(f2("wasd"))
        #define DEBOUNCE_MS \\(Int((s["debounce"] ?? 12).rounded()))

        \"\"\"
    }

    /// 키 배치 헤더. 9슬롯 전부를 쓰고 순환 개수만 TTK_PROFILE_COUNT 로 넘긴다.
    static func mappingHeader(profileCount: Int,
                              names: [String: String],
                              mappings: [String: String]) -> String {
        var lines = [
            "// 딸깍 감도 조절기에서 생성됨 — 키 배치. 직접 편집하지 마세요.",
            "// 이 파일을 firmware/ttalkkak/mapping_override.h 로 저장한 뒤 빌드하세요.",
            "#pragma once", "",
            "// MODE 링으로 순환할 페이지 개수 (1~9)",
            "#define TTK_PROFILE_COUNT \\(profileCount)", ""
        ]
        for p in profiles {
            let name = (names[p.tag] ?? p.defaultName).replacingOccurrences(of: "\\"", with: "")
            lines.append("// --- \\(p.tag) : \\(name) ---")
            lines.append("#define TTK_NAME_\\(p.tag) \\"\\(name)\\"")
            for b in editableButtons {
                lines.append("#define TTK_ACT_\\(p.tag)_\\(b) \\(mappings["\\(p.tag)_\\(b)"] ?? "NA")")
            }
            lines.append("")
        }
        return lines.joined(separator: "\\n")
    }''')
    out.append("}")
    return "\n".join(out) + "\n"


def cs_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def gen_cs() -> str:
    out = [BANNER, "using System.Collections.Generic;\n"]
    out.append("public readonly record struct ContractAction(string Label, string Macro);")
    out.append("public readonly record struct ButtonInfo(string Id, string Subtitle, string Group, string Slot);")
    out.append("public readonly record struct ProfileInfo(string Tag, string DefaultName, bool Builtin);")
    out.append("public readonly record struct SensRange(double Min, double Max, double Step, double Default);\n")
    out.append("public static class Contract")
    out.append("{")
    out.append(f"    public const int SchemaVersion = {C['schemaVersion']};")
    out.append(f"    public const int MaxProfiles = {C['maxProfiles']};")
    out.append(f"    public const int DefaultProfileCount = {C['defaultProfileCount']};\n")

    out.append("    public static readonly List<ContractAction> Actions = new()")
    out.append("    {")
    for a in C["actions"]:
        out.append(f"        new({cs_str(a['label'])}, {cs_str(a['macro'])}),")
    out.append("    };\n")

    out.append("    public static readonly string[] EditableButtons = { " +
               ", ".join(cs_str(b) for b in C["editableButtons"]) + " };\n")
    out.append("    public static readonly string[] BitOrder = { " +
               ", ".join(cs_str(b["id"]) for b in sorted(C["buttons"], key=lambda x: x["bit"])) + " };\n")

    out.append("    public static readonly List<ButtonInfo> Buttons = new()")
    out.append("    {")
    for b in C["buttons"]:
        out.append(f"        new({cs_str(b['id'])}, {cs_str(b['subtitle'])}, "
                   f"{cs_str(b['group'])}, {cs_str(b['slot'])}),")
    out.append("    };\n")

    out.append("    public static readonly List<ProfileInfo> Profiles = new()")
    out.append("    {")
    for p in C["profiles"]:
        out.append(f"        new({cs_str(p['tag'])}, {cs_str(p['defaultName'])}, "
                   f"{'true' if p['builtin'] else 'false'}),")
    out.append("    };\n")

    out.append("    public static readonly Dictionary<string, string> DefaultMappings = new()")
    out.append("    {")
    for p in C["profiles"]:
        for btn in C["editableButtons"]:
            out.append(f"        [{cs_str(p['tag'] + '_' + btn)}] = {cs_str(p['defaultMapping'][btn])},")
    out.append("    };\n")

    out.append("    public static readonly Dictionary<string, SensRange> Sensitivity = new()")
    out.append("    {")
    for k, v in C["sensitivity"].items():
        out.append(f"        [{cs_str(k)}] = new({v['min']}, {v['max']}, {v['step']}, {v['default']}),")
    out.append("    };\n")

    # 프리셋 파일 규격 — Swift 와 같은 키 순서·자릿수를 쓴다.
    P = C["preset"]
    out.append(f"    public const int FileSchemaVersion = {P['fileSchemaVersion']};")
    out.append("    public static readonly string[] SensOrder = { " +
               ", ".join(cs_str(k) for k in P["precision"]) + " };")
    out.append("    public static readonly Dictionary<string, int> PresetPrecision = new()")
    out.append("    {")
    for k, v in P["precision"].items():
        out.append(f"        [{cs_str(k)}] = {v},")
    out.append("    };")
    out.append((HERE / "templates/preset.cs.in").read_text(encoding="utf-8"))

    # 헤더 생성기 — Swift 쪽과 반드시 같은 문자열을 내야 한다.
    # 문화권에 따라 소수점이 ',' 가 되면 헤더가 깨지므로 InvariantCulture 를 강제한다.
    out.append('''    /// 감도 헤더. 골든 fixture 와 byte-for-byte 같아야 한다.
    public static string SensitivityHeader(Dictionary<string, double> s)
    {
        var c = System.Globalization.CultureInfo.InvariantCulture;
        string F2(string k) => s[k].ToString("0.00", c) + "f";
        string F1(string k) => s[k].ToString("0.0", c) + "f";
        var sb = new System.Text.StringBuilder();
        sb.Append("// 딸깍 감도 조절기에서 생성됨 — 직접 편집하지 마세요.\\n");
        sb.Append("// 이 파일을 firmware/ttalkkak/sensitivity_override.h 로 저장한 뒤 빌드하세요.\\n");
        sb.Append("#pragma once\\n");
        sb.Append("#define DEADZONE_GIMBAL " + F2("gdz") + "\\n");
        sb.Append("#define DEADZONE_THUMB " + F2("tdz") + "\\n");
        sb.Append("#define SATURATE_GIMBAL " + F2("gsat") + "\\n");
        sb.Append("#define SATURATE_THUMB " + F2("tsat") + "\\n");
        sb.Append("#define MOUSE_GAMMA " + F1("gamma") + "\\n");
        sb.Append("#define MOUSE_SPEED_FPS " + F1("fps") + "\\n");
        sb.Append("#define MOUSE_SPEED_MOBA " + F1("moba") + "\\n");
        sb.Append("#define MOUSE_SPEED_DESK " + F1("desk") + "\\n");
        sb.Append("#define WASD_THRESHOLD " + F2("wasd") + "\\n");
        sb.Append("#define DEBOUNCE_MS " + ((int)System.Math.Round(s["debounce"])).ToString(c) + "\\n");
        return sb.ToString();
    }

    /// 키 배치 헤더. 9슬롯 전부를 쓰고 순환 개수만 TTK_PROFILE_COUNT 로 넘긴다.
    public static string MappingHeader(int profileCount,
                                       Dictionary<string, string> names,
                                       Dictionary<string, string> mappings)
    {
        var c = System.Globalization.CultureInfo.InvariantCulture;
        var lines = new List<string>
        {
            "// 딸깍 감도 조절기에서 생성됨 — 키 배치. 직접 편집하지 마세요.",
            "// 이 파일을 firmware/ttalkkak/mapping_override.h 로 저장한 뒤 빌드하세요.",
            "#pragma once", "",
            "// MODE 링으로 순환할 페이지 개수 (1~9)",
            "#define TTK_PROFILE_COUNT " + profileCount.ToString(c), ""
        };
        foreach (var p in Profiles)
        {
            var name = (names.TryGetValue(p.Tag, out var n) ? n : p.DefaultName).Replace("\\"", "");
            lines.Add("// --- " + p.Tag + " : " + name + " ---");
            lines.Add("#define TTK_NAME_" + p.Tag + " \\"" + name + "\\"");
            foreach (var b in EditableButtons)
            {
                var key = p.Tag + "_" + b;
                lines.Add("#define TTK_ACT_" + key + " " +
                          (mappings.TryGetValue(key, out var m) ? m : "NA"));
            }
            lines.Add("");
        }
        return string.Join("\\n", lines);
    }''')
    out.append("}")
    return "\n".join(out) + "\n"


# ---- 헤더 생성기: 두 앱이 반드시 이 함수와 같은 결과를 내야 한다 ----

def sensitivity_header(s: dict) -> str:
    return (
        "// 딸깍 감도 조절기에서 생성됨 — 직접 편집하지 마세요.\n"
        "// 이 파일을 firmware/ttalkkak/sensitivity_override.h 로 저장한 뒤 빌드하세요.\n"
        "#pragma once\n"
        f"#define DEADZONE_GIMBAL {s['gdz']:.2f}f\n"
        f"#define DEADZONE_THUMB {s['tdz']:.2f}f\n"
        f"#define SATURATE_GIMBAL {s['gsat']:.2f}f\n"
        f"#define SATURATE_THUMB {s['tsat']:.2f}f\n"
        f"#define MOUSE_GAMMA {s['gamma']:.1f}f\n"
        f"#define MOUSE_SPEED_FPS {s['fps']:.1f}f\n"
        f"#define MOUSE_SPEED_MOBA {s['moba']:.1f}f\n"
        f"#define MOUSE_SPEED_DESK {s['desk']:.1f}f\n"
        f"#define WASD_THRESHOLD {s['wasd']:.2f}f\n"
        f"#define DEBOUNCE_MS {int(round(s['debounce']))}\n"
    )


def mapping_header(profile_count: int, names: dict, mappings: dict) -> str:
    out = ["// 딸깍 감도 조절기에서 생성됨 — 키 배치. 직접 편집하지 마세요.",
           "// 이 파일을 firmware/ttalkkak/mapping_override.h 로 저장한 뒤 빌드하세요.",
           "#pragma once", "",
           "// MODE 링으로 순환할 페이지 개수 (1~9)",
           f"#define TTK_PROFILE_COUNT {profile_count}", ""]
    for p in C["profiles"]:
        tag = p["tag"]
        name = names.get(tag, p["defaultName"]).replace('"', "")
        out.append(f"// --- {tag} : {name} ---")
        out.append(f'#define TTK_NAME_{tag} "{name}"')
        for btn in C["editableButtons"]:
            out.append(f"#define TTK_ACT_{tag}_{btn} {mappings[f'{tag}_{btn}']}")
        out.append("")
    return "\n".join(out)


def encode_preset(name: str, count: int, sens: dict, names: dict, maps: dict) -> str:
    """계약이 정한 키 순서·자릿수로 프리셋 JSON 을 쓴다.
    표준 인코더는 키 순서를 보장하지 않아서 직접 쓴다 — 두 OS 의 출력이 byte 단위로 같아야 한다."""
    P = C["preset"]

    def num(k, v):
        p = P["precision"][k]
        return str(int(round(v))) if p == 0 else f"{v:.{p}f}"

    def js(x):
        return json.dumps(x, ensure_ascii=False)

    l = ["{", f'  "schemaVersion": {C["schemaVersion"]},',
         f'  "presetName": {js(name)},', f'  "profileCount": {count},', '  "sensitivity": {']
    keys = list(P["precision"])
    for i, k in enumerate(keys):
        l.append(f'    {js(k)}: {num(k, sens[k])}' + ("" if i == len(keys) - 1 else ","))
    l += ["  },", '  "profileNames": {']
    for i, prof in enumerate(C["profiles"]):
        nm = names.get(prof["tag"], prof["defaultName"])
        l.append(f'    {js(prof["tag"])}: {js(nm)}' + ("" if i == len(C["profiles"]) - 1 else ","))
    l += ["  },", '  "mappings": {']
    for i, prof in enumerate(C["profiles"]):
        l.append(f'    {js(prof["tag"])}: {{')
        for j, b in enumerate(C["editableButtons"]):
            m = maps[f'{prof["tag"]}_{b}']
            l.append(f'      {js(b)}: {js(m)}' + ("" if j == len(C["editableButtons"]) - 1 else ","))
        l.append("    }" + ("" if i == len(C["profiles"]) - 1 else ","))
    l += ["  }", "}"]
    return "\n".join(l) + "\n"


def gen_golden() -> dict:
    sens = {k: v["default"] for k, v in C["sensitivity"].items()}
    names = {p["tag"]: p["defaultName"] for p in C["profiles"]}
    maps = {f"{p['tag']}_{b}": p["defaultMapping"][b]
            for p in C["profiles"] for b in C["editableButtons"]}
    return {
        "sensitivity_override.h": sensitivity_header(sens),
        "mapping_override.h": mapping_header(C["defaultProfileCount"], names, maps),
        "preset.json": encode_preset("기본 설정", C["defaultProfileCount"], sens, names, maps),
    }


TARGETS = {}
TARGETS[HERE / "generated/Contract.swift"] = gen_swift()
TARGETS[HERE / "generated/Contract.cs"] = gen_cs()
for name, text in gen_golden().items():
    TARGETS[HERE / "fixtures/golden" / name] = text

if __name__ == "__main__":
    check = "--check" in sys.argv
    stale = []
    for path, text in TARGETS.items():
        current = path.read_text(encoding="utf-8") if path.exists() else None
        if current == text:
            continue
        if check:
            stale.append(path.name)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
            print(f"  생성 {path.relative_to(HERE)}")
    if check:
        if stale:
            print("생성물이 계약과 어긋난다: " + ", ".join(stale))
            print("  python3 contract/generate.py 를 돌릴 것")
            sys.exit(1)
        print("생성물 최신 상태 OK")
    else:
        print("생성 완료")
