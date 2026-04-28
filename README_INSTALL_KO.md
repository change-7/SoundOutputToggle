# SoundOutputToggle 설치 및 사용 안내

SoundOutputToggle은 지정한 두 개의 macOS 사운드 출력 기기를 빠르게 전환하는 앱입니다.

## DMG 안의 파일

- `SoundOutputToggle.app`
  - 실행하면 Output A와 Output B 사이를 전환한 뒤 바로 종료됩니다.
  - 상주하지 않습니다.
  - 현재 출력 기기에 맞춰 앱 아이콘의 색상과 글자가 바뀝니다.

- `SoundOutputToggle Settings.app`
  - Output A와 Output B를 설정하는 앱입니다.
  - 설정 앱은 토글 앱과 같은 위치에 있어야 토글 앱 아이콘을 함께 갱신할 수 있습니다.

## 설치 방법

DMG 안의 두 앱을 모두 `/Applications` 폴더로 옮기세요.

```text
SoundOutputToggle.app
SoundOutputToggle Settings.app
```

두 앱을 같은 `/Applications` 폴더에 함께 설치하는 것을 권장합니다.

## 처음 설정

1. `/Applications/SoundOutputToggle Settings.app`을 실행합니다.
2. `Output A`와 `Output B`에 전환할 사운드 출력 기기를 선택합니다.
3. 필요하면 `Also switch system alert sounds`를 켭니다.
4. 설정 앱을 닫습니다.

## 권장 사용법

Alfred를 이미 사용 중이라면 Alfred Hotkey에 토글 앱을 연결하는 방식을 권장합니다.

Alfred Workflow 예:

```bash
open -na "/Applications/SoundOutputToggle.app"
```

이 방식은 다음 장점이 있습니다.

- SoundOutputToggle이 상주하지 않습니다.
- Alfred가 단축키를 감지합니다.
- SoundOutputToggle은 실행 순간에만 출력 전환 후 종료됩니다.
- Spotlight, Raycast, Finder에서 직접 실행하는 방식도 계속 사용할 수 있습니다.

## Alfred 연결 방법

1. Alfred Preferences를 엽니다.
2. `Workflows`로 이동합니다.
3. 새 Blank Workflow를 만듭니다.
4. `Triggers > Hotkey`를 추가하고 원하는 단축키를 지정합니다.
5. `Actions > Run Script`를 추가합니다.
6. Script에 아래 명령을 넣습니다.

```bash
open -na "/Applications/SoundOutputToggle.app"
```

7. Hotkey Trigger와 Run Script Action을 연결합니다.

## Raycast 연결 방법

Raycast를 사용 중이라면 Raycast Hotkey로 토글 앱을 실행하는 방식을 권장합니다.

권장 방식은 Raycast의 `Create Quicklink` 또는 Script Command를 쓰는 것입니다.

### Quicklink 방식

1. Raycast를 엽니다.
2. `Create Quicklink`를 실행합니다.
3. Name을 `Toggle Sound Output`처럼 지정합니다.
4. Link에는 아래 값을 넣습니다.

```text
file:///Applications/SoundOutputToggle.app
```

5. Quicklink를 저장합니다.
6. Raycast Settings에서 해당 Quicklink에 Hotkey를 지정합니다.

### Script Command 방식

Raycast Script Commands를 쓰고 있다면 아래 스크립트를 등록해도 됩니다.

```bash
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Sound Output
# @raycast.mode silent
#
# Optional parameters:
# @raycast.icon 🔊

open -na "/Applications/SoundOutputToggle.app"
```

Script Command 방식은 실행 동작이 가장 명확해서, Raycast를 자주 쓴다면 이 방식을 추천합니다.

## macOS 단축어 연결 방법

macOS Shortcuts 앱을 통해서도 연결할 수 있습니다.

1. `단축어` 앱을 엽니다.
2. 새 단축어를 만듭니다.
3. 동작에서 `쉘 스크립트 실행`을 추가합니다.
4. 스크립트에 아래 명령을 넣습니다.

```bash
open -na "/Applications/SoundOutputToggle.app"
```

5. 단축어 이름을 `Sound Output Toggle`처럼 지정합니다.
6. 필요하면 단축어 설정에서 키보드 단축키를 지정합니다.
7. macOS 단축어 위젯에 이 단축어를 추가해도 됩니다.

단축어 위젯은 토글 버튼으로 쓰기에는 좋지만, 위젯 타일 자체가 현재 출력 기기 이름으로 실시간 변경되지는 않습니다.

## 가장 추천하는 연결 방식

이미 Alfred나 Raycast를 상시 사용 중이라면:

```text
Alfred/Raycast Hotkey
→ open -na "/Applications/SoundOutputToggle.app"
→ 출력 전환
→ 앱 종료
```

이 방식이 가장 가볍고 안정적입니다.

macOS 기본 기능만 쓰고 싶다면:

```text
Shortcuts
→ 쉘 스크립트 실행
→ open -na "/Applications/SoundOutputToggle.app"
```

을 추천합니다.

## 아이콘 표시 참고

`SoundOutputToggle.app` 아이콘은 현재 출력 기기의 앞 글자와 색상으로 갱신됩니다.

다만 Dock에 고정된 아이콘은 macOS Dock 캐시 때문에 즉시 바뀌지 않을 수 있습니다. 상태 확인용으로는 Finder, Spotlight, Alfred, Raycast 쪽 표시가 더 적합합니다.
