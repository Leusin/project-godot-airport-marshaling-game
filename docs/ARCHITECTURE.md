# 아키텍처

프로젝트 구조와 주요 컴포넌트를 설명하는 문서입니다.

코드를 읽는 순서는 [CODE_GUIDE.md](CODE_GUIDE.md) 참고.

## 폴더 구조

```text
project.godot
assets/                     아트, 사운드, 폰트 등 게임 에셋
src/
  core/
    main_game/              메인 씬 + 게임 진행 관리 (Main.tscn, game_manager.gd)
    utils/                  여러 노드가 공유하는 재사용 스크립트 (scene_query.gd, collision_2d.gd 등)
  gameplay/
    input/                  입력 전담 (이동키/수신호 → 값 변환, 특정 엔티티 비의존)
    aircraft/               비행기 로직 (설정·명령/이동/FSM/시야/충돌)
    marshaller/             마샬러 로직 (설정/이동/스프라이트)
  ui/                       HUD (수신호 표시, 게임오버, 성공)
  debug/                    개발/디버그 도구 (시야 시각화, FPS/버전 HUD, 프로젝트 설정)
tests/                      단위 테스트 (자체 경량 하네스, 애드온 없음)
docs/                       문서, 다이어그램
```

## 씬 계층 구조

![씬 구조 다이어그램](attachment/scene_diagram.svg)

```text
MainGame (Node)                  앱 루트. Process Mode = Always
├─ Systems                       상위 시스템 (게임 진행 · 입력 · 컨트롤러)
│  ├─ GameManager                판정 + 재시작  [group: game_manager]
│  ├─ Input                      디바이스 입력 (이벤트 기반)
│  │  ├─ MovementInput           [group: movement_input]
│  │  └─ SignalInput             [group: signal_input]
│  └─ PlayerController           Marshaller possess → 이동 의도 push
├─ World (Node3D)                게임 세계. Process Mode = Pausable
│  ├─ TopDownCamera              직교 탑다운 카메라
│  ├─ LevelRoot                  배경 요소
│  │  ├─ Ground
│  │  ├─ Obstacle                [group: obstacle]
│  │  └─ ParkingSpot             [group: parking]
│  ├─ EntityRoot                 핵심 요소
│  │  ├─ Marshaller              [group: marshaller]  (Pawn)
│  │  │  ├─ MarshallerSprite
│  │  │  └─ MarshallerMovement    이동 실행 (Pawn 의도만 읽음)
│  │  └─ Aircraft                [group: aircraft]
│  │     ├─ AircraftModel
│  │     ├─ AircraftMovement      이동 실행 (명령=FSM 결정)
│  │     ├─ VisionCone / VisionConeVisual
│  │     ├─ AircraftFSM           [group: aircraft_fsm]  Aircraft가 받은 신호로 상태 전이
│  │     └─ AircraftHitbox
│  └─ EffectRoot                 임시 시각 효과 (향후)
├─ HudLayer (layer 10, Pausable) └─ HudRoot
│     ├─ SignalIndicator
│     ├─ GameOverHUD             [group: game_over_hud]
│     └─ SuccessHUD              [group: success_hud]
├─ PauseLayer (layer 20, Always)      └─ PauseRoot        (향후)
├─ TransitionLayer (layer 100, Always) └─ TransitionRoot  (향후)
└─ DebugLayer (layer 128, Always)     └─ DebugRoot        (향후)
```

- 각 `*Root` Control 은 `mouse_filter = Ignore`.
- 노드 간 참조는 계층 경로가 아니라 **그룹**으로 찾아 트리 위치에 독립적이다 (`get_tree().get_first_node_in_group(...)`).

## 주요 구성

**마샬러 (Controller/Pawn 분리 — 언리얼 possess 모델)**
- `Marshaller` — Pawn. 설정(speed) + 명령받은 상태(이동 의도 `move_intent`, 수신호 `hand_signal`)만 보유하고 입력은 전혀 모른다. 상태가 바뀌면 각각 `move_intent_changed` / `hand_signal_changed` 방출
- `MarshallerMovement` — 이동 실행(MovementComponent). Pawn의 `move_intent` × speed로 부모를 이동. 의도가 0이 아닐 때만 물리처리(이벤트 게이팅)
- `MarshallerSprite` — 시각화. Pawn의 `hand_signal`(+ GameManager의 확정 유예)을 읽어 텍스처를 바꾼다. 입력(SignalInput)을 직접 보지 않음
- `PlayerController` — Marshaller를 possess(그룹 조회). `MovementInput`/`SignalInput`의 시그널을 받아 Pawn의 `set_move_intent()`/`set_hand_signal()`로 push. 이 노드만 AI 컨트롤러로 갈아끼우면 같은 Pawn을 코드가 조종 (씬에서는 `Systems` 아래)

**입력** (`gameplay/input/`, 씬에서는 `Systems/Input` 아래 · 특정 엔티티 비의존 · 이벤트 기반 · 디바이스 계층)
- `MovementInput` — 이동 입력 전담. `_unhandled_input`으로 방향을 재계산해 바뀔 때 `move_direction_changed` 방출(캐시 `move_direction`도 유지) [group: movement_input]
- `SignalInput` — 수신호 입력 전담. `_unhandled_input`으로 현재 신호를 상태로 보관(`get_signal()`은 캐시 반환)하고 바뀔 때 `hand_signal_changed` 방출. 엔진정지 확정은 단발 `shutdown_confirmed` 시그널.
  모두 hold-to-move. 키를 떼면 NONE(무신호) — NONE과 STOP은 별개 값. 이동 신호 판별(`is_move_signal`) 제공

**비행기 (Controller/Pawn — brain은 FSM)**
- `Aircraft` — Pawn. 설정·명령 루트. 자기 시야로 **마샬러를 관찰해 "받은 수신호"**(`received_signal()`/`sees_marshaller()`, 시야 밖이면 NONE)를 제공하고, 수신호를 내부 명령(Command)으로 번역(`issue_signal`)해 딜레이(반응 지연)를 해소. 이동/시야/충돌 컴포넌트를 붙인다
- `AircraftMovement` — 이동 실행(MovementComponent). 명령(=FSM이 결정한 것)/설정을 읽어 속도 관성 + 회전 + 전진을 부모에 반영
- `AircraftVisionCone` — 정면 기준 70도 원뿔 판정, 마샬러가 원뿔 안에 있는지 bool만 반환 (Aircraft가 `sees_marshaller`에서 사용)
- `AircraftFSM` — 비행기의 brain. **Aircraft가 받은 신호 + 시야를 읽어**(SignalInput을 직접 보지 않음) IDLE/MOVING/HESITATING/STOPPING 상태 전이 후 Aircraft에 명령 전달(`issue_signal`). 무신호는 멈칫 후 정지, STOP은 즉시 정지, 시야 밖은 즉시 정지
- `AircraftCollision` — XZ 거리 기반으로 마샬러/장애물/주차지점 근접 판정 -> GameManager 통지

**UI**
- `SignalIndicatorHUD` — 마샬러가 현재 입력 중인 수신호를 화면에 아이콘으로 표시 (텍스처 없이 코드로 그림)

**공유/판정**
- `Obstacle` / `ParkingSpot` — 그룹(obstacle/parking)만 붙은 위치 마커. AircraftCollision이 거리로 판정
- `GameManager` — 게임오버(비행기-장애물/사람) / A->B 도착 성공 처리 + 재시작
- `SceneQuery` / `Collision2D` / `CollisionShapes` / `Countdown` — 공용 유틸 (그룹 단일 조회 `require_single` / OBB 겹침 SAT / 메쉬 AABB 반크기 / 프레임 카운트다운). `ScreenBounds`는 현재 테스트에서만 사용

## 더 볼 것

- 테스트 하네스와 실행 방법 → [TESTING.md](TESTING.md)
