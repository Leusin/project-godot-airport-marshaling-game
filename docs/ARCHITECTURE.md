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
    utils/                  여러 노드가 공유하는 재사용 스크립트 (scene_query.gd, countdown.gd 등)
  gameplay/
    hand_signal.gd          수신호 도메인 (SignalType/is_move_signal, 입력·Pawn·표시·FSM 공유)
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
│  │  ├─ Obstacle → ObstacleArea (Area3D, layer=hazard)
│  │  └─ ParkingSpot → ParkingArea (Area3D, layer=parking)
│  ├─ EntityRoot                 핵심 요소
│  │  ├─ Marshaller              [group: marshaller]  (Pawn)
│  │  │  ├─ MarshallerSprite
│  │  │  └─ MarshallerArea        (Area3D, layer=hazard, 원기둥)
│  │  └─ Aircraft                (Pawn)
│  │     ├─ AircraftModel
│  │     ├─ VisionCone / VisionConeVisual
│  │     └─ AircraftHitbox        (Area3D, monitoring, AircraftCollision) → CollisionShape3D
│  └─ EffectRoot                 임시 시각 효과 (향후)
   ※ 이동/FSM은 씬 노드가 아니라 RefCounted 헬퍼 — 소유 엔티티가 코드로 들고 구동한다:
     Marshaller → MarshallerMovement / Aircraft → AircraftFSM · AircraftMovement
├─ HudLayer (layer 10, Pausable) └─ HudRoot
│     ├─ SignalIndicator
│     ├─ GameOverHUD             [group: game_over_hud]
│     └─ SuccessHUD              [group: success_hud]
├─ PauseLayer (layer 20, Always)      └─ PauseRoot        (향후)
├─ TransitionLayer (layer 100, Always) └─ TransitionRoot  (향후)
└─ DebugLayer (layer 128, Always)     └─ DebugRoot        (향후)
```

- 각 `*Root` Control 은 `mouse_filter = Ignore`.
- 노드 간 참조: 싱글턴 시스템/엔티티는 **그룹 조회**(`SceneQuery.require_single`), 부모-자식은 직접 참조(`get_parent_node_3d()` 등), 유틸/도메인/헬퍼는 `class_name` 전역으로 찾는다.

## 주요 구성

**마샬러 (Controller/Pawn 분리 — 언리얼 possess 모델)**
- `Marshaller` — Pawn(Node3D). 설정(speed) + 명령받은 상태(이동 의도 `move_intent`, 수신호 `hand_signal`)만 보유하고 입력은 전혀 모른다. `MarshallerMovement` 헬퍼를 코드로 들고 `_process`에서 이동을 적용한다
- `MarshallerMovement` — 이동 실행 헬퍼(RefCounted, 씬 노드 아님). 순수 함수 `update(body, direction, speed, delta)`로 위치를 갱신. 상태 없음
- `MarshallerSprite` — 시각화. 부모 Marshaller(`get_parent_node_3d()`)의 `hand_signal`(+ GameManager의 확정 유예)을 읽어 텍스처를 바꾼다. 입력(SignalInput)을 직접 보지 않음
- `PlayerController` — Marshaller를 possess(그룹 조회). `MovementInput`/`SignalInput`의 시그널을 받아 Pawn의 `set_move_intent()`/`set_hand_signal()`로 push. 이 노드만 AI 컨트롤러로 갈아끼우면 같은 Pawn을 코드가 조종 (씬에서는 `Systems` 아래)

**신호 도메인**
- `HandSignal` (`gameplay/hand_signal.gd`) — 수신호 어휘. `enum SignalType`(NONE/ADVANCE/STOP/TURN_LEFT/TURN_RIGHT)과 성질 판별(`is_move_signal`)만 정의. 입력 장치가 아니라 신호 자체의 것이라, 입력(SignalInput)·Pawn(Marshaller/Aircraft)·표시(HUD/Sprite)·판단(FSM)이 모두 이걸 공유한다 (게임플레이 로직이 입력 스크립트에 의존하지 않도록 분리)

**입력** (`gameplay/input/`, 씬에서는 `Systems/Input` 아래 · 특정 엔티티 비의존 · 이벤트 기반 · 디바이스 계층)
- `MovementInput` — 이동 입력 전담. `_unhandled_input`으로 방향을 재계산해 바뀔 때 `move_direction_changed` 방출(캐시 `move_direction`도 유지) [group: movement_input]
- `SignalInput` — 수신호 입력 전담. `_unhandled_input`으로 현재 신호(`HandSignal.SignalType`)를 상태로 보관(`get_signal()`은 캐시 반환)하고 바뀔 때 `hand_signal_changed` 방출. 엔진정지 확정은 단발 `shutdown_confirmed` 시그널.
  모두 hold-to-move. 키를 떼면 NONE(무신호) — NONE과 STOP은 별개 값

**비행기 (Controller/Pawn — brain은 FSM)**
- `Aircraft` — Pawn(Node3D). 설정 루트. 자기 시야로 마샬러를 관찰해 "받은 수신호"(`_received_signal()`/`_sees_marshaller()`, 시야 밖이면 NONE)를 구하고, `AircraftFSM`·`AircraftMovement` 헬퍼를 코드로 들고 구동한다: `_process`에서 FSM 갱신 + FSM 출력(forward/turn)이 바뀌면 `command_delay`(반응 지연) 뒤 적용, `_physics_process`에서 이동 실행
- `AircraftFSM` — 비행기의 brain(RefCounted, 씬 노드 아님). `update(in_view, received_signal, speed, delta)`로 IDLE/MOVING/HESITATING/STOPPING 상태를 전이하고, `forward()`/`turn()`으로 이동 의도를 노출. SignalInput을 직접 보지 않는다. 무신호는 멈칫(`hesitate_duration`) 후 정지, STOP은 즉시 정지, 시야 밖은 즉시 정지
- `AircraftMovement` — 이동 실행 헬퍼(RefCounted, 씬 노드 아님). `update(body, forward, turn, max_speed, accel, decel, turn_speed, delta)`로 속도 관성 + 회전 + 전진을 body에 반영. 현재 속도만 상태로 보유
- `AircraftVisionCone` — 정면 기준 70도 원뿔 판정, 마샬러가 원뿔 안에 있는지 bool만 반환 (Aircraft가 `_sees_marshaller`에서 사용)
- `AircraftCollision` — 비행기 `AircraftHitbox`(Area3D) 스크립트. Godot Area3D 겹침으로 판정: hazard 레이어(장애물·마샬러) 진입 → 게임오버, parking 레이어는 겹치는 동안 비행기 AABB가 주차존 AABB에 완전히 포함되면(AABB.encloses) 확정 대기 → GameManager 통지. 모든 콜리전 도형을 Y로 길게 만들어 실질 XZ 판정

**UI**
- `SignalIndicatorHUD` — 마샬러가 현재 입력 중인 수신호를 화면에 아이콘으로 표시 (텍스처 없이 코드로 그림)

**공유/판정**
- `Obstacle` / `ParkingSpot` — 위치 마커. 자식 `Area3D`+`CollisionShape3D`로 충돌 레이어(hazard/parking)를 부여, AircraftHitbox가 감지
- `GameManager` — 게임오버(비행기-장애물/사람) / A->B 도착 성공 처리 + 재시작
- `SceneQuery` / `Countdown` — 공용 유틸 (그룹 단일 조회 `require_single` / 프레임 카운트다운). 충돌은 Godot Area3D로 이관해 커스텀 `Collision2D`/`CollisionShapes`/`ScreenBounds` 제거

## 더 볼 것

- 테스트 하네스와 실행 방법 → [TESTING.md](TESTING.md)
