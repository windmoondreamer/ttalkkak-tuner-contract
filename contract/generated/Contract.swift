// settings-contract.json 에서 자동 생성됨 — 직접 고치지 마세요.
// 고치려면 contract/settings-contract.json 을 바꾸고 generate.py 를 돌리세요.

import Foundation

struct ContractAction: Identifiable, Hashable {
    let label: String
    let macro: String
    var id: String { macro }
}

enum Contract {
    static let schemaVersion = 2
    static let maxProfiles = 9
    static let defaultProfileCount = 4

    static let actions: [ContractAction] = [
        .init(label: "사용 안 함", macro: "NA"),
        .init(label: "마우스 왼쪽 클릭", macro: "MB(MOUSE_BUTTON_LEFT)"),
        .init(label: "마우스 오른쪽 클릭", macro: "MB(MOUSE_BUTTON_RIGHT)"),
        .init(label: "마우스 가운데 클릭", macro: "MB(MOUSE_BUTTON_MIDDLE)"),
        .init(label: "마우스 왼쪽 연사", macro: "MBR(MOUSE_BUTTON_LEFT)"),
        .init(label: "마우스 오른쪽 연사", macro: "MBR(MOUSE_BUTTON_RIGHT)"),
        .init(label: "Shift (누르는 동안)", macro: "MODONLY(KEYBOARD_MODIFIER_LEFTSHIFT)"),
        .init(label: "Ctrl (누르는 동안)", macro: "MODONLY(KEYBOARD_MODIFIER_LEFTCTRL)"),
        .init(label: "Shift 토글 (다시 누르면 해제)", macro: "MODT(KEYBOARD_MODIFIER_LEFTSHIFT)"),
        .init(label: "Ctrl 토글 (다시 누르면 해제)", macro: "MODT(KEYBOARD_MODIFIER_LEFTCTRL)"),
        .init(label: "브라우저 뒤로", macro: "KM(HID_KEY_ARROW_LEFT, NAV_MOD)"),
        .init(label: "브라우저 앞으로", macro: "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)"),
        .init(label: "이전 탭", macro: "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)"),
        .init(label: "다음 탭", macro: "KM(HID_KEY_TAB, PRIMARY_MOD)"),
        .init(label: "탭 닫기", macro: "KM(HID_KEY_W, PRIMARY_MOD)"),
        .init(label: "새 탭", macro: "KM(HID_KEY_T, PRIMARY_MOD)"),
        .init(label: "주소창 검색", macro: "KM(HID_KEY_L, PRIMARY_MOD)"),
        .init(label: "YouTube 검색 (/)", macro: "K(HID_KEY_SLASH)"),
        .init(label: "키 A", macro: "K(HID_KEY_A)"),
        .init(label: "키 B", macro: "K(HID_KEY_B)"),
        .init(label: "키 C", macro: "K(HID_KEY_C)"),
        .init(label: "키 D", macro: "K(HID_KEY_D)"),
        .init(label: "키 E", macro: "K(HID_KEY_E)"),
        .init(label: "키 F", macro: "K(HID_KEY_F)"),
        .init(label: "키 G", macro: "K(HID_KEY_G)"),
        .init(label: "키 H", macro: "K(HID_KEY_H)"),
        .init(label: "키 I", macro: "K(HID_KEY_I)"),
        .init(label: "키 J", macro: "K(HID_KEY_J)"),
        .init(label: "키 K", macro: "K(HID_KEY_K)"),
        .init(label: "키 L", macro: "K(HID_KEY_L)"),
        .init(label: "키 M", macro: "K(HID_KEY_M)"),
        .init(label: "키 N", macro: "K(HID_KEY_N)"),
        .init(label: "키 O", macro: "K(HID_KEY_O)"),
        .init(label: "키 P", macro: "K(HID_KEY_P)"),
        .init(label: "키 Q", macro: "K(HID_KEY_Q)"),
        .init(label: "키 R", macro: "K(HID_KEY_R)"),
        .init(label: "키 S", macro: "K(HID_KEY_S)"),
        .init(label: "키 T", macro: "K(HID_KEY_T)"),
        .init(label: "키 U", macro: "K(HID_KEY_U)"),
        .init(label: "키 V", macro: "K(HID_KEY_V)"),
        .init(label: "키 W", macro: "K(HID_KEY_W)"),
        .init(label: "키 X", macro: "K(HID_KEY_X)"),
        .init(label: "키 Y", macro: "K(HID_KEY_Y)"),
        .init(label: "키 Z", macro: "K(HID_KEY_Z)"),
        .init(label: "키 0", macro: "K(HID_KEY_0)"),
        .init(label: "키 1", macro: "K(HID_KEY_1)"),
        .init(label: "키 2", macro: "K(HID_KEY_2)"),
        .init(label: "키 3", macro: "K(HID_KEY_3)"),
        .init(label: "키 4", macro: "K(HID_KEY_4)"),
        .init(label: "키 5", macro: "K(HID_KEY_5)"),
        .init(label: "키 6", macro: "K(HID_KEY_6)"),
        .init(label: "키 7", macro: "K(HID_KEY_7)"),
        .init(label: "키 8", macro: "K(HID_KEY_8)"),
        .init(label: "키 9", macro: "K(HID_KEY_9)"),
        .init(label: "Space", macro: "K(HID_KEY_SPACE)"),
        .init(label: "Tab", macro: "K(HID_KEY_TAB)"),
        .init(label: "Enter", macro: "K(HID_KEY_ENTER)"),
        .init(label: "Esc", macro: "K(HID_KEY_ESCAPE)"),
        .init(label: "← 왼쪽", macro: "K(HID_KEY_ARROW_LEFT)"),
        .init(label: "→ 오른쪽", macro: "K(HID_KEY_ARROW_RIGHT)"),
        .init(label: "↑ 위", macro: "K(HID_KEY_ARROW_UP)"),
        .init(label: "↓ 아래", macro: "K(HID_KEY_ARROW_DOWN)"),
        .init(label: "F1", macro: "K(HID_KEY_F1)"),
        .init(label: "F2", macro: "K(HID_KEY_F2)"),
        .init(label: "F3", macro: "K(HID_KEY_F3)"),
        .init(label: "F4", macro: "K(HID_KEY_F4)"),
        .init(label: "F5 (새로 고침)", macro: "K(HID_KEY_F5)"),
        .init(label: "F6", macro: "K(HID_KEY_F6)"),
        .init(label: "F7", macro: "K(HID_KEY_F7)"),
        .init(label: "F8", macro: "K(HID_KEY_F8)"),
    ]

    static let editableButtons = ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "M1", "M2", "U1", "U2", "U3", "U4"]

    /// btnev 마스크의 비트 순서 (pins.h BTN_* 열거와 동일)
    static let bitOrder = ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "M1", "M2", "U1", "U2", "U3", "U4", "SP", "MD"]

    struct ButtonInfo { let id: String; let subtitle: String; let group: String; let slot: String }
    static let buttons: [ButtonInfo] = [
        .init(id: "F1", subtitle: "검지 좌", group: "finger", slot: "P00"),
        .init(id: "F2", subtitle: "검지 중", group: "finger", slot: "P01"),
        .init(id: "F3", subtitle: "검지 우", group: "finger", slot: "P02"),
        .init(id: "F4", subtitle: "검지 방아쇠", group: "finger", slot: "P03"),
        .init(id: "F5", subtitle: "중지 좌", group: "finger", slot: "P04"),
        .init(id: "F6", subtitle: "중지 중", group: "finger", slot: "P05"),
        .init(id: "F7", subtitle: "중지 우", group: "finger", slot: "P06"),
        .init(id: "F8", subtitle: "중지 방아쇠", group: "finger", slot: "P07"),
        .init(id: "M1", subtitle: "크라운 1", group: "thumb", slot: "P10"),
        .init(id: "M2", subtitle: "크라운 2", group: "thumb", slot: "P11"),
        .init(id: "U1", subtitle: "베이스 Y", group: "finger", slot: "P12"),
        .init(id: "U2", subtitle: "베이스 X", group: "finger", slot: "P13"),
        .init(id: "U3", subtitle: "베이스 B", group: "finger", slot: "P14"),
        .init(id: "U4", subtitle: "베이스 A", group: "finger", slot: "P15"),
        .init(id: "SP", subtitle: "스틱 클릭", group: "thumb", slot: "GP2"),
        .init(id: "MD", subtitle: "MODE 링", group: "thumb", slot: "P17"),
    ]

    struct ProfileInfo { let tag: String; let defaultName: String; let builtin: Bool }
    static let profiles: [ProfileInfo] = [
        .init(tag: "FPS", defaultName: "FPS", builtin: true),
        .init(tag: "MOBA", defaultName: "MOBA", builtin: true),
        .init(tag: "DESK", defaultName: "DESK", builtin: true),
        .init(tag: "MEDIA", defaultName: "MEDIA", builtin: true),
        .init(tag: "P5", defaultName: "사용자1", builtin: false),
        .init(tag: "P6", defaultName: "사용자2", builtin: false),
        .init(tag: "P7", defaultName: "사용자3", builtin: false),
        .init(tag: "P8", defaultName: "사용자4", builtin: false),
        .init(tag: "P9", defaultName: "사용자5", builtin: false),
    ]

    static let defaultMappings: [String: String] = [
        "FPS_F1": "K(HID_KEY_Q)",
        "FPS_F2": "K(HID_KEY_E)",
        "FPS_F3": "K(HID_KEY_C)",
        "FPS_F4": "MBR(MOUSE_BUTTON_LEFT)",
        "FPS_F5": "MODONLY(KEYBOARD_MODIFIER_LEFTSHIFT)",
        "FPS_F6": "K(HID_KEY_SPACE)",
        "FPS_F7": "MODONLY(KEYBOARD_MODIFIER_LEFTCTRL)",
        "FPS_F8": "MB(MOUSE_BUTTON_RIGHT)",
        "FPS_M1": "K(HID_KEY_X)",
        "FPS_M2": "K(HID_KEY_R)",
        "FPS_U1": "K(HID_KEY_TAB)",
        "FPS_U2": "K(HID_KEY_B)",
        "FPS_U3": "K(HID_KEY_ESCAPE)",
        "FPS_U4": "K(HID_KEY_ENTER)",
        "MOBA_F1": "K(HID_KEY_Q)",
        "MOBA_F2": "K(HID_KEY_W)",
        "MOBA_F3": "K(HID_KEY_E)",
        "MOBA_F4": "MBR(MOUSE_BUTTON_RIGHT)",
        "MOBA_F5": "K(HID_KEY_R)",
        "MOBA_F6": "K(HID_KEY_D)",
        "MOBA_F7": "K(HID_KEY_F)",
        "MOBA_F8": "MB(MOUSE_BUTTON_LEFT)",
        "MOBA_M1": "MB(MOUSE_BUTTON_LEFT)",
        "MOBA_M2": "K(HID_KEY_A)",
        "MOBA_U1": "K(HID_KEY_TAB)",
        "MOBA_U2": "K(HID_KEY_P)",
        "MOBA_U3": "K(HID_KEY_B)",
        "MOBA_U4": "K(HID_KEY_ESCAPE)",
        "DESK_F1": "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        "DESK_F2": "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        "DESK_F3": "K(HID_KEY_F5)",
        "DESK_F4": "MB(MOUSE_BUTTON_LEFT)",
        "DESK_F5": "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        "DESK_F6": "KM(HID_KEY_TAB, PRIMARY_MOD)",
        "DESK_F7": "KM(HID_KEY_W, PRIMARY_MOD)",
        "DESK_F8": "MB(MOUSE_BUTTON_RIGHT)",
        "DESK_M1": "MB(MOUSE_BUTTON_LEFT)",
        "DESK_M2": "MB(MOUSE_BUTTON_RIGHT)",
        "DESK_U1": "K(HID_KEY_ESCAPE)",
        "DESK_U2": "K(HID_KEY_ENTER)",
        "DESK_U3": "K(HID_KEY_TAB)",
        "DESK_U4": "KM(HID_KEY_T, PRIMARY_MOD)",
        "MEDIA_F1": "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        "MEDIA_F2": "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        "MEDIA_F3": "KM(HID_KEY_L, PRIMARY_MOD)",
        "MEDIA_F4": "MB(MOUSE_BUTTON_LEFT)",
        "MEDIA_F5": "K(HID_KEY_SLASH)",
        "MEDIA_F6": "K(HID_KEY_TAB)",
        "MEDIA_F7": "K(HID_KEY_K)",
        "MEDIA_F8": "MB(MOUSE_BUTTON_RIGHT)",
        "MEDIA_M1": "MB(MOUSE_BUTTON_LEFT)",
        "MEDIA_M2": "K(HID_KEY_F)",
        "MEDIA_U1": "K(HID_KEY_J)",
        "MEDIA_U2": "K(HID_KEY_K)",
        "MEDIA_U3": "K(HID_KEY_L)",
        "MEDIA_U4": "K(HID_KEY_ESCAPE)",
        "P5_F1": "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        "P5_F2": "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        "P5_F3": "K(HID_KEY_F5)",
        "P5_F4": "MB(MOUSE_BUTTON_LEFT)",
        "P5_F5": "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        "P5_F6": "KM(HID_KEY_TAB, PRIMARY_MOD)",
        "P5_F7": "KM(HID_KEY_W, PRIMARY_MOD)",
        "P5_F8": "MB(MOUSE_BUTTON_RIGHT)",
        "P5_M1": "MB(MOUSE_BUTTON_LEFT)",
        "P5_M2": "MB(MOUSE_BUTTON_RIGHT)",
        "P5_U1": "K(HID_KEY_ESCAPE)",
        "P5_U2": "K(HID_KEY_ENTER)",
        "P5_U3": "K(HID_KEY_TAB)",
        "P5_U4": "KM(HID_KEY_T, PRIMARY_MOD)",
        "P6_F1": "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        "P6_F2": "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        "P6_F3": "K(HID_KEY_F5)",
        "P6_F4": "MB(MOUSE_BUTTON_LEFT)",
        "P6_F5": "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        "P6_F6": "KM(HID_KEY_TAB, PRIMARY_MOD)",
        "P6_F7": "KM(HID_KEY_W, PRIMARY_MOD)",
        "P6_F8": "MB(MOUSE_BUTTON_RIGHT)",
        "P6_M1": "MB(MOUSE_BUTTON_LEFT)",
        "P6_M2": "MB(MOUSE_BUTTON_RIGHT)",
        "P6_U1": "K(HID_KEY_ESCAPE)",
        "P6_U2": "K(HID_KEY_ENTER)",
        "P6_U3": "K(HID_KEY_TAB)",
        "P6_U4": "KM(HID_KEY_T, PRIMARY_MOD)",
        "P7_F1": "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        "P7_F2": "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        "P7_F3": "K(HID_KEY_F5)",
        "P7_F4": "MB(MOUSE_BUTTON_LEFT)",
        "P7_F5": "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        "P7_F6": "KM(HID_KEY_TAB, PRIMARY_MOD)",
        "P7_F7": "KM(HID_KEY_W, PRIMARY_MOD)",
        "P7_F8": "MB(MOUSE_BUTTON_RIGHT)",
        "P7_M1": "MB(MOUSE_BUTTON_LEFT)",
        "P7_M2": "MB(MOUSE_BUTTON_RIGHT)",
        "P7_U1": "K(HID_KEY_ESCAPE)",
        "P7_U2": "K(HID_KEY_ENTER)",
        "P7_U3": "K(HID_KEY_TAB)",
        "P7_U4": "KM(HID_KEY_T, PRIMARY_MOD)",
        "P8_F1": "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        "P8_F2": "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        "P8_F3": "K(HID_KEY_F5)",
        "P8_F4": "MB(MOUSE_BUTTON_LEFT)",
        "P8_F5": "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        "P8_F6": "KM(HID_KEY_TAB, PRIMARY_MOD)",
        "P8_F7": "KM(HID_KEY_W, PRIMARY_MOD)",
        "P8_F8": "MB(MOUSE_BUTTON_RIGHT)",
        "P8_M1": "MB(MOUSE_BUTTON_LEFT)",
        "P8_M2": "MB(MOUSE_BUTTON_RIGHT)",
        "P8_U1": "K(HID_KEY_ESCAPE)",
        "P8_U2": "K(HID_KEY_ENTER)",
        "P8_U3": "K(HID_KEY_TAB)",
        "P8_U4": "KM(HID_KEY_T, PRIMARY_MOD)",
        "P9_F1": "KM(HID_KEY_ARROW_LEFT, NAV_MOD)",
        "P9_F2": "KM(HID_KEY_ARROW_RIGHT, NAV_MOD)",
        "P9_F3": "K(HID_KEY_F5)",
        "P9_F4": "MB(MOUSE_BUTTON_LEFT)",
        "P9_F5": "KM(HID_KEY_TAB, PRIMARY_MOD | KEYBOARD_MODIFIER_LEFTSHIFT)",
        "P9_F6": "KM(HID_KEY_TAB, PRIMARY_MOD)",
        "P9_F7": "KM(HID_KEY_W, PRIMARY_MOD)",
        "P9_F8": "MB(MOUSE_BUTTON_RIGHT)",
        "P9_M1": "MB(MOUSE_BUTTON_LEFT)",
        "P9_M2": "MB(MOUSE_BUTTON_RIGHT)",
        "P9_U1": "K(HID_KEY_ESCAPE)",
        "P9_U2": "K(HID_KEY_ENTER)",
        "P9_U3": "K(HID_KEY_TAB)",
        "P9_U4": "KM(HID_KEY_T, PRIMARY_MOD)",
    ]

    struct Range { let min: Double; let max: Double; let step: Double; let def: Double }
    static let sensitivity: [String: Range] = [
        "gdz": .init(min: 0.0, max: 0.4, step: 0.01, def: 0.1),
        "tdz": .init(min: 0.0, max: 0.4, step: 0.01, def: 0.14),
        "gsat": .init(min: 0.55, max: 1.0, step: 0.01, def: 0.85),
        "tsat": .init(min: 0.55, max: 1.0, step: 0.01, def: 0.9),
        "fps": .init(min: 4, max: 45, step: 1, def: 22),
        "moba": .init(min: 4, max: 45, step: 1, def: 16),
        "desk": .init(min: 4, max: 45, step: 1, def: 14),
        "gamma": .init(min: 1.0, max: 3.0, step: 0.1, def: 1.8),
        "wasd": .init(min: 0.15, max: 0.75, step: 0.01, def: 0.38),
        "debounce": .init(min: 2, max: 25, step: 1, def: 12),
    ]

    /// 감도 헤더. 골든 fixture 와 byte-for-byte 같아야 한다.
    static func sensitivityHeader(_ s: [String: Double]) -> String {
        func f2(_ k: String) -> String { String(format: "%.2ff", s[k] ?? 0) }
        func f1(_ k: String) -> String { String(format: "%.1ff", s[k] ?? 0) }
        return """
        // 딸깍 감도 조절기에서 생성됨 — 직접 편집하지 마세요.
        // 이 파일을 firmware/ttalkkak/sensitivity_override.h 로 저장한 뒤 빌드하세요.
        #pragma once
        #define DEADZONE_GIMBAL \(f2("gdz"))
        #define DEADZONE_THUMB \(f2("tdz"))
        #define SATURATE_GIMBAL \(f2("gsat"))
        #define SATURATE_THUMB \(f2("tsat"))
        #define MOUSE_GAMMA \(f1("gamma"))
        #define MOUSE_SPEED_FPS \(f1("fps"))
        #define MOUSE_SPEED_MOBA \(f1("moba"))
        #define MOUSE_SPEED_DESK \(f1("desk"))
        #define WASD_THRESHOLD \(f2("wasd"))
        #define DEBOUNCE_MS \(Int((s["debounce"] ?? 12).rounded()))

        """
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
            "#define TTK_PROFILE_COUNT \(profileCount)", ""
        ]
        for p in profiles {
            let name = (names[p.tag] ?? p.defaultName).replacingOccurrences(of: "\"", with: "")
            lines.append("// --- \(p.tag) : \(name) ---")
            lines.append("#define TTK_NAME_\(p.tag) \"\(name)\"")
            for b in editableButtons {
                lines.append("#define TTK_ACT_\(p.tag)_\(b) \(mappings["\(p.tag)_\(b)"] ?? "NA")")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
