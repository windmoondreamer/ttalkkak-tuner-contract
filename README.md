# 딸깍 설정기 — 설정 계약

macOS(SwiftUI)와 Windows(WinForms) 설정기가 **같은 펌웨어 헤더를 내도록** 보장하는 저장소다.
본체 프로젝트(`ttalkkak-assistive-input`)에서 이 부분만 떼어 냈다.

## 왜 떼어 냈나

`Task 1`(단일 설정 계약)의 마지막 한 칸이 **macOS 개발 머신에 dotnet 이 없어서** 막혀 있었다.
C# 구현이 골든 헤더와 같은 결과를 내는지 확인할 방법이 없었고,
그 상태로 다음 작업(JSON 프리셋·검증·레이아웃 편집기)을 쌓으면 미검증 부채가 늘어난다.

**GitHub Actions 의 `windows-latest` 러너가 그 칸을 채운다.** Windows PC 가 없어도 push 하면 검증된다.

## 구조

```
settings-contract.json          ← 여기만 고친다
        │  python3 contract/generate.py
        ├─ contract/generated/Contract.swift   → macOS 앱이 컴파일
        ├─ contract/generated/Contract.cs      → Windows 앱이 컴파일
        └─ contract/fixtures/golden/*.h        → 두 앱이 내야 할 정답 헤더
```

액션 목록·프로필·기본 배치뿐 아니라 **헤더 생성 함수 자체를 계약에서 생성한다.**
목록만 공유하고 헤더 조립을 앱마다 손으로 쓰면 반드시 어긋나기 때문이다.

## 쓰는 법

```sh
python3 contract/generate.py          # 계약을 고친 뒤 반드시 실행
python3 contract/generate.py --check  # 생성물이 최신인지만 확인
python3 contract/verify_fixture.py    # 전체 검증
```

빌드 스크립트가 빌드 전에 `--check` 를 돌린다. **계약만 고치고 생성을 안 하면 빌드가 막힌다.**

### Windows

```powershell
python contract/verify_fixture.py
.\windows\build_windows.ps1
```

### macOS

```sh
cd macos && ./build_app.sh
```

## 검증 항목

| 단계 | 내용 | 이 저장소 단독 |
|---|---|---|
| 1 | 계약 정합성 — 매크로/라벨 중복, 비트 0~15, 보호 버튼, 감도 범위 | ✅ |
| 2 | `generated/` 와 골든이 계약과 최신인지 | ✅ |
| 3 | Swift 구현이 골든과 byte-for-byte 같은지 | ✅ (swiftc 필요) |
| 4 | C# 구현이 골든과 byte-for-byte 같은지 | ✅ (dotnet 필요) |
| 5 | 골든 헤더가 펌웨어에서 컴파일되는지 | ⏭ 펌웨어 트리가 없어 건너뜀 |

5번은 본체 저장소에서 `arduino-cli` 로 확인한다. 2026-08-28 기준 통과.

## 본체 저장소와의 관계

계약과 생성물의 **정본은 이 저장소**다. 본체(`02_설계/툴/감도조절기/`)에 같은 파일이 있으며
당분간은 손으로 맞춘다. 한쪽만 고치면 갈라지므로, 계약을 바꿀 때는 양쪽에 반영할 것.

## 계약이 잡아낸 것

- `새로 고침`(`K(HID_KEY_F5)`)과 `F5` 가 같은 매크로 → 매크로가 곧 `Identifiable` 의 id 라
  SwiftUI Picker 가 깨진다. 중복 검사가 생성 단계에서 막았다.
- 도입 직전 상태: macOS 액션 70개 · Windows 8개 · 계약 16개로 셋 다 달랐고,
  Windows 는 9프로필 확장을 몰라 4프로필 헤더를 내고 있었다.
