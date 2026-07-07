# 진행 로그

형식: `YYYY-MM-DD [유형] 요약`. 각 로그는 위에서부터 최신 항목 추가.
<br>
**결정·교훈**은 설계/툴체인 의사결정과 재발 방지 함정, **세션**은 진행한 작업.

## Milestones

2026-06-28
Prototype Started

2026-07-01
Playable Prototype

2026-07-06
Prototype Complete

## 결정 · 교훈

- 2026-07-05 [결정] 씬 계층을 표준 레이어 트리로 재편 — MainGame(Always)/World(Pausable)/HudLayer/PauseLayer/TransitionLayer/DebugLayer. 크로스 트리 참조를 계층 경로 → 그룹 조회로 전환. 거리 판정으로 미사용이던 Area3D 히트박스 제거.

- 2026-07-05 [결정] 폴더 구조를 src/{core,gameplay,ui,debug} 트리로 재편 — 규모(스크립트 14개)에 맞게 빈 폴더 생략. 미사용 aircraft_signal_receiver.gd 삭제.

- 2026-07-05 [결정] 물리 튜닝값(max_speed 등)은 @export가 인스펙터 조정을 줘 중앙화 안 함.

- 2026-07-05 [교훈] Area3D 대신 수동 SAT 충돌 유지 — 시그널 불안정으로 걷어낸 이력 + 헤드리스 테스트 가능.

- 2026-07-05 [교훈] FSM 테스트가 주석-코드 불일치를 잡음: 시야 밖은 멈칫 없이 즉시 정지가 맞음. 코드를 정답으로 두고 주석 정정.

- 2026-06-28 [결정] 수신호 NONE과 STOP을 별개 값으로 유지 — 무신호(모호)와 정지 명령은 의미가 달라, FSM이 "모호하면 멈칫"을 구현할 수 있게 enum에서 분리.

- 2026-06-28 [에러] MeshInstance3D에 mesh 할당 전 set_surface_override_material 호출 → surface out of bounds. 교훈: mesh 대입 후 머티리얼 오버라이드 순서를 지킬 것.

- 2026-06-28 [에러] GDScript class_name과 const 별칭 이름 충돌 → 파서 에러. 해결: class_name 제거하고 preload const로만 참조. 교훈: MCP 헤드리스 재실행 구조라 전역 클래스 캐시 갱신이 불안정, 작은 유틸은 class_name 없이 preload로.

## 세션 로그

- 2026-07-06 레벨 조명/환경 추가 — 씬에 Light도 WorldEnvironment도 없어 셰이딩 머티리얼이 거의 검게 렌더되던 문제. Sun(DirectionalLight3D) + level_lighting.gd(WorldEnvironment로 배경/앰비언트 구성). 마샬러 Sprite3D는 unshaded라 영향 없음.

- 2026-07-06 확정 연출에 1초 유예 추가 — 스페이스 → 엔진정지 포즈 → 1초 뒤 성공 HUD. game_manager에 is_confirming_shutdown + Countdown(SHUTDOWN_CONFIRM_DELAY).

- 2026-07-06 주차 성공을 즉시 판정 → 확정 버튼(스페이스) 방식으로 변경 — signal_shutdown 액션 추가, is_awaiting_shutdown_confirm 상태. 완전 진입 후 확정을 눌러야 성공.

- 2026-07-06 판정 난이도 완화 — 주차존 3.0→4.5, 마샬러 충돌을 사각형→원(반지름 0.45). 빌보드 스프라이트라 메쉬 크기를 못 읽어 원으로 명시.

- 2026-07-06 주차 판정을 "겹침"→"완전 포함"으로 강화 — collision_2d에 obb_within_aabb 추가. 일부만 걸치면 실패.

- 2026-07-06 카메라 직교 → 원근(Perspective, fov 45) 전환 — screen_bounds에 compute_ground_frustum 추가(틸트/원근 반영, center 기준 클램프).

- 2026-07-05 충돌 박스 디버그 시각화 추가 — collision_shapes.gd로 판정과 시각화가 같은 소스 사용("그려진 박스=실제 판정 범위"). 백틱으로 토글.

- 2026-07-05 그룹 이름 중앙화(game_groups.gd StringName 상수) + 줄임말 제거.

- 2026-07-05 손수 돌리던 타이머를 Countdown 유틸로 승격 + 로직 매직넘버 상수화.

- 2026-07-05 충돌을 원(거리) → 모델 크기 기반 사각형(OBB, XZ 평면 SAT)으로 교체 — collision_2d.gd 순수 함수. 반크기를 메쉬 AABB에서 읽어 모델이 바뀌면 자동으로 따라감.

- 2026-07-05 테스트 결과를 창 모드면 씬 화면에, 헤드리스면 콘솔+종료코드로 분기. scene_query.gd로 그룹 단일 조회 널가드/싱글턴 정리.

- 2026-07-05 화면 경계 클램프 중복 제거(ScreenClamp 재사용 컴포넌트) + 외부 애드온 없는 경량 테스트 하네스 도입.

- 2026-07-01 A→B 유도 성공 판정 구현 — ParkingSpot + trigger_success + success_hud. 성공/실패 모두 엔터/ESC 재시작. MVP 기능 일단락.

- 2026-07-01 충돌 → 게임오버 구현 — AircraftHitbox(Area3D) 겹침으로 trigger_game_over, GameOverHUD, 트리 일시정지.

- 2026-07-01 비행기 FSM 구현(AircraftFSM) — IDLE/MOVING/HESITATING/STOPPING. NONE=1초 멈칫 후 정지, STOP=즉시정지, 시야 밖=NONE과 동일. STOPPING→IDLE은 실제 속도로 감지. 임시 브릿지 대체.

- 2026-06-28 수신호 입력 시스템 구현 — signal_input(방향키→신호타입, hold-to-move), 마샬러 이동(WASD)과 분리, SignalIndicatorHUD. 회전속도 50→25°/s. 더블탭 SLOW는 hold와 안 맞아 제거.

- 2026-06-28 비행기 기본 이동 구현(Aircraft) — command_delay(0.6s) 뒤 반영 + 가속/감속 관성. screen_bounds 유틸을 마샬러와 공유.

- 2026-06-28 비행기 시야 원뿔 구현(AircraftVisionCone) — 정면 기준 좌우 35도 + 반경, bool만 반환. 디버그 부채꼴 시각화(판정과 분리).

- 2026-06-28 마샬러 직접 이동 구현(MarshallerController/MoveInput) — 화면 경계를 카메라 크기+뷰포트 비율로 실시간 계산.

- 2026-06-28 godot-mcp 연동 확인 + 프로젝트 토대(project.godot, Main.tscn에 카메라/마샬러/비행기/게임매니저 뼈대).

- 2026-06-27 관리문서 3종(README/DEVLOG/MEMORY) 도입.
