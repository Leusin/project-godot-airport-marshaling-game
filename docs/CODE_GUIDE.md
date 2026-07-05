# 코드 읽기 가이드

이 프로젝트 코드를 처음 읽는 사람을 위한 안내. 전체 20개 스크립트 / 약 800줄로 작으니
**데이터 흐름 순서**로 읽으면 30분이면 파악된다.

> 각 스크립트 맨 위 `##` 주석에 "무엇을 담당하고 무엇을 안 하는지"가 적혀 있다. 그것부터 읽자.

## 큰 그림

탑다운 3D 공항 마샬링 시뮬레이션. 마샬러(플레이어)가 수신호로 비행기를 주차 지점까지 유도한다.

핵심 데이터 흐름 한 줄 요약:

```
입력(키) → 신호 타입 → [시야 판정 + FSM 해석] → 비행기 명령 → 물리 이동 → 충돌/도착 판정 → HUD
```

전체 씬 계층·연결은 다이어그램 참고: [docs/scene_diagram.svg](scene_diagram.svg)

## 읽는 순서 (권장)

흐름을 따라가면 자연스럽게 이해된다. 위에서부터 순서대로:

| # | 파일 | 한 줄 책임 |
|---|---|---|
| 1 | `src/core/main_game/Main.tscn` | 씬 골격. 노드 계층/그룹/Process Mode를 눈으로 파악 |
| 2 | `src/gameplay/marshaller/move_input.gd` | WASD → XZ 방향 벡터 (가장 단순, 상태 없음) |
| 3 | `src/gameplay/marshaller/signal_input.gd` | 방향키 → 수신호 타입(enum) 변환만 |
| 4 | `src/gameplay/aircraft/aircraft_vision_cone.gd` | 정면 70° 시야 판정, bool만 반환 (상태 없는 기하) |
| 5 | **`src/gameplay/aircraft/aircraft_fsm.gd`** | **게임의 두뇌.** 신호+시야를 해석해 상태 전이(IDLE/MOVING/HESITATING/STOPPING) |
| 6 | `src/gameplay/aircraft/aircraft.gd` | 명령 → 딜레이/관성 물리 이동 (해석은 안 함) |
| 7 | `src/gameplay/aircraft/aircraft_collision.gd` | XZ 거리로 마샬러/장애물/주차 근접 판정 |
| 8 | `src/core/main_game/game_manager.gd` | 게임오버/성공 처리 + 재시작 |
| 9 | `src/ui/*.gd` | HUD (신호 표시 / 게임오버 / 성공 오버레이) |
| 10 | `src/core/utils/*.gd` | 공유 유틸 (아래 "핵심 패턴" 참고) |
| 11 | `src/debug/*.gd` | 디버그 전용 (시야 시각화, FPS/버전, 프로젝트 설정) |

**5번 `aircraft_fsm.gd`가 제일 중요하다.** 여기만 이해하면 게임 규칙의 대부분을 안다:
- `NONE`(무신호): 이동 중이면 잠깐 멈칫 후 정지
- `STOP`(정지 신호): 즉시 정지 시작
- 시야 밖: 유도자를 놓친 것이므로 지체 없이 정지 (멈칫 없음)

## 폴더 지도

```
src/
  core/
    main_game/   Main.tscn, game_manager.gd      게임 진입/진행 관리
    utils/       screen_bounds, screen_clamp,    여러 노드가 공유하는 재사용 로직
                 scene_query
  gameplay/
    aircraft/    aircraft, aircraft_fsm,          비행기: 물리 / 해석 / 시야 / 충돌
                 aircraft_vision_cone, aircraft_collision
    marshaller/  marshaller_controller,           마샬러: 이동 / 입력 / 수신호
                 move_input, signal_input
  ui/            signal_indicator, game_over,      HUD (코드로 직접 그림, 텍스처 없음)
                 success
  debug/         vision_cone_debug_visual,         개발 전용 (게임플레이 미관여)
                 debug_hud, apply_project_settings
tests/           단위 테스트 (자체 경량 하네스)
```

## 핵심 패턴 (이걸 알면 코드가 빨리 읽힌다)

### 1. 컴포넌트 합성
큰 스크립트 하나가 다 하지 않고, 작은 노드로 쪼개 붙인다.
- 마샬러 = `MarshallerController`(이동) + `MoveInput`(입력) + `SignalInput`(수신호) + `ScreenClamp`(경계)
- 각 조각은 한 가지만 한다. 스크립트 상단 주석이 그 경계를 못박아 둔다.

### 2. 그룹 기반 참조 (계층 경로 X)
노드끼리 `get_parent().get_parent()...` 같은 경로로 찾지 않고 **그룹**으로 찾는다.
씬 트리 어디로 옮겨도 안 깨진다. 조회는 `src/core/utils/scene_query.gd`의
`get_singleton()`으로 통일 — 없으면 경고+null, 2개 이상이면 경고(싱글턴 가정을 드러냄).
- 그룹: `marshaller`, `signal_input`, `game_manager`, `game_over_hud`, `success_hud`, `obstacle`, `parking`

### 3. 공유 유틸
- `screen_bounds.gd` — 탑다운 카메라의 가시 영역(절반 크기) 계산 (순수 함수)
- `screen_clamp.gd` — 부모 Node3D를 그 영역 안으로 클램프하는 컴포넌트 (마샬러/비행기가 공유)
- `scene_query.gd` — 위 그룹 조회 유틸

### 4. 씬 계층 = 레이어
`MainGame` 아래 `World`(Pausable) / `HudLayer`(10) / `PauseLayer`(20) /
`TransitionLayer`(100) / `DebugLayer`(128). 게임오버 시 `World`만 멈추고
오버레이는 `Process Mode = Always`라 계속 동작한다. (다이어그램에 뱃지로 표시됨)

### 5. "하는 것 / 안 하는 것" 경계
입력은 변환만, 시야는 판정만, 비행기는 물리만, FSM만 해석한다. 각 파일 주석이
"~만 한다 / 판정은 안 한다" 식으로 책임 경계를 명시한다. 이 경계가 곧 설계다.

## 실행 방법

- **게임 실행**: 에디터에서 F5 (메인 씬 = `Main.tscn`)
- **테스트 실행**:
  - 에디터에서 `tests/tests.tscn` 열고 **F6** → 화면에 색상 리포트 표시
  - 또는 터미널에서 `./run_tests.ps1` (헤드리스, 실패 수를 종료 코드로 반환)

## 함께 볼 문서

- [README.md](../README.md) — 개요 / 설계 / 로드맵 / 씬 계층 트리
- [DEVLOG.md](../DEVLOG.md) — 진행·결정·에러 로그 (왜 이렇게 짰는지 배경)
- [docs/scene_diagram.svg](scene_diagram.svg) — 씬 계층 다이어그램
