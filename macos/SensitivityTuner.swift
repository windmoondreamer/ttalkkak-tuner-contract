import AppKit
import SwiftUI
import UniformTypeIdentifiers
import Foundation
import Darwin

// 액션·버튼·프로필·기본 배치는 contract/settings-contract.json 이 진실이고,
// contract/generated/Contract.swift 로 생성된다. 여기서 다시 적지 않는다.
// (2026-08-28 이전에는 macOS 70개 · Windows 8개 · 계약 16개로 셋 다 달랐다.)
private let actionChoices = Contract.actions

/// 프로필(페이지) 정의. 앞 4개는 원래 배치, 뒤 5개는 사용자 커스텀이다.
/// tag 는 펌웨어 매크로 이름에 그대로 들어간다 (TTK_ACT_<tag>_F1 …).
private struct Profile: Identifiable {
    let tag: String
    let defaultName: String
    let builtin: Bool
    var id: String { tag }
}

private let allProfiles: [Profile] = Contract.profiles.map {
    Profile(tag: $0.tag, defaultName: $0.defaultName, builtin: $0.builtin)
}

private let mappableButtons = Contract.editableButtons
private let fullDefaultMappings = Contract.defaultMappings

/// 상단 큰 메뉴. 부위별로 나눠서 "지금 뭘 만지는지"가 분명해지게 한다.
/// 이름을 Section 으로 두면 SwiftUI.Section 과 충돌한다.
private enum TunerSection: String, CaseIterable, Identifiable {
    case gimbal = "하부 짐벌"
    case thumbStick = "엄지 조이스틱"
    case thumbButtons = "엄지쪽 버튼"
    case fingerButtons = "검지·중지 버튼"
    case profiles = "프로필 페이지"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gimbal: return "hand.raised.fill"
        case .thumbStick: return "circle.circle"
        case .thumbButtons: return "hand.thumbsup"
        case .fingerButtons: return "hand.point.up.left"
        case .profiles: return "square.stack.3d.up"
        }
    }

    var blurb: String {
        switch self {
        case .gimbal: return "손 전체로 미는 하부 짐벌(홀센서, GP26·GP27)의 감도와 반응을 봅니다."
        case .thumbStick: return "엄지로 미는 스틱(GP28·GP29)의 감도와 커서 속도를 봅니다."
        case .thumbButtons: return "크라운 M1·M2, 스틱 클릭 SP, MODE 링 MD 입니다."
        case .fingerButtons: return "검지 F1~F4, 중지 F5~F8, 베이스 U1~U4 입니다."
        case .profiles: return "프로필 페이지 개수와 각 페이지의 키 배치를 정합니다."
        }
    }
}

private struct PhysicalButton: Identifiable {
    let id: String
    let subtitle: String
    let group: TunerSection
}

private let physicalButtons: [PhysicalButton] = Contract.buttons.map {
    PhysicalButton(id: $0.id, subtitle: $0.subtitle,
                   group: $0.group == "thumb" ? .thumbButtons : .fingerButtons)
}

/// btnev 마스크의 비트 순서 — pins.h 의 BTN_* 열거와 같다 (계약이 보장한다).
private let bitOrder = Contract.bitOrder

private final class InputMonitor: ObservableObject {
    @Published var ports: [String] = []
    @Published var selectedPort = ""
    @Published var connected = false
    @Published var pressed: Set<String> = []
    @Published var message = "진단 펌웨어를 연결한 뒤 포트를 선택하세요."
    // 축 상태 — 펌웨어의 axev= 줄에서 온다 (약 50Hz)
    @Published var gimbal = CGPoint.zero      // 하부 짐벌, 데드존·포화 적용 후 -1~+1
    @Published var thumb = CGPoint.zero       // 엄지 스틱
    @Published var gimbalRaw = CGPoint.zero   // EMA 만 거친 ADC — 센서가 실제로 움직이는지
    @Published var thumbRaw = CGPoint.zero
    @Published var gimbalCenter = CGPoint.zero
    @Published var thumbCenter = CGPoint.zero
    @Published var gimbalDead = false         // 미연결 판정
    @Published var thumbDead = false
    @Published var sawAxis = false            // axev 를 한 번이라도 받았는가
    @Published var gimbalReach = CGPoint.zero // 이번 세션에서 도달한 최대 |값|
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceRead?
    private var buffer = ""
    private let bitNames = bitOrder

    init() { refreshPorts() }
    deinit { disconnect() }

    func refreshPorts() {
        let found = (try? FileManager.default.contentsOfDirectory(atPath: "/dev"))?.filter {
            $0.hasPrefix("cu.usbmodem") || $0.hasPrefix("cu.usbserial")
        }.map { "/dev/\($0)" }.sorted() ?? []
        ports = found
        if !found.contains(selectedPort) { selectedPort = found.first ?? "" }
        if found.isEmpty { message = "시리얼 포트를 찾지 못했습니다. USB 연결과 진단 펌웨어를 확인하세요." }
    }

    func toggleConnection() { connected ? disconnect() : connect() }

    private func connect() {
        guard !selectedPort.isEmpty else { message = "연결할 시리얼 포트를 먼저 선택하세요."; return }
        let fd = open(selectedPort, O_RDWR | O_NOCTTY | O_NONBLOCK)
        guard fd >= 0 else { message = "포트를 열 수 없습니다: \(selectedPort)"; return }
        var options = termios()
        guard tcgetattr(fd, &options) == 0 else { close(fd); message = "시리얼 설정을 읽지 못했습니다."; return }
        cfmakeraw(&options)
        cfsetspeed(&options, speed_t(B115200))
        options.c_cflag |= tcflag_t(CLOCAL | CREAD)
        guard tcsetattr(fd, TCSANOW, &options) == 0 else { close(fd); message = "115200bps 설정에 실패했습니다."; return }
        fileDescriptor = fd
        let readSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: DispatchQueue.global(qos: .userInitiated))
        readSource.setEventHandler { [weak self] in self?.readAvailable() }
        readSource.setCancelHandler { close(fd) }
        source = readSource; readSource.resume()
        connected = true; message = "연결됨 — 버튼을 누르면 초록색으로 표시됩니다."
    }

    func disconnect() {
        source?.cancel(); source = nil; fileDescriptor = -1
        if connected { message = "연결을 해제했습니다." }
        connected = false; pressed = []
        sawAxis = false; gimbalReach = .zero
    }

    func resetReach() { gimbalReach = .zero }

    private func readAvailable() {
        var bytes = [UInt8](repeating: 0, count: 1024)
        let count = read(fileDescriptor, &bytes, bytes.count)
        guard count > 0, let text = String(bytes: bytes[0..<Int(count)], encoding: .utf8) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.buffer += text
            let lines = self.buffer.split(separator: "\n", omittingEmptySubsequences: false)
            self.buffer = lines.last.map(String.init) ?? ""
            for line in lines.dropLast() { self.consume(String(line)) }
        }
    }

    private func consume(_ line: String) {
        if line.hasPrefix("axev=") { consumeAxis(line); return }
        guard let start = line.range(of: "btnev=") else { return }
        let hex = line[start.upperBound...].prefix(4)
        guard hex.count == 4, let mask = UInt16(hex, radix: 16) else { return }
        pressed = Set(bitNames.enumerated().compactMap { index, name in (mask & (1 << index)) != 0 ? name : nil })
    }

    /// axev=+0.000,+0.000,+0.000,-0.000 gr=2216,2028 tr=2060,2069 gc=... tc=... d=00
    private func consumeAxis(_ line: String) {
        let fields = line.split(separator: " ")
        guard let head = fields.first else { return }
        let nums = head.dropFirst("axev=".count).split(separator: ",").compactMap { Double($0) }
        guard nums.count == 4 else { return }
        gimbal = CGPoint(x: nums[0], y: nums[1])
        thumb  = CGPoint(x: nums[2], y: nums[3])
        gimbalReach = CGPoint(x: max(gimbalReach.x, abs(nums[0])),
                              y: max(gimbalReach.y, abs(nums[1])))
        for field in fields.dropFirst() {
            let parts = field.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]), value = String(parts[1])
            if key == "d" {
                let flags = Array(value)
                if flags.count == 2 { gimbalDead = flags[0] == "1"; thumbDead = flags[1] == "1" }
                continue
            }
            let pair = value.split(separator: ",").compactMap { Double($0) }
            guard pair.count == 2 else { continue }
            let point = CGPoint(x: pair[0], y: pair[1])
            switch key {
            case "gr": gimbalRaw = point
            case "tr": thumbRaw = point
            case "gc": gimbalCenter = point
            case "tc": thumbCenter = point
            default: break
            }
        }
        sawAxis = true
    }
}

/// 축 하나를 2D 패드로 그린다. 데드존·포화 원을 같이 그려서
/// "얼마나 밀어야 반응이 시작되고, 어디서 최대가 되는지"를 눈으로 보게 한다.
private struct StickPad: View {
    let title: String
    let value: CGPoint          // -1 ~ +1 (데드존·포화 적용 후)
    let raw: CGPoint            // EMA 만 거친 ADC
    let center: CGPoint         // 부팅 때 잡은 중립
    let deadzone: Double
    let saturation: Double
    let dead: Bool
    let reach: CGPoint?         // 이번 세션 최대 도달치 (짐벌만)

    private let side: CGFloat = 232

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(title).font(.system(size: 15, weight: .bold))
                if dead {
                    Text("미연결").font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(Color.orange.opacity(0.3)).clipShape(Capsule())
                }
            }
            ZStack {
                Rectangle().fill(Color.secondary.opacity(0.08))
                Path { p in
                    p.move(to: CGPoint(x: side / 2, y: 0)); p.addLine(to: CGPoint(x: side / 2, y: side))
                    p.move(to: CGPoint(x: 0, y: side / 2)); p.addLine(to: CGPoint(x: side, y: side / 2))
                }.stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                // 데드존은 원 안쪽을 옅게 칠해서, 점에 가려도 범위가 보이게 한다.
                // 선만 그리면 데드존이 작을 때(0.10 = 지름 23pt) 점 밑으로 숨는다.
                Circle().fill(Color.orange.opacity(0.16))
                    .frame(width: side * deadzone, height: side * deadzone)
                Circle().stroke(Color.orange.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: side * deadzone, height: side * deadzone)
                Circle().stroke(Color.green.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .frame(width: side * saturation, height: side * saturation)
                // 위치 점 — 흰 테두리를 둘러 배경·원과 구분되게 한다.
                Circle()
                    .fill(dead ? Color.orange : (magnitude > 0 ? Color.accentColor : Color.secondary))
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                    .frame(width: 15, height: 15)
                    .shadow(radius: 1.5)
                    .offset(x: CGFloat(value.x) * side / 2, y: CGFloat(-value.y) * side / 2)
                    .animation(.easeOut(duration: 0.04), value: value)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.25), lineWidth: 1))

            HStack(spacing: 14) {
                legend(Color.orange, "데드존")
                legend(Color.green, "포화점")
                Spacer()
            }.frame(width: side, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                row("출력", String(format: "%+.2f , %+.2f", value.x, value.y))
                row("ADC", String(format: "%d , %d", Int(raw.x), Int(raw.y)))
                row("중립에서", String(format: "%+d , %+d", Int(raw.x - center.x), Int(raw.y - center.y)))
                if let reach {
                    row("최대 도달", String(format: "%.2f , %.2f", reach.x, reach.y))
                }
            }.frame(width: side, alignment: .leading)
        }
    }

    private var magnitude: Double { abs(value.x) + abs(value.y) }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Circle().stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                .frame(width: 11, height: 11)
            Text(text).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.system(size: 13)).foregroundStyle(.secondary)
            Spacer()
            Text(v).font(.system(size: 15, weight: .semibold, design: .monospaced))
        }
    }
}

@main
struct SensitivityTunerApp: App {
    var body: some Scene {
        WindowGroup("딸깍 감도 조절기") {
            ContentView().frame(minWidth: 1040, minHeight: 820)
        }
        .windowResizability(.contentSize)
    }
}

private struct Setting {
    let title: String
    let help: String
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
}

private struct ContentView: View {
    @State private var gimbalDeadzone = 0.10
    @State private var thumbDeadzone = 0.14
    @State private var gimbalSaturation = 0.85
    @State private var thumbSaturation = 0.90
    @State private var fpsSpeed = 22.0
    @State private var mobaSpeed = 16.0
    @State private var deskSpeed = 14.0
    @State private var mouseGamma = 1.8
    @State private var wasdThreshold = 0.38
    @State private var debounce = 12.0
    @State private var status = "값을 조절한 뒤 ‘펌웨어 설정 저장’을 누르세요."
    @State private var didCopy = false
    @State private var layoutMode = "FPS"
    @State private var mappings = fullDefaultMappings
    @State private var section: TunerSection = .gimbal
    @State private var profileCount = 4
    @State private var profileNames: [String: String] =
        Dictionary(uniqueKeysWithValues: allProfiles.map { ($0.tag, $0.defaultName) })
    @State private var confirmReset = false
    @State private var presetName = "기본 설정"
    @State private var loadError: String?
    @StateObject private var inputMonitor = InputMonitor()

    /// 지금 순환에 들어가는 프로필만
    private var activeProfiles: [Profile] { Array(allProfiles.prefix(profileCount)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            topMenu
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(section.blurb).font(.system(size: 15)).foregroundStyle(.secondary)
                    switch section {
                    case .gimbal:        gimbalSection
                    case .thumbStick:    thumbStickSection
                    case .thumbButtons:  buttonSection(.thumbButtons)
                    case .fingerButtons: buttonSection(.fingerButtons)
                    case .profiles:      profilesSection
                    }
                }.padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 20)
            }
            Divider()
            footer
        }
        .onAppear {
            restoreLastSession()
            // onChange 는 값이 바뀔 때만 돈다. 첫 실행에도 파일이 남게 여기서 한 번 쓴다.
            autosave()
        }
        // 값이 바뀔 때마다 조용히 마지막 상태를 남긴다. 앱을 다시 켜면 여기서 복원한다.
        .onChange(of: currentSignature) { _, _ in autosave() }
        .alert("프리셋을 불러오지 못했습니다",
               isPresented: Binding(get: { loadError != nil },
                                    set: { if !$0 { loadError = nil } })) {
            Button("확인", role: .cancel) { loadError = nil }
        } message: {
            Text(loadError ?? "")
        }
    }

    /// 자동 저장 트리거용. 값이 하나라도 바뀌면 이 문자열이 바뀐다.
    private var currentSignature: String {
        "\(presetName)|\(profileCount)|\(gimbalDeadzone)|\(thumbDeadzone)|"
        + "\(gimbalSaturation)|\(thumbSaturation)|\(mouseGamma)|\(fpsSpeed)|"
        + "\(mobaSpeed)|\(deskSpeed)|\(wasdThreshold)|\(debounce)|"
        + profileNames.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        + "|" + mappings.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("딸깍 감도 조절기").font(.system(size: 28, weight: .bold))
            Text("부위를 고르고, 값을 조절하고, 펌웨어 설정 파일로 저장합니다.")
                .foregroundStyle(.secondary).font(.system(size: 15))
        }.padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 14)
         .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 상단 큰 메뉴 — 부위별로 눌러서 이동한다.
    private var topMenu: some View {
        HStack(spacing: 10) {
            ForEach(TunerSection.allCases) { item in
                Button { section = item } label: {
                    VStack(spacing: 8) {
                        Image(systemName: item.icon).font(.system(size: 28, weight: .medium))
                        Text(item.rawValue).font(.system(size: 15, weight: .bold))
                            .lineLimit(1).minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity).frame(height: 92)
                    .background(section == item ? Color.accentColor : Color.secondary.opacity(0.12))
                    .foregroundStyle(section == item ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(section == item ? Color.accentColor : Color.secondary.opacity(0.22), lineWidth: 2))
                }.buttonStyle(.plain)
                .help(item.blurb)
            }
        }.padding(.horizontal, 24).padding(.bottom, 14)
    }

    private var footer: some View {
        HStack {
            Button("전체 초기화…") { confirmReset = true }.controlSize(.large)
                .confirmationDialog("모든 설정을 처음 상태로 되돌릴까요?", isPresented: $confirmReset) {
                    Button("초기화", role: .destructive, action: reset)
                    Button("취소", role: .cancel) {}
                } message: {
                    Text("감도·커서 속도·프로필 이름·키 배치·페이지 개수가 전부 기본값으로 돌아갑니다.")
                }
            Button("불러오기…", action: importPreset).controlSize(.large)
            Button("내보내기…", action: exportPreset).controlSize(.large)
            Spacer()
            Text(status).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(2)
            Spacer()
            Button(didCopy ? "빌드 명령 복사됨" : "빌드 명령 복사", action: copyCommand)
                .controlSize(.large)
            Button("펌웨어 설정 저장…", action: saveHeader)
                .keyboardShortcut("s").buttonStyle(.borderedProminent).controlSize(.large)
        }.padding(.horizontal, 24).padding(.vertical, 16)
    }

    // ---------------- 부위별 화면 ----------------

    private var gimbalSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            serialBar
            GroupBox(label: boxTitle("실시간 확인")) {
                HStack(alignment: .top, spacing: 22) {
                    StickPad(title: "하부 짐벌 (HALL · GP26/27)",
                             value: inputMonitor.gimbal, raw: inputMonitor.gimbalRaw,
                             center: inputMonitor.gimbalCenter,
                             deadzone: gimbalDeadzone, saturation: gimbalSaturation,
                             dead: inputMonitor.gimbalDead, reach: inputMonitor.gimbalReach)
                    VStack(alignment: .leading, spacing: 9) {
                        Text(gimbalVerdict).font(.system(size: 16, weight: .medium))
                        Text("주황 원이 데드존, 초록 원이 포화점입니다. 점이 주황 원을 벗어나야 반응이 시작되고, 초록 원에 닿으면 최대 출력입니다.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                        Text("짐벌을 8방향으로 끝까지 밀어 ‘최대 도달’이 양쪽 다 0.85를 넘는지 보세요.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                        Button("최대 도달 초기화") { inputMonitor.resetReach() }
                            .disabled(!inputMonitor.connected).controlSize(.large)
                        Spacer(minLength: 0)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding(.top, 4)
            }
            GroupBox(label: boxTitle("감도")) {
                VStack(spacing: 14) {
                    slider("데드존", "중립 근처에서 무시할 범위입니다. 커서가 저절로 움직이면 올리세요.", 0...0.40, 0.01, $gimbalDeadzone, 2)
                    slider("최대 입력(포화점)", "낮을수록 끝까지 덜 밀어도 최대 입력으로 처리합니다.", 0.55...1.00, 0.01, $gimbalSaturation, 2)
                    slider("WASD 입력 시작점", "짐벌을 얼마나 기울여야 이동 키가 눌리는지입니다. FPS·MOBA에서 쓰입니다.", 0.15...0.75, 0.01, $wasdThreshold, 2)
                }.padding(.top, 4)
            }
        }
    }

    private var thumbStickSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            serialBar
            GroupBox(label: boxTitle("실시간 확인")) {
                HStack(alignment: .top, spacing: 22) {
                    StickPad(title: "엄지 스틱 (GP28/29)",
                             value: inputMonitor.thumb, raw: inputMonitor.thumbRaw,
                             center: inputMonitor.thumbCenter,
                             deadzone: thumbDeadzone, saturation: thumbSaturation,
                             dead: inputMonitor.thumbDead, reach: nil)
                    VStack(alignment: .leading, spacing: 9) {
                        Text(thumbVerdict).font(.system(size: 16, weight: .medium))
                        Text("엄지 스틱은 프로필에 따라 마우스 커서(FPS·MOBA) 또는 스크롤(DESK·MEDIA)이 됩니다.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                        Text("손을 뗐는데 점이 중앙에 없으면 MODE 링을 1초 눌러 재캘리브레이션하세요.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding(.top, 4)
            }
            GroupBox(label: boxTitle("감도")) {
                VStack(spacing: 14) {
                    slider("데드존", "엄지의 미세 떨림을 줄입니다. 반응이 둔하면 낮추세요.", 0...0.40, 0.01, $thumbDeadzone, 2)
                    slider("최대 입력(포화점)", "엄지 스틱의 끝 입력 민감도입니다.", 0.55...1.00, 0.01, $thumbSaturation, 2)
                }.padding(.top, 4)
            }
            GroupBox(label: boxTitle("커서 속도")) {
                VStack(spacing: 14) {
                    slider("FPS 조준 속도", "발로란트 등에서 조준할 때 커서 속도입니다.", 4...45, 1, $fpsSpeed, 0)
                    slider("MOBA 커서 속도", "스킬 조준·포인팅 속도입니다.", 4...45, 1, $mobaSpeed, 0)
                    slider("DESK 커서 속도", "웹·데스크톱 탐색 속도입니다. MEDIA와 커스텀 페이지도 이 값을 씁니다.", 4...45, 1, $deskSpeed, 0)
                    slider("미세 조준 곡선", "높을수록 중앙은 느리고 끝은 빠릅니다.", 1.0...3.0, 0.1, $mouseGamma, 1)
                }.padding(.top, 4)
            }
        }
    }

    /// 버튼 부위 화면 — 실시간 눌림 확인 + 그 부위 버튼의 키 배치를 한자리에서.
    private func buttonSection(_ group: TunerSection) -> some View {
        let buttons = physicalButtons.filter { $0.group == group }
        let editable = buttons.filter { mappableButtons.contains($0.id) }
        return VStack(alignment: .leading, spacing: 18) {
            serialBar
            GroupBox(label: boxTitle("실시간 눌림 확인")) {
                VStack(alignment: .leading, spacing: 10) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(buttons) { button in
                            VStack(spacing: 5) {
                                Text(button.id).font(.system(size: 26, weight: .bold, design: .rounded))
                                Text(button.subtitle).font(.system(size: 12, weight: .medium))
                            }
                            .frame(maxWidth: .infinity, minHeight: 86)
                            .background(inputMonitor.pressed.contains(button.id) ? Color.green.opacity(0.86) : Color.secondary.opacity(0.12))
                            .foregroundStyle(inputMonitor.pressed.contains(button.id) ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(inputMonitor.pressed.contains(button.id) ? Color.green : Color.secondary.opacity(0.2), lineWidth: 2))
                            .animation(.easeOut(duration: 0.08), value: inputMonitor.pressed)
                        }
                    }
                    Text("누르면 초록색으로 바뀝니다. 안 바뀌면 그 버튼의 배선을 확인하세요.")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }.padding(.top, 4)
            }
            GroupBox(label: boxTitle("이 부위의 키 배치")) {
                VStack(alignment: .leading, spacing: 10) {
                    profilePicker
                    ForEach(editable) { button in
                        HStack(spacing: 12) {
                            Text(button.id)
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .frame(width: 44, height: 40)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(button.subtitle).font(.system(size: 14)).foregroundStyle(.secondary)
                                .frame(width: 92, alignment: .leading)
                            Picker(button.id, selection: mappingBinding("\(layoutMode)_\(button.id)")) {
                                ForEach(actionChoices) { action in Text(action.label).tag(action.macro) }
                            }.labelsHidden().controlSize(.large).frame(maxWidth: .infinity)
                        }
                    }
                    if editable.count < buttons.count {
                        Text("SP(스틱 클릭)와 MD(MODE 링)는 모드 전환·재캘리브레이션·레벨업 기능이 걸려 있어 고정입니다.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                }.padding(.top, 4)
            }
        }
    }

    /// 편집할 페이지 고르기 — 드롭다운 대신 큰 버튼으로 늘어놓는다.
    /// 목록을 펼쳐서 고르는 것보다 한 번에 눌러서 고르는 쪽이 훨씬 쉽다.
    private var profilePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("편집할 페이지").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(activeProfiles) { p in
                    Button { layoutMode = p.tag } label: {
                        VStack(spacing: 2) {
                            Text(profileNames[p.tag] ?? p.defaultName)
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Text(profileOrdinal(p)).font(.system(size: 11))
                        }
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(layoutMode == p.tag ? Color.accentColor : Color.secondary.opacity(0.12))
                        .foregroundStyle(layoutMode == p.tag ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox(label: boxTitle("프리셋")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text("이름").font(.system(size: 14)).foregroundStyle(.secondary)
                        TextField("기본 설정", text: $presetName)
                            .font(.system(size: 16)).controlSize(.large).frame(maxWidth: 260)
                        Spacer()
                    }
                    Text("아래 ‘내보내기’ 로 저장하면 Windows 설정기에서 그대로 열립니다. 값은 바꿀 때마다 자동으로 기억됩니다.")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }.padding(.top, 4)
            }
            GroupBox(label: boxTitle("프로필 페이지")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MODE 링을 짧게 누르면 아래 페이지들이 순서대로 순환합니다.")
                        .font(.system(size: 14)).foregroundStyle(.secondary)

                    ForEach(activeProfiles) { p in
                        HStack(spacing: 12) {
                            Text(profileOrdinal(p))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .frame(width: 46, height: 44)
                                .background(layoutMode == p.tag ? Color.accentColor : Color.secondary.opacity(0.14))
                                .foregroundStyle(layoutMode == p.tag ? Color.white : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                            TextField(p.defaultName, text: nameBinding(p.tag))
                                .font(.system(size: 16)).controlSize(.large).frame(maxWidth: 240)
                            Text(p.builtin ? "기본 페이지" : "커스텀 — 기본 배치는 DESK 복사")
                                .font(.system(size: 13)).foregroundStyle(.secondary)
                            Spacer()
                            Button("이 페이지 편집") { layoutMode = p.tag }
                                .controlSize(.large)
                                .disabled(layoutMode == p.tag)
                            // 마지막 페이지만 뺄 수 있다. 중간을 빼면 뒤 페이지 번호가
                            // 전부 밀려서 이미 잡아 둔 키 배치가 어긋난다.
                            Button {
                                removeLastPage()
                            } label: {
                                Image(systemName: "minus.circle.fill").font(.system(size: 19))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(canRemovePage(p) ? Color.red.opacity(0.8) : Color.clear)
                            .disabled(!canRemovePage(p))
                            .help("이 페이지를 뺍니다")
                        }
                        .padding(.vertical, 3)
                    }

                    if profileCount < allProfiles.count {
                        let next = allProfiles[profileCount]
                        Button {
                            setProfileCount(profileCount + 1)
                            layoutMode = next.tag
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: "plus.circle.fill").font(.system(size: 19))
                                Text("페이지 추가  —  \(profileCount + 1)번 ‘\(profileNames[next.tag] ?? next.defaultName)’")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .overlay(RoundedRectangle(cornerRadius: 11)
                                .stroke(Color.accentColor.opacity(0.45),
                                        style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
                        }.buttonStyle(.plain)
                    } else {
                        Text("최대 9페이지입니다.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                    }

                    if profileCount != 4 {
                        HStack(spacing: 8) {
                            Text("처음 저장한 구성은 4페이지입니다.")
                                .font(.system(size: 13)).foregroundStyle(.secondary)
                            Button("4페이지로 되돌리기") { setProfileCount(4) }.controlSize(.large)
                        }
                    }
                }.padding(.top, 4)
            }
            GroupBox(label: boxTitle("키 배치 — 전체 14칸")) {
                VStack(alignment: .leading, spacing: 10) {
                    // 편집 대상은 위 목록의 '이 페이지 편집' 으로 고른다. 여기선 표시만.
                    HStack(spacing: 8) {
                        Text("편집 중")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                        Text(profileNames[layoutMode] ?? layoutMode)
                            .font(.system(size: 17, weight: .bold))
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Color.accentColor.opacity(0.18))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 10) {
                        ForEach(mappableButtons, id: \.self) { button in
                            HStack(spacing: 10) {
                                Text(button)
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                    .frame(width: 44, height: 40)
                                    .background(inputMonitor.pressed.contains(button)
                                                ? Color.green.opacity(0.8) : Color.secondary.opacity(0.12))
                                    .foregroundStyle(inputMonitor.pressed.contains(button) ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .animation(.easeOut(duration: 0.08), value: inputMonitor.pressed)
                                Picker(button, selection: mappingBinding("\(layoutMode)_\(button)")) {
                                    ForEach(actionChoices) { action in Text(action.label).tag(action.macro) }
                                }.labelsHidden().controlSize(.large).frame(maxWidth: .infinity)
                            }
                        }
                    }
                    HStack {
                        Button("이 페이지 기본 배치 복원") {
                            for button in mappableButtons {
                                mappings["\(layoutMode)_\(button)"] = fullDefaultMappings["\(layoutMode)_\(button)"]
                            }
                            status = "\(profileNames[layoutMode] ?? layoutMode) 페이지를 기본 배치로 되돌렸습니다."
                        }.controlSize(.large)
                        Button("DESK 배치 복사해오기") {
                            for button in mappableButtons {
                                mappings["\(layoutMode)_\(button)"] = mappings["DESK_\(button)"]
                            }
                            status = "DESK 배치를 \(profileNames[layoutMode] ?? layoutMode) 페이지로 복사했습니다."
                        }.controlSize(.large)
                        Spacer()
                    }
                }.padding(.top, 4)
            }
            switchModeGuide
        }
    }

    /// 마지막 페이지만 뺄 수 있는지. 1페이지는 남겨야 한다.
    private func canRemovePage(_ p: Profile) -> Bool {
        profileCount > 1 && allProfiles.firstIndex(where: { $0.tag == p.tag }) == profileCount - 1
    }

    private func removeLastPage() {
        guard profileCount > 1 else { return }
        let removed = allProfiles[profileCount - 1]
        setProfileCount(profileCount - 1)
        status = "\(profileNames[removed.tag] ?? removed.defaultName) 페이지를 뺐습니다. 키 배치는 그대로 남아 있어 다시 추가하면 살아납니다."
    }

    private func setProfileCount(_ count: Int) {
        profileCount = count
        // 편집 중이던 페이지가 범위 밖으로 밀려나면 마지막 페이지로 옮긴다
        if let index = allProfiles.firstIndex(where: { $0.tag == layoutMode }), index >= count {
            layoutMode = allProfiles[max(0, count - 1)].tag
        }
        status = "페이지를 \(count)개로 정했습니다."
    }

    private func profileOrdinal(_ p: Profile) -> String {
        "\((allProfiles.firstIndex(where: { $0.tag == p.tag }) ?? 0) + 1)번"
    }

    private func nameBinding(_ tag: String) -> Binding<String> {
        Binding(get: { profileNames[tag] ?? tag }, set: { profileNames[tag] = $0 })
    }

    /// 시리얼 연결 줄 — 실시간 확인이 필요한 화면마다 같은 모양으로 보여준다.
    private var serialBar: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker("시리얼 포트", selection: $inputMonitor.selectedPort) {
                        if inputMonitor.ports.isEmpty { Text("포트 없음").tag("") }
                        ForEach(inputMonitor.ports, id: \.self) { Text($0).tag($0) }
                    }.frame(maxWidth: 340).controlSize(.large)
                    Button("새로 고침") { inputMonitor.refreshPorts() }.controlSize(.large)
                    Spacer()
                    Button(inputMonitor.connected ? "연결 해제" : "연결") { inputMonitor.toggleConnection() }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
                Label(inputMonitor.message, systemImage: inputMonitor.connected ? "checkmark.circle.fill" : "info.circle")
                    .font(.caption).foregroundStyle(inputMonitor.connected ? .green : .secondary)
                if !inputMonitor.connected {
                    Text("진단 펌웨어가 필요합니다 — ‘빌드 명령 복사’ 후 터미널에서 ./build.sh diagpcf upload")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
            }.padding(.top, 2)
        }
    }

    /// 엄지 스틱 상태 한 줄 판정
    private var thumbVerdict: String {
        if !inputMonitor.connected { return "연결하면 엄지 스틱 상태가 여기 표시됩니다." }
        if !inputMonitor.sawAxis { return "축 데이터를 못 받았습니다 — diagpcf 또는 diag 빌드로 다시 올리세요." }
        if inputMonitor.thumbDead {
            return "엄지 스틱 미연결로 판정됐습니다. GP28·GP29 배선과 3.3V를 확인하세요."
        }
        let dx = abs(inputMonitor.thumbRaw.x - inputMonitor.thumbCenter.x)
        let dy = abs(inputMonitor.thumbRaw.y - inputMonitor.thumbCenter.y)
        if dx < 8 && dy < 8 { return "엄지 스틱을 밀어 보세요. 아직 중립에서 안 움직였습니다." }
        if abs(inputMonitor.thumb.x) < 0.01 && abs(inputMonitor.thumb.y) < 0.01 {
            return "움직임은 감지되는데 데드존을 못 넘었습니다. 데드존을 낮춰 보세요."
        }
        return "정상 — 입력이 들어오고 있습니다."
    }

    private func slider(_ title: String, _ help: String, _ range: ClosedRange<Double>, _ step: Double, _ value: Binding<Double>, _ precision: Int, _ unit: String = "") -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title).font(.system(size: 16, weight: .semibold))
                Spacer()
                // 값을 크게 — 슬라이더를 미세 조작하지 않아도 숫자로 확인된다
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(precision))) + unit)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit().foregroundStyle(.tint)
                    .frame(minWidth: 74, alignment: .trailing)
            }
            HStack(spacing: 10) {
                stepButton("minus") { value.wrappedValue = max(range.lowerBound, value.wrappedValue - step) }
                Slider(value: value, in: range, step: step).controlSize(.large)
                stepButton("plus") { value.wrappedValue = min(range.upperBound, value.wrappedValue + step) }
            }
            Text(help).font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }

    private func boxTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 17, weight: .bold)).padding(.bottom, 2)
    }

    /// 슬라이더 옆 ±버튼. 미세 조작이 어려운 사용자를 위해 한 칸씩 눌러서 바꾼다.
    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 15, weight: .bold))
                .frame(width: 38, height: 32)
                .background(Color.secondary.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
    }

    private func summary(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 13)).foregroundStyle(.secondary)
            Text(value).font(.caption).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 8)
    }

    private var gimbalVerdict: String {
        if !inputMonitor.connected { return "연결하면 짐벌 상태가 여기 표시됩니다." }
        if !inputMonitor.sawAxis { return "축 데이터를 못 받았습니다 — diagpcf 또는 diag 빌드로 다시 올리세요." }
        if inputMonitor.gimbalDead {
            return "짐벌 미연결로 판정됐습니다. 홀센서가 GP26·GP27에 물려 있는지, 3.3V가 들어오는지 확인하세요."
        }
        let dx = abs(inputMonitor.gimbalRaw.x - inputMonitor.gimbalCenter.x)
        let dy = abs(inputMonitor.gimbalRaw.y - inputMonitor.gimbalCenter.y)
        if inputMonitor.gimbalReach.x < 0.02 && inputMonitor.gimbalReach.y < 0.02 {
            if dx < 8 && dy < 8 { return "짐벌을 밀어 보세요. 아직 중립에서 안 움직였습니다." }
            return "움직임은 감지되는데 데드존을 못 넘었습니다. 데드존을 낮춰 보세요."
        }
        if inputMonitor.gimbalReach.x >= 0.85 && inputMonitor.gimbalReach.y >= 0.85 {
            return "정상 — 양축 모두 최대 출력에 도달합니다."
        }
        if inputMonitor.gimbalReach.x < 0.5 || inputMonitor.gimbalReach.y < 0.5 {
            let weak = inputMonitor.gimbalReach.x < inputMonitor.gimbalReach.y ? "X" : "Y"
            return "\(weak)축이 절반도 못 갑니다. 그 축 배선·자석 위치를 확인하거나 포화점을 낮추세요."
        }
        return "축은 살아 있지만 최대 출력에 못 닿습니다. 포화점을 낮추면 끝까지 나갑니다."
    }

    private func mappingBinding(_ key: String) -> Binding<String> {
        Binding(get: { mappings[key] ?? "NA" }, set: { mappings[key] = $0 })
    }

    // ---------------- 프리셋 (계약 규격 JSON) ----------------

    /// 현재 화면 상태를 계약의 Preset 으로 모은다.
    private var currentPreset: Contract.Preset {
        Contract.Preset(
            name: presetName,
            profileCount: profileCount,
            sensitivity: [
                "gdz": gimbalDeadzone, "tdz": thumbDeadzone,
                "gsat": gimbalSaturation, "tsat": thumbSaturation,
                "gamma": mouseGamma, "fps": fpsSpeed, "moba": mobaSpeed,
                "desk": deskSpeed, "wasd": wasdThreshold, "debounce": debounce,
            ],
            profileNames: profileNames,
            mappings: mappings)
    }

    private func apply(_ p: Contract.Preset) {
        presetName = p.name
        profileCount = min(max(p.profileCount, 1), Contract.maxProfiles)
        gimbalDeadzone = p.sensitivity["gdz"] ?? gimbalDeadzone
        thumbDeadzone = p.sensitivity["tdz"] ?? thumbDeadzone
        gimbalSaturation = p.sensitivity["gsat"] ?? gimbalSaturation
        thumbSaturation = p.sensitivity["tsat"] ?? thumbSaturation
        mouseGamma = p.sensitivity["gamma"] ?? mouseGamma
        fpsSpeed = p.sensitivity["fps"] ?? fpsSpeed
        mobaSpeed = p.sensitivity["moba"] ?? mobaSpeed
        deskSpeed = p.sensitivity["desk"] ?? deskSpeed
        wasdThreshold = p.sensitivity["wasd"] ?? wasdThreshold
        debounce = p.sensitivity["debounce"] ?? debounce
        profileNames = p.profileNames
        mappings = p.mappings
        if let i = allProfiles.firstIndex(where: { $0.tag == layoutMode }), i >= profileCount {
            layoutMode = allProfiles[max(0, profileCount - 1)].tag
        }
    }

    /// 마지막 상태를 두는 곳. 앱을 다시 켜면 여기서 복원한다.
    private static var lastSessionURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
            .appendingPathComponent("딸깍 감도 조절기", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("last-session.json")
    }

    private func autosave() {
        try? Contract.encodePreset(currentPreset)
            .write(to: Self.lastSessionURL, atomically: true, encoding: .utf8)
    }

    private func restoreLastSession() {
        guard let text = try? String(contentsOf: Self.lastSessionURL, encoding: .utf8) else { return }
        do {
            apply(try Contract.decodePreset(text))
            status = "지난번 설정을 불러왔습니다 — \(presetName)"
        } catch {
            // 형식이 바뀌었거나 깨진 경우. 기본값으로 시작하되 조용히 넘어가지 않는다.
            status = "지난 설정을 못 읽어 기본값으로 시작합니다: \(error.localizedDescription)"
        }
    }

    private func importPreset() {
        let panel = NSOpenPanel()
        panel.title = "프리셋 불러오기"
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            apply(try Contract.decodePreset(text))
            autosave()
            status = "\(presetName) 프리셋을 불러왔습니다. 다른 OS 에서 만든 파일도 그대로 열립니다."
        } catch {
            loadError = error.localizedDescription
            status = "불러오지 못했습니다."
        }
    }

    private func exportPreset() {
        let panel = NSSavePanel()
        panel.title = "프리셋 내보내기"
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = presetName.isEmpty ? "ttalkkak-preset.json"
                                                        : "\(presetName).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try Contract.encodePreset(currentPreset).write(to: url, atomically: true, encoding: .utf8)
            status = "프리셋을 내보냈습니다. Windows 설정기에서 그대로 열립니다."
        } catch {
            status = "내보내기 실패: \(error.localizedDescription)"
        }
    }

    /// 전체 초기화 — 감도·속도·키 배치·페이지 이름·페이지 개수를 전부 처음 상태로.
    private func reset() {
        gimbalDeadzone = 0.10; thumbDeadzone = 0.14; gimbalSaturation = 0.85; thumbSaturation = 0.90
        fpsSpeed = 22; mobaSpeed = 16; deskSpeed = 14; mouseGamma = 1.8; wasdThreshold = 0.38; debounce = 12
        mappings = fullDefaultMappings
        profileCount = 4
        profileNames = Dictionary(uniqueKeysWithValues: allProfiles.map { ($0.tag, $0.defaultName) })
        layoutMode = "FPS"
        presetName = "기본 설정"
        status = "전부 처음 상태로 되돌렸습니다 — 페이지 4개(FPS·MOBA·DESK·MEDIA), 권장 감도."
    }

    /// 헤더 생성은 계약(Contract.swift)이 담당한다. 앱마다 손으로 쓰면 어긋난다.
    private func headerText() -> String {
        Contract.sensitivityHeader([
            "gdz": gimbalDeadzone, "tdz": thumbDeadzone,
            "gsat": gimbalSaturation, "tsat": thumbSaturation,
            "gamma": mouseGamma, "fps": fpsSpeed, "moba": mobaSpeed,
            "desk": deskSpeed, "wasd": wasdThreshold, "debounce": debounce,
        ])
    }

    private func mappingHeaderText() -> String {
        Contract.mappingHeader(profileCount: profileCount,
                               names: profileNames,
                               mappings: mappings)
    }

    private var switchModeGuide: some View {
        GroupBox("Nintendo Switch 게임 모드") {
            VStack(alignment: .leading, spacing: 7) {
                Label("MODE 링을 2.5초 이상 누른 뒤 떼면 PC 키보드·마우스 모드와 Switch 게임패드 모드가 전환됩니다.", systemImage: "gamecontroller.fill")
                    .font(.callout)
                Text("Switch 모드에서는 하부 짐벌=왼쪽 스틱, 엄지 스틱=오른쪽 스틱이며 F1~F8·M1·M2·U1~U4가 Switch 버튼·D패드로 동작합니다. PC 프로필(FPS·MOBA·DESK·MEDIA) 설정은 Switch 모드에 영향을 주지 않습니다.")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
            }.padding(.top, 3)
        }
    }

    private func saveHeader() {
        let panel = NSOpenPanel(); panel.title = "펌웨어 ttalkkak 폴더 선택"; panel.message = "sensitivity_override.h와 mapping_override.h를 함께 저장합니다."
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try headerText().write(to: url.appendingPathComponent("sensitivity_override.h"), atomically: true, encoding: .utf8)
                try mappingHeaderText().write(to: url.appendingPathComponent("mapping_override.h"), atomically: true, encoding: .utf8)
                status = "감도와 키 배치(페이지 \(profileCount)개)를 저장했습니다. 이제 build.sh로 펌웨어를 다시 빌드해 올리세요."
            }
            catch { status = "저장 실패: \(error.localizedDescription)" }
        }
    }

    private func copyCommand() {
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString("cd '02_설계/툴/firmware' && ./build.sh diagpcf upload", forType: .string)
        didCopy = true; status = "진단+PCF 펌웨어 업로드 명령을 클립보드에 복사했습니다. PCF를 쓰지 않으면 diagpcf 대신 dev를 쓰세요."
    }
}
