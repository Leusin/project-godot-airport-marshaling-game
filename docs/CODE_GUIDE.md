# 코드 읽기 가이드

20개 스크립트 / 약 800줄. **데이터 흐름 순서**로 읽으면 빠르다.
각 스크립트 맨 위 `##` 주석이 "무엇을 하고 무엇을 안 하는지" 알려주니 그것부터 보자.

```
입력(키) → 신호 타입 → [시야 판정 + FSM 해석] → 비행기 명령 → 물리 이동 → 충돌/도착 판정 → HUD
```

## 읽는 순서

| # | 파일 | 책임 |
|---|---|---|
| 1 | `core/main_game/Main.tscn` | 씬 골격 — 노드 계층/그룹/Process Mode를 눈으로 |
| 2 | `gameplay/marshaller/move_input.gd` | WASD → 방향 벡터 |
| 3 | `gameplay/marshaller/signal_input.gd` | 방향키 → 수신호 타입 |
| 4 | `gameplay/aircraft/aircraft_vision_cone.gd` | 정면 70° 시야 판정 (bool만) |
| 5 | **`gameplay/aircraft/aircraft_fsm.gd`** | **게임의 두뇌** — 신호+시야 해석, 상태 전이 |
| 6 | `gameplay/aircraft/aircraft.gd` | 명령 → 딜레이/관성 물리 이동 |
| 7 | `gameplay/aircraft/aircraft_collision.gd` | 거리로 충돌/도착 판정 |
| 8 | `core/main_game/game_manager.gd` | 게임오버/성공 + 재시작 |
| 9 | `ui/` · `debug/` · `core/utils/` | HUD / 디버그 / 공용 유틸 (필요할 때) |

**5번이 핵심.** 여기만 이해하면 게임 규칙 대부분을 안다.

## 알아두면 빨리 읽히는 규칙

- **컴포넌트 합성** — 한 스크립트가 다 하지 않고 작은 노드로 쪼갠다 (마샬러 = 이동+입력+수신호+ScreenClamp).
- **그룹 참조** — 노드끼리 경로가 아니라 그룹으로 찾는다. 조회는 `core/utils/scene_query.gd`로 통일.
- **책임 경계** — 입력은 변환만, 시야는 판정만, 비행기는 물리만, 해석은 FSM만. 이 경계가 곧 설계.

## 실행

- 게임: 에디터 F5
- 테스트: `tests/tests.tscn` 열고 F6 (화면에 결과) / 또는 `./run_tests.ps1`

## 더 볼 것

[README](../README.md) 설계·로드맵·씬 계층 · [DEVLOG](../DEVLOG.md) 왜 이렇게 짰는지 · [scene_diagram.svg](scene_diagram.svg) 다이어그램
