# 코드 읽기 가이드

코드를 빠르게 파악하기 위한 가이드입니다. 

아래 표는 "읽는 순서"만 제공하고, 파일별 상세 책임은 각 스크립트 맨 위 `##` 주석 참고.

| # | 파일 | 흐름 단계 |
|---|---|---|
| 1 | `core/main_game/Main.tscn` | 씬 골격 (계층/그룹/Process Mode) |
| 2 | `gameplay/hand_signal.gd` | 수신호 도메인 (종류 enum + 판별) |
| 3 | `gameplay/input/movement_input.gd` · `signal_input.gd` | 입력 (이동·수신호) |
| 4 | `gameplay/marshaller/player_controller.gd` | 입력을 Pawn으로 라우팅 (possess) |
| 5 | `gameplay/aircraft/aircraft_vision_cone.gd` | 시야 판정 |
| 6 | **`gameplay/aircraft/aircraft_fsm.gd`** | **신호 해석 (게임의 두뇌)** |
| 7 | `gameplay/aircraft/aircraft.gd` | Pawn: 신호 받아 FSM·이동 헬퍼 구동 |
| 8 | `gameplay/aircraft/aircraft_collision.gd` | 충돌/도착 사실 감지 (Area3D) |
| 9 | `core/main_game/game_manager.gd` | 현재 레벨 플레이 (스폰·승패 판정·HUD) |
| 10 | `core/main_game/campaign_manager.gd` · `main_game.gd` | 레벨 캠페인 진행 + 매니저 배선 |
| 11 | `ui/` · `debug/` · `core/utils/` | 표시 · 디버그 · 공용 유틸 |


## 실행

- 게임: 에디터 F5
- 테스트: `tests/tests.tscn` 열고 F6 (화면에 결과) / 또는 `./run_tests.ps1`

## 관련 문서

- [ARCHITECTURE](ARCHITECTURE.md) - 씬 구조와 설계
- [CONVENTIONS](CONVENTIONS.md) - 설계 원칙·코딩 컨벤션
- [TESTING](TESTING.md) - 테스트 하네스와 실행 방법
- [DEVLOG](DEVLOG.md) - 변경 이력과 설계 이유
- [scene_diagram.svg](attachment/scene_diagram.svg) - 씬 계층 다이어그램
