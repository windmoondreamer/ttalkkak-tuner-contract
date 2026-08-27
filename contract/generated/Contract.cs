// settings-contract.json 에서 자동 생성됨 — 직접 고치지 마세요.
// 고치려면 contract/settings-contract.json 을 바꾸고 generate.py 를 돌리세요.

using System.Collections.Generic;

public readonly record struct ContractAction(string Label, string Macro);
public readonly record struct ButtonInfo(string Id, string Subtitle, string Group, string Slot);
public readonly record struct ProfileInfo(string Tag, string DefaultName, bool Builtin);
public readonly record struct SensRange(double Min, double Max, double Step, double Default);

public static class Contract
{
    public const int SchemaVersion = 2;
    public const int MaxProfiles = 9;
    public const int DefaultProfileCount = 4;

    public static readonly List<ContractAction> Actions = new()
    {
        new("사용 안 함", "NA"),
        new("마우스 왼쪽 클릭", "MB(MOUSE_BUTTON_LEFT)"),
        new("마우스 오른쪽 클릭", "MB(MOUSE_BUTTON_RIGHT)"),
        new("마우스 가운데 클릭", "MB(MOUSE_BUTTON_MIDDLE)"),
        new("마우스 왼쪽 연사", "MBR(MOUSE_BUTTON_LEFT)"),
        new("마우스 오른쪽 연사", "MBR(MOUSE_BUTTON_RIGHT)"),
        new("Shift (누르는 동안)", "MODONLY(KEYBOARD_MODIFIER_LEFTSHIFT)"),
        new("Ctrl (누르는 동안)", "MODONLY(KEYBOARD_MODIFIER_LEFTCTRL)"),
        new("Shift 토글 (다시 누르면 해제)", "MODT(KEYBOARD_MODIFIER_LEFTSHIFT)"),
        new("Ctrl 토글 (다시 누르면 해제)", "MODT(KEYBOARD_MODIFIER_LEFTCTRL)"),
        new("브라우저 뒤로", "KM(HID_KEY_ARROW_LEFT, NAV_MOD)"),
        new("브라우저 앞으로", "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)"),
        new("이전 탭", "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)"),
        new("다음 탭", "KM(HID_KEY_TAB, PRIMARY_MOD)"),
        new("탭 닫기", "KM(HID_KEY_W, PRIMARY_MOD)"),
        new("새 탭", "KM(HID_KEY_T, PRIMARY_MOD)"),
        new("주소창 검색", "KM(HID_KEY_L, PRIMARY_MOD)"),
        new("YouTube 검색 (/)", "K(HID_KEY_SLASH)"),
        new("키 A", "K(HID_KEY_A)"),
        new("키 B", "K(HID_KEY_B)"),
        new("키 C", "K(HID_KEY_C)"),
        new("키 D", "K(HID_KEY_D)"),
        new("키 E", "K(HID_KEY_E)"),
        new("키 F", "K(HID_KEY_F)"),
        new("키 G", "K(HID_KEY_G)"),
        new("키 H", "K(HID_KEY_H)"),
        new("키 I", "K(HID_KEY_I)"),
        new("키 J", "K(HID_KEY_J)"),
        new("키 K", "K(HID_KEY_K)"),
        new("키 L", "K(HID_KEY_L)"),
        new("키 M", "K(HID_KEY_M)"),
        new("키 N", "K(HID_KEY_N)"),
        new("키 O", "K(HID_KEY_O)"),
        new("키 P", "K(HID_KEY_P)"),
        new("키 Q", "K(HID_KEY_Q)"),
        new("키 R", "K(HID_KEY_R)"),
        new("키 S", "K(HID_KEY_S)"),
        new("키 T", "K(HID_KEY_T)"),
        new("키 U", "K(HID_KEY_U)"),
        new("키 V", "K(HID_KEY_V)"),
        new("키 W", "K(HID_KEY_W)"),
        new("키 X", "K(HID_KEY_X)"),
        new("키 Y", "K(HID_KEY_Y)"),
        new("키 Z", "K(HID_KEY_Z)"),
        new("키 0", "K(HID_KEY_0)"),
        new("키 1", "K(HID_KEY_1)"),
        new("키 2", "K(HID_KEY_2)"),
        new("키 3", "K(HID_KEY_3)"),
        new("키 4", "K(HID_KEY_4)"),
        new("키 5", "K(HID_KEY_5)"),
        new("키 6", "K(HID_KEY_6)"),
        new("키 7", "K(HID_KEY_7)"),
        new("키 8", "K(HID_KEY_8)"),
        new("키 9", "K(HID_KEY_9)"),
        new("Space", "K(HID_KEY_SPACE)"),
        new("Tab", "K(HID_KEY_TAB)"),
        new("Enter", "K(HID_KEY_ENTER)"),
        new("Esc", "K(HID_KEY_ESCAPE)"),
        new("← 왼쪽", "K(HID_KEY_ARROW_LEFT)"),
        new("→ 오른쪽", "K(HID_KEY_ARROW_RIGHT)"),
        new("↑ 위", "K(HID_KEY_ARROW_UP)"),
        new("↓ 아래", "K(HID_KEY_ARROW_DOWN)"),
        new("F1", "K(HID_KEY_F1)"),
        new("F2", "K(HID_KEY_F2)"),
        new("F3", "K(HID_KEY_F3)"),
        new("F4", "K(HID_KEY_F4)"),
        new("F5 (새로 고침)", "K(HID_KEY_F5)"),
        new("F6", "K(HID_KEY_F6)"),
        new("F7", "K(HID_KEY_F7)"),
        new("F8", "K(HID_KEY_F8)"),
    };

    public static readonly string[] EditableButtons = { "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "M1", "M2", "U1", "U2", "U3", "U4" };

    public static readonly string[] BitOrder = { "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "M1", "M2", "U1", "U2", "U3", "U4", "SP", "MD" };

    public static readonly List<ButtonInfo> Buttons = new()
    {
        new("F1", "검지 좌", "finger", "P00"),
        new("F2", "검지 중", "finger", "P01"),
        new("F3", "검지 우", "finger", "P02"),
        new("F4", "검지 방아쇠", "finger", "P03"),
        new("F5", "중지 좌", "finger", "P04"),
        new("F6", "중지 중", "finger", "P05"),
        new("F7", "중지 우", "finger", "P06"),
        new("F8", "중지 방아쇠", "finger", "P07"),
        new("M1", "크라운 1", "thumb", "P10"),
        new("M2", "크라운 2", "thumb", "P11"),
        new("U1", "베이스 Y", "finger", "P12"),
        new("U2", "베이스 X", "finger", "P13"),
        new("U3", "베이스 B", "finger", "P14"),
        new("U4", "베이스 A", "finger", "P15"),
        new("SP", "스틱 클릭", "thumb", "GP2"),
        new("MD", "MODE 링", "thumb", "P17"),
    };

    public static readonly List<ProfileInfo> Profiles = new()
    {
        new("FPS", "FPS", true),
        new("MOBA", "MOBA", true),
        new("DESK", "DESK", true),
        new("MEDIA", "MEDIA", true),
        new("P5", "사용자1", false),
        new("P6", "사용자2", false),
        new("P7", "사용자3", false),
        new("P8", "사용자4", false),
        new("P9", "사용자5", false),
    };

    public static readonly Dictionary<string, string> DefaultMappings = new()
    {
        ["FPS_F1"] = "K(HID_KEY_Q)",
        ["FPS_F2"] = "K(HID_KEY_E)",
        ["FPS_F3"] = "K(HID_KEY_C)",
        ["FPS_F4"] = "MBR(MOUSE_BUTTON_LEFT)",
        ["FPS_F5"] = "MODONLY(KEYBOARD_MODIFIER_LEFTSHIFT)",
        ["FPS_F6"] = "K(HID_KEY_SPACE)",
        ["FPS_F7"] = "MODONLY(KEYBOARD_MODIFIER_LEFTCTRL)",
        ["FPS_F8"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["FPS_M1"] = "K(HID_KEY_X)",
        ["FPS_M2"] = "K(HID_KEY_R)",
        ["FPS_U1"] = "K(HID_KEY_TAB)",
        ["FPS_U2"] = "K(HID_KEY_B)",
        ["FPS_U3"] = "K(HID_KEY_ESCAPE)",
        ["FPS_U4"] = "K(HID_KEY_ENTER)",
        ["MOBA_F1"] = "K(HID_KEY_Q)",
        ["MOBA_F2"] = "K(HID_KEY_W)",
        ["MOBA_F3"] = "K(HID_KEY_E)",
        ["MOBA_F4"] = "MBR(MOUSE_BUTTON_RIGHT)",
        ["MOBA_F5"] = "K(HID_KEY_R)",
        ["MOBA_F6"] = "K(HID_KEY_D)",
        ["MOBA_F7"] = "K(HID_KEY_F)",
        ["MOBA_F8"] = "MB(MOUSE_BUTTON_LEFT)",
        ["MOBA_M1"] = "MB(MOUSE_BUTTON_LEFT)",
        ["MOBA_M2"] = "K(HID_KEY_A)",
        ["MOBA_U1"] = "K(HID_KEY_TAB)",
        ["MOBA_U2"] = "K(HID_KEY_P)",
        ["MOBA_U3"] = "K(HID_KEY_B)",
        ["MOBA_U4"] = "K(HID_KEY_ESCAPE)",
        ["DESK_F1"] = "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        ["DESK_F2"] = "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        ["DESK_F3"] = "K(HID_KEY_F5)",
        ["DESK_F4"] = "MB(MOUSE_BUTTON_LEFT)",
        ["DESK_F5"] = "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        ["DESK_F6"] = "KM(HID_KEY_TAB, PRIMARY_MOD)",
        ["DESK_F7"] = "KM(HID_KEY_W, PRIMARY_MOD)",
        ["DESK_F8"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["DESK_M1"] = "MB(MOUSE_BUTTON_LEFT)",
        ["DESK_M2"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["DESK_U1"] = "K(HID_KEY_ESCAPE)",
        ["DESK_U2"] = "K(HID_KEY_ENTER)",
        ["DESK_U3"] = "K(HID_KEY_TAB)",
        ["DESK_U4"] = "KM(HID_KEY_T, PRIMARY_MOD)",
        ["MEDIA_F1"] = "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        ["MEDIA_F2"] = "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        ["MEDIA_F3"] = "KM(HID_KEY_L, PRIMARY_MOD)",
        ["MEDIA_F4"] = "MB(MOUSE_BUTTON_LEFT)",
        ["MEDIA_F5"] = "K(HID_KEY_SLASH)",
        ["MEDIA_F6"] = "K(HID_KEY_TAB)",
        ["MEDIA_F7"] = "K(HID_KEY_K)",
        ["MEDIA_F8"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["MEDIA_M1"] = "MB(MOUSE_BUTTON_LEFT)",
        ["MEDIA_M2"] = "K(HID_KEY_F)",
        ["MEDIA_U1"] = "K(HID_KEY_J)",
        ["MEDIA_U2"] = "K(HID_KEY_K)",
        ["MEDIA_U3"] = "K(HID_KEY_L)",
        ["MEDIA_U4"] = "K(HID_KEY_ESCAPE)",
        ["P5_F1"] = "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        ["P5_F2"] = "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        ["P5_F3"] = "K(HID_KEY_F5)",
        ["P5_F4"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P5_F5"] = "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        ["P5_F6"] = "KM(HID_KEY_TAB, PRIMARY_MOD)",
        ["P5_F7"] = "KM(HID_KEY_W, PRIMARY_MOD)",
        ["P5_F8"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P5_M1"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P5_M2"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P5_U1"] = "K(HID_KEY_ESCAPE)",
        ["P5_U2"] = "K(HID_KEY_ENTER)",
        ["P5_U3"] = "K(HID_KEY_TAB)",
        ["P5_U4"] = "KM(HID_KEY_T, PRIMARY_MOD)",
        ["P6_F1"] = "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        ["P6_F2"] = "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        ["P6_F3"] = "K(HID_KEY_F5)",
        ["P6_F4"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P6_F5"] = "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        ["P6_F6"] = "KM(HID_KEY_TAB, PRIMARY_MOD)",
        ["P6_F7"] = "KM(HID_KEY_W, PRIMARY_MOD)",
        ["P6_F8"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P6_M1"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P6_M2"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P6_U1"] = "K(HID_KEY_ESCAPE)",
        ["P6_U2"] = "K(HID_KEY_ENTER)",
        ["P6_U3"] = "K(HID_KEY_TAB)",
        ["P6_U4"] = "KM(HID_KEY_T, PRIMARY_MOD)",
        ["P7_F1"] = "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        ["P7_F2"] = "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        ["P7_F3"] = "K(HID_KEY_F5)",
        ["P7_F4"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P7_F5"] = "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        ["P7_F6"] = "KM(HID_KEY_TAB, PRIMARY_MOD)",
        ["P7_F7"] = "KM(HID_KEY_W, PRIMARY_MOD)",
        ["P7_F8"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P7_M1"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P7_M2"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P7_U1"] = "K(HID_KEY_ESCAPE)",
        ["P7_U2"] = "K(HID_KEY_ENTER)",
        ["P7_U3"] = "K(HID_KEY_TAB)",
        ["P7_U4"] = "KM(HID_KEY_T, PRIMARY_MOD)",
        ["P8_F1"] = "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        ["P8_F2"] = "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        ["P8_F3"] = "K(HID_KEY_F5)",
        ["P8_F4"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P8_F5"] = "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        ["P8_F6"] = "KM(HID_KEY_TAB, PRIMARY_MOD)",
        ["P8_F7"] = "KM(HID_KEY_W, PRIMARY_MOD)",
        ["P8_F8"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P8_M1"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P8_M2"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P8_U1"] = "K(HID_KEY_ESCAPE)",
        ["P8_U2"] = "K(HID_KEY_ENTER)",
        ["P8_U3"] = "K(HID_KEY_TAB)",
        ["P8_U4"] = "KM(HID_KEY_T, PRIMARY_MOD)",
        ["P9_F1"] = "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        ["P9_F2"] = "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        ["P9_F3"] = "K(HID_KEY_F5)",
        ["P9_F4"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P9_F5"] = "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        ["P9_F6"] = "KM(HID_KEY_TAB, PRIMARY_MOD)",
        ["P9_F7"] = "KM(HID_KEY_W, PRIMARY_MOD)",
        ["P9_F8"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P9_M1"] = "MB(MOUSE_BUTTON_LEFT)",
        ["P9_M2"] = "MB(MOUSE_BUTTON_RIGHT)",
        ["P9_U1"] = "K(HID_KEY_ESCAPE)",
        ["P9_U2"] = "K(HID_KEY_ENTER)",
        ["P9_U3"] = "K(HID_KEY_TAB)",
        ["P9_U4"] = "KM(HID_KEY_T, PRIMARY_MOD)",
    };

    public static readonly Dictionary<string, SensRange> Sensitivity = new()
    {
        ["gdz"] = new(0.0, 0.4, 0.01, 0.1),
        ["tdz"] = new(0.0, 0.4, 0.01, 0.14),
        ["gsat"] = new(0.55, 1.0, 0.01, 0.85),
        ["tsat"] = new(0.55, 1.0, 0.01, 0.9),
        ["fps"] = new(4, 45, 1, 22),
        ["moba"] = new(4, 45, 1, 16),
        ["desk"] = new(4, 45, 1, 14),
        ["gamma"] = new(1.0, 3.0, 0.1, 1.8),
        ["wasd"] = new(0.15, 0.75, 0.01, 0.38),
        ["debounce"] = new(2, 25, 1, 12),
    };

    /// 감도 헤더. 골든 fixture 와 byte-for-byte 같아야 한다.
    public static string SensitivityHeader(Dictionary<string, double> s)
    {
        var c = System.Globalization.CultureInfo.InvariantCulture;
        string F2(string k) => s[k].ToString("0.00", c) + "f";
        string F1(string k) => s[k].ToString("0.0", c) + "f";
        var sb = new System.Text.StringBuilder();
        sb.Append("// 딸깍 감도 조절기에서 생성됨 — 직접 편집하지 마세요.\n");
        sb.Append("// 이 파일을 firmware/ttalkkak/sensitivity_override.h 로 저장한 뒤 빌드하세요.\n");
        sb.Append("#pragma once\n");
        sb.Append("#define DEADZONE_GIMBAL " + F2("gdz") + "\n");
        sb.Append("#define DEADZONE_THUMB " + F2("tdz") + "\n");
        sb.Append("#define SATURATE_GIMBAL " + F2("gsat") + "\n");
        sb.Append("#define SATURATE_THUMB " + F2("tsat") + "\n");
        sb.Append("#define MOUSE_GAMMA " + F1("gamma") + "\n");
        sb.Append("#define MOUSE_SPEED_FPS " + F1("fps") + "\n");
        sb.Append("#define MOUSE_SPEED_MOBA " + F1("moba") + "\n");
        sb.Append("#define MOUSE_SPEED_DESK " + F1("desk") + "\n");
        sb.Append("#define WASD_THRESHOLD " + F2("wasd") + "\n");
        sb.Append("#define DEBOUNCE_MS " + ((int)System.Math.Round(s["debounce"])).ToString(c) + "\n");
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
            var name = (names.TryGetValue(p.Tag, out var n) ? n : p.DefaultName).Replace("\"", "");
            lines.Add("// --- " + p.Tag + " : " + name + " ---");
            lines.Add("#define TTK_NAME_" + p.Tag + " \"" + name + "\"");
            foreach (var b in EditableButtons)
            {
                var key = p.Tag + "_" + b;
                lines.Add("#define TTK_ACT_" + key + " " +
                          (mappings.TryGetValue(key, out var m) ? m : "NA"));
            }
            lines.Add("");
        }
        return string.Join("\n", lines);
    }
}
