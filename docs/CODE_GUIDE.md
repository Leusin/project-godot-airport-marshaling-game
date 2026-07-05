# 코드 읽기 가이드

20개 스크립트 / 약 800줄. 아래 **데이터 흐름 순서**대로 읽으면 빠르다.
파일별 상세 책임은 각 스크립트 맨 위 `##` 주석에 있으니 그걸 본다. 이 표는 "읽는 순서"만 준다.

| # | 파일 | 흐름 단계 |
|---|---|---|
| 1 | `core/main_game/Main.tscn` | 씬 골격 (계층/그룹/Process Mode) |
| 2 | `gameplay/marshaller/move_input.gd` | 이동 입력 |
| 3 | `gameplay/marshaller/signal_input.gd` | 수신호 입력 |
| 4 | `gameplay/aircraft/aircraft_vision_cone.gd` | 시야 판정 |
| 5 | **`gameplay/aircraft/aircraft_fsm.gd`** | **신호 해석 (게임의 두뇌)** |
| 6 | `gameplay/aircraft/aircraft.gd` | 물리 이동 |
| 7 | `gameplay/aircraft/aircraft_collision.gd` | 충돌/도착 판정 |
| 8 | `core/main_game/game_manager.gd` | 게임오버/성공 |
| 9 | `ui/` · `debug/` · `core/utils/` | 표시 · 디버그 · 공용 유틸 |

**5번만 이해하면 게임 규칙 대부분을 안다.**

## 실행

- 게임: 에디터 F5
- 테스트: `tests/tests.tscn` 열고 F6 (화면에 결과) / 또는 `./run_tests.ps1`

## 더 볼 것

설계·패턴·씬 계층 → [README](../README.md) · 왜 이렇게 짰는지 → [DEVLOG](../DEVLOG.md) · 구조 그림 → [scene_diagram.svg](scene_diagram.svg)
