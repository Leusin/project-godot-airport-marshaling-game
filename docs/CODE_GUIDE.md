# 코드 읽기 가이드

코드를 빠르게 파악하기 위한 가이드입니다. 

아래 표는 "읽는 순서"만 제공하고, 파일별 상세 책임은 각 스크립트 맨 위 `##` 주석 참고.

| # | 파일 | 흐름 단계 |
|---|---|---|
| 1 | `core/main_game/Main.tscn` | 씬 골격 (계층/그룹/Process Mode) |
| 2 | `gameplay/input/move_input.gd` | 이동 입력 |
| 3 | `gameplay/input/signal_input.gd` | 수신호 입력 |
| 4 | `gameplay/aircraft/aircraft_vision_cone.gd` | 시야 판정 |
| 5 | **`gameplay/aircraft/aircraft_fsm.gd`** | **신호 해석 (게임의 두뇌)** |
| 6 | `gameplay/aircraft/aircraft.gd` | 설정·명령 (이동은 `aircraft_control.gd`) |
| 7 | `gameplay/aircraft/aircraft_collision.gd` | 충돌/도착 판정 |
| 8 | `core/main_game/game_manager.gd` | 게임오버/성공 |
| 9 | `ui/` · `debug/` · `core/utils/` | 표시 · 디버그 · 공용 유틸 |


## 실행

- 게임: 에디터 F5
- 테스트: `tests/tests.tscn` 열고 F6 (화면에 결과) / 또는 `./run_tests.ps1`

## 관련 문서

- [ARCHITECTURE](ARCHITECTURE.md) - 씬 구조와 설계
- [TESTING](TESTING.md) - 테스트 하네스와 실행 방법
- [DEVLOG](DEVLOG.md) - 변경 이력과 설계 이유
- [scene_diagram.svg](attachment/scene_diagram.svg) - 씬 계층 다이어그램
