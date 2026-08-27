# 설정 계약 (Task 1)

`settings-contract.json` **하나가 진실**이다. 앱 소스에 액션 목록·프로필·기본 배치를 손으로 적지 않는다.

2026-08-28 이전에는 세 곳이 전부 달랐다 — macOS 액션 70개, Windows 8개, 계약 16개.
Windows 는 9프로필 확장도 모르고 있었고, 두 앱의 `mapping_override.h` 형식 자체가 달랐다.

## 구조

```
settings-contract.json          ← 여기만 고친다
        │  python3 generate.py
        ├─ generated/Contract.swift   → macOS 앱이 컴파일
        ├─ generated/Contract.cs      → Windows 앱이 컴파일
        └─ fixtures/golden/*.h        → 두 앱이 내야 할 정답 헤더
```

**헤더 생성 함수까지 계약에서 만든다.** 앱마다 손으로 쓰면 반드시 어긋나서,
`Contract.sensitivityHeader()` · `Contract.mappingHeader()` 를 양쪽 언어로 생성한다.

## 쓰는 법

```sh
python3 contract/generate.py          # 계약을 고친 뒤 반드시 실행
python3 contract/generate.py --check  # 생성물이 최신인지만 확인
python3 contract/verify_fixture.py    # 전체 검증
```

`build_app.sh`(macOS)와 `build_windows.ps1`(Windows) 이 빌드 전에 `--check` 를 돌린다.
계약만 고치고 생성을 안 하면 **빌드가 막힌다.**

## 검증 항목

| 단계 | 내용 |
|---|---|
| 1 | 계약 정합성 — 매크로/라벨 중복, 비트 0~15, 보호 버튼, 감도 기본값 범위 |
| 2 | `generated/` 와 골든이 계약과 최신인지 |
| 3 | **Swift 구현이 골든과 byte-for-byte 같은지** (실제 컴파일·실행) |
| 4 | **C# 구현이 골든과 byte-for-byte 같은지** (dotnet 필요) |
| 5 | 골든 헤더가 펌웨어에서 실제로 컴파일되는지 (arduino-cli) |

> ⚠ **4번은 macOS 개발 머신에 dotnet 이 없어 아직 미검증이다.**
> Windows 에서 `python3 contract/verify_fixture.py` 를 한 번 돌려야 OS 동등성이 증명된다.
> 그 전까지 "두 OS 가 같은 헤더를 낸다" 는 **설계상 그렇게 만들었을 뿐 확인된 사실이 아니다.**

## 계약이 잡아낸 것

- `새로 고침`(`K(HID_KEY_F5)`)과 `F5` 가 같은 매크로 → 매크로가 곧 id 라 Picker 가 깨진다.
  중복 검사가 생성 단계에서 막았다.
