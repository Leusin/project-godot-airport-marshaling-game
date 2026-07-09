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

- 2026-07-09 [결정] 비행기도 Controller/Pawn으로 정리 — FSM이 `SignalInput`을 직접 보던 것을, Aircraft가 자기 시야로 마샬러를 관찰해 "받은 신호"(`received_signal()`/`sees_marshaller()`, 시야 밖이면 NONE)를 제공하고 FSM은 그것만 읽어 상태 전이하도록 변경. 이제 FSM(brain)은 Aircraft만 바라보고(마샬러/시야/입력 직접 참조 제거), Aircraft(Pawn)가 명령을 보유, `AircraftControl`→`AircraftMovement` 개명(명령=FSM 결정을 읽어 이동). 물리적으로도 "조종사가 마샬러를 본다"에 부합. FSM 단위테스트는 fake Aircraft가 received_signal/sees_marshaller를 제공하도록 갱신(45/45 통과), 미사용 fake_signal_input 제거.

- 2026-07-09 [결정] 마샬러 수신호도 Controller/Pawn으로 통일 — 스프라이트가 `SignalInput`을 직접 보던 것을, `PlayerController`가 `SignalInput.hand_signal_changed`를 Pawn의 `set_hand_signal()`로 push하고 스프라이트는 Pawn의 `hand_signal`을 참조하도록 변경. 이제 Pawn이 이동·수신호 상태를 모두 보유(입력 무지)하고 컨트롤러가 모든 플레이어 입력을 라우팅. 입력 액션명은 StringName 상수(ACTION_*)로 분리(movement_input/signal_input). FSM/HUD는 여전히 SignalInput 직접 구독(범위 밖).

- 2026-07-09 [결정] 마샬러 입력/이동을 Controller/Pawn(언리얼 possess)으로 분리 — 이동 컴포넌트가 전역 입력을 당겨오던(pull) 구조를, 컨트롤러가 Pawn에 의도를 밀어넣는(push) 구조로 뒤집음. 신규 `PlayerController`가 `MovementInput`(개명: MoveInput)을 possess한 `Marshaller`로 라우팅하고, Pawn은 `move_intent`만 보유(입력 무지)해 `move_intent_changed`로 자식 `MarshallerMovement`(개명: MarshallerControl)를 깨운다. 전 구간 이벤트 기반(시그널 2홉), 위치 적분은 의도≠0일 때만 물리처리. AI 조종 교체 지점이 PlayerController 하나로 국소화됨. `MarshallerController`라는 이름은 이동 컴포넌트(Control)와 혼동돼 쓰지 않음.

- 2026-07-08 [결정] 입력 처리를 폴링→이벤트(`_unhandled_input`) — 입력 노드가 이벤트로 현재 상태를 보관·방출한다. 연속 입력(이동/유지 신호)은 소비자가 캐시(move_direction/hand_signal)를 매 프레임 읽고, 단발 입력(엔진정지 확정)은 shutdown_confirmed 시그널로 받는다. `get_signal()`이 캐시를 반환해 기존 폴링 소비자(FSM/HUD/스프라이트)는 무변경. 입력은 특정 엔티티 비의존이라 Systems/Input에 둠. 물리프레임 `is_action_just_pressed`의 단발입력 유실/중복도 해소.

- 2026-07-08 [결정] 엔티티 루트/이동 분리 — 루트(Aircraft/Marshaller)는 설정·정체성·명령, 실제 이동은 자식 Control 컴포넌트(AircraftControl/MarshallerControl). 부모가 먼저 명령을 해소한 뒤 자식이 움직여 충돌 판정보다 앞서 위치가 반영됨. 외부 인터페이스(issue_signal/get_speed)는 루트에 유지해 FSM/충돌 호출부 불변.

- 2026-07-08 [결정] 입력 스크립트를 gameplay/input/으로 분리 — move_input/signal_input은 특정 엔티티(마샬러) 비의존이라 marshaller/ 밖으로. 신호↔명령 번역은 Aircraft(구현 세부사항), is_move_signal은 SignalInput(신호의 성질)에 각각 귀속. ScreenClamp(화면 경계 클램프)는 제거.

- 2026-07-05 [결정] 씬 계층을 표준 레이어 트리로 재편 — MainGame(Always)/World(Pausable)/HudLayer/PauseLayer/TransitionLayer/DebugLayer. 크로스 트리 참조를 계층 경로 → 그룹 조회로 전환. 거리 판정으로 미사용이던 Area3D 히트박스 제거.

- 2026-07-05 [결정] 폴더 구조를 src/{core,gameplay,ui,debug} 트리로 재편 — 규모(스크립트 14개)에 맞게 빈 폴더 생략. 미사용 aircraft_signal_receiver.gd 삭제.

- 2026-07-05 [결정] 물리 튜닝값(max_speed 등)은 @export가 인스펙터 조정을 줘 중앙화 안 함.

- 2026-07-05 [교훈] Area3D 대신 수동 SAT 충돌 유지 — 시그널 불안정으로 걷어낸 이력 + 헤드리스 테스트 가능.

- 2026-07-05 [교훈] FSM 테스트가 주석-코드 불일치를 잡음: 시야 밖은 멈칫 없이 즉시 정지가 맞음. 코드를 정답으로 두고 주석 정정.

- 2026-06-28 [결정] 수신호 NONE과 STOP을 별개 값으로 유지 — 무신호(모호)와 정지 명령은 의미가 달라, FSM이 "모호하면 멈칫"을 구현할 수 있게 enum에서 분리.

- 2026-06-28 [에러] MeshInstance3D에 mesh 할당 전 set_surface_override_material 호출 → surface out of bounds. 교훈: mesh 대입 후 머티리얼 오버라이드 순서를 지킬 것.

- 2026-06-28 [에러] GDScript class_name과 const 별칭 이름 충돌 → 파서 에러. 해결: class_name 제거하고 preload const로만 참조. 교훈: MCP 헤드리스 재실행 구조라 전역 클래스 캐시 갱신이 불안정, 작은 유틸은 class_name 없이 preload로.

## 세션 로그

- 2026-07-08 입력 별도 엔티티화 + 이벤트 기반 전환 — MoveInput/SignalInput을 Marshaller 자식 → Systems/Input로 분리, `_unhandled_input`으로 상태 갱신(move_direction/hand_signal + hand_signal_changed 시그널). 엔진정지 확정을 폴링 → shutdown_confirmed 시그널로(AircraftCollision 구독). MarshallerControl은 MoveInput을 그룹(move_input) 조회. signal_input 이벤트 테스트 추가 (45/45). Godot 실물 실행 확인.

- 2026-07-08 컴포넌트 책임 정리 리팩터링 — 이동을 루트에서 AircraftControl/MarshallerControl로 분리, 입력 스크립트를 gameplay/input/으로 이동, ScreenClamp 제거(→ 미사용된 screen_bounds.compute_ground_frustum 제거). FSM은 상태 전이만, 신호→명령 번역은 Aircraft.issue_signal로, is_move_signal은 SignalInput으로. SceneQuery.get_singleton→require_single. 디버그 시각화가 Collision2D.obb_corners 재사용. 누락 .uid 트래킹 일관화. (테스트 38/38, MCP 실물 실행 확인)

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
