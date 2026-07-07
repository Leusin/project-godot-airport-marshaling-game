# 아키텍처

폴더 구조 · 씬 계층 · 주요 구성 · 테스트. 코드를 읽는 순서는 [CODE_GUIDE.md](CODE_GUIDE.md)를 먼저 본다.

## 폴더 구조

```text
project.godot
assets/                     아트, 사운드, 폰트 등 게임 에셋
src/
  core/
    main_game/              메인 씬 + 게임 진행 관리 (Main.tscn, game_manager.gd)
    utils/                  여러 노드가 공유하는 재사용 스크립트 (screen_bounds.gd)
  gameplay/
    aircraft/               비행기 로직 (이동/FSM/시야/충돌)
    marshaller/             마샬러 로직 (이동/입력/수신호)
  ui/                       HUD (수신호 표시, 게임오버, 성공)
  debug/                    개발/디버그 도구 (시야 시각화, FPS/버전 HUD, 프로젝트 설정)
tests/                      단위 테스트 (자체 경량 하네스, 애드온 없음)
docs/                       문서, 다이어그램
```

## 씬 계층 구조

![씬 구조 다이어그램](attachment/scene_diagram.svg)

```text
MainGame (Node)                  앱 루트. Process Mode = Always
├─ Systems                       상위 시스템 (초기화/전환/게임 진행)
│  └─ GameManager                판정 + 재시작  [group: game_manager]
├─ World (Node3D)                게임 세계. Process Mode = Pausable
│  ├─ TopDownCamera              직교 탑다운 카메라
│  ├─ LevelRoot                  배경 요소
│  │  ├─ Ground
│  │  ├─ Obstacle                [group: obstacle]
│  │  └─ ParkingSpot             [group: parking]
│  ├─ EntityRoot                 핵심 요소
│  │  ├─ Marshaller              [group: marshaller]
│  │  │  ├─ MoveInput / SignalInput [group: signal_input]
│  │  │  └─ MarshallerMesh
│  │  └─ Aircraft
│  │     ├─ AircraftMesh / NoseMarker
│  │     ├─ VisionCone / VisionConeVisual
│  │     ├─ AircraftFSM
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

**마샬러**
- `MarshallerController` — 이동만 담당 (WASD)
- `MoveInput` — 이동 입력 전담
- `SignalInput` — 수신호 입력 전담. 방향키 -> 신호 타입(전진/정지/좌우회전) 변환만, 판정은 안 함.
  모두 hold-to-move. 키를 떼면 NONE(무신호) — NONE과 STOP은 별개 값
- `ScreenClamp` — (공용 컴포넌트) 부모를 화면 경계 안으로 클램프. 마샬러/비행기가 공유

**비행기**
- `Aircraft` — 위치/속도/회전, 딜레이+관성 이동 로직
- `AircraftVisionCone` — 정면 기준 70도 원뿔 판정, 마샬러가 원뿔 안에 있는지 bool만 반환
- `AircraftFSM` — IDLE/MOVING/HESITATING/STOPPING 전이. 신호 + 시야 판정을 함께 받아 Aircraft에 명령 전달. 무신호는 멈칫 후 정지, STOP은 즉시 정지
- `AircraftCollision` — XZ 거리 기반으로 마샬러/장애물/주차지점 근접 판정 -> GameManager 통지

**UI**
- `SignalIndicatorHUD` — 마샬러가 현재 입력 중인 수신호를 화면에 아이콘으로 표시 (텍스처 없이 코드로 그림)

**공유/판정**
- `Obstacle` / `ParkingSpot` — 그룹(obstacle/parking)만 붙은 위치 마커. AircraftCollision이 거리로 판정
- `GameManager` — 게임오버(비행기-장애물/사람) / A->B 도착 성공 처리 + 재시작
- `ScreenBounds` / `ScreenClamp` / `SceneQuery` — 공용 유틸 (경계 계산 / 경계 클램프 / 그룹 단일 조회)

## 테스트

외부 애드온 없이 도는 경량 자체 하네스. `tests/tests.tscn` 을 실행하면 모든 테스트를 돌리고
통과/실패를 출력한 뒤 실패 개수를 종료 코드로 반환한다 (CI 연동 가능).

```powershell
# Windows: 헬퍼 스크립트 권장 (GUI 빌드는 콘솔에 로그가 안 붙어 리다이렉트가 필요함)
./run_tests.ps1
```

```bash
# 그 외 / 직접 실행 (콘솔 빌드거나 stdout이 보이는 환경)
godot --headless --path . res://tests/tests.tscn
```

> Windows Godot 에디터 실행 파일은 GUI 프로그램이라 대화형 콘솔에 직접 실행하면 `print` 로그가 보이지 않는다.
> `run_tests.ps1` 은 `Start-Process -RedirectStandardOutput` 으로 stdout을 받아 다시 출력한다.

- `screen_bounds` — 카메라 가시 영역 계산 (순수 함수)
- `aircraft_vision_cone` — 시야 원뿔 각도/반경 판정 (상태 없는 기하)
- `aircraft_fsm` — 신호 해석 상태 전이 (페이크 비행기/시야/수신호로 구동)
