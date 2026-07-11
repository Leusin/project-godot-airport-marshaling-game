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

- 2026-07-11 [결정] 마샬러 방향(등/정면)을 주입된 타깃으로 판정 + HUD 자가 조회 제거 — 마샬러가 항상 비행기를 바라본다는 가정에서, 비행기가 화면 위(작은 z)면 등·아래면 정면을 보이므로 스프라이트를 좌우 반전해 좌/우 수신호의 손잡이 방향을 맞춘다(머리가 블롭이라 앞/뒤 차이는 미러링뿐). 처음엔 스프라이트가 `get_first_node_in_group(AIRCRAFT)`로 비행기를 자가 조회했으나 §6 위반 → `Marshaller`가 `set_facing_target`으로 비행기를 주입받아 `is_showing_back()` 사실만 노출하고 뷰는 부모 Pawn만 읽게 고침(비행기 지각의 `set_perception_target`과 대칭). 같은 결로 `ParkingGradeHUD`/`DebugHUD`도 비행기 자가 조회를 걷어내 GameManager가 `parking_metrics()`/`current_grade()`를 중계하고 HUD는 GameManager 싱글턴만 읽게 정렬(§3/§4/§6/§7).

- 2026-07-11 [결정] 주차 판정을 완전포함 → 겹침비율 + 등급(B/A/S/SS) 채점 — 확정 게이트를 `AABB.encloses`(완전포함)에서 풋프린트 XZ 겹침비율 ≥ `MIN_PARK_RATIO`(0.7)로 완화(비스듬히 들어오면 AABB가 주차존보다 커져 영영 확정 불가였던 문제 해결). 채점은 아키텍처대로 분리: `AircraftCollision`(기하 사실)이 `parking_metrics()`로 겹침비율·중심 오차·축 각도 오차를 제공, 신규 `ParkingGrade`(중립 규칙 도메인, HandSignal 패턴)가 위치·각도 오차 → 등급으로 환산, `GameManager`(판정자)가 확정 순간 등급을 스냅샷(유예 중 관성 이동 무관), `SuccessHUD`가 표시. 각도는 사각 주차존이라 180° 뒤집힘을 동일 취급(0=정렬~90=직각). 등급 임계값은 프로토타입 초기값 — 실측 튜닝 대상. 30/30 통과.

- 2026-07-11 [결정] 주차 등급은 게임 HUD, 정확도 수치는 디버그로 분리 — 라이브 등급(B/A/S/SS)은 실제 게임 HUD(`ParkingGradeHUD`, 우측)가 주차 충분(확정 가능) 동안 표시하고, 원자료(overlap/pos/ang)는 `DebugHUD`(백틱 토글)에만 둠. 둘 다 판정자와 같은 규칙(`ParkingGrade`)을 프리뷰로 재계산 — 규칙은 한 소스, 표시만 여러 곳. 키매핑 인디케이터는 하드코딩 대신 `InputMap.action_get_events`로 실제 바인딩을 읽어 라벨 생성(리바인딩 자동 반영), 방향키는 화살표 글리프로 압축.

- 2026-07-11 [에러] 에디터 밖에서 만든 `class_name` 스크립트가 전역 클래스 캐시에 없어 파서 에러(`Could not find type "ParkingGrade"`). MCP 헤드리스 재실행은 캐시를 자동 갱신 안 함 → `.godot/global_script_class_cache.cfg`에 항목을 알파벳 순 위치에 수동 추가해 해결. 교훈: 에디터를 거치지 않고 새 class_name 파일을 추가하면 캐시 등록이 필요.

- 2026-07-11 [결정] 엔티티를 씬으로 추출 + GameManager 스폰/배선 + 비행기 지각 대상 주입 — 인라인 Marshaller/Aircraft/Obstacle을 각각 `.tscn`으로 분리하고, GameManager가 레벨 스폰 마커(그룹 `marshaller_spawn`/`aircraft_spawn`) 위치에 인스턴싱. 비행기가 `require_single(MARSHALLER)`로 peer를 전역 조회하던 것을 GameManager가 `set_perception_target(marshaller)`로 주입하도록 바꿔 엔티티 간 횡적 커플링·크래시 위험 제거(대상 없으면 대기). 스폰 마커는 레벨 데이터라 레벨별로 다르게 둘 수 있음. 초기화 순서: GameManager가 마샬러를 먼저 스폰해야 다른 노드의 그룹 조회가 성립.

- 2026-07-11 [결정] 콜리전 폴리싱 — 마샬러 물리 블로킹 + 비행기 복합 히트박스. 마샬러를 Node3D→CharacterBody3D(`move_and_slide`), 장애물에 StaticBody3D + 신규 solid 레이어(bit4)를 줘 관통 방지(hazard Area3D 감지는 유지). 비행기 단일 박스 히트박스를 동체+날개 복합 형상으로 교체해 모델에 맞춤, `AircraftCollision._world_aabb`는 다중 셰입 AABB 병합으로 완전 주차 판정 유지. 시야는 shader 기반 `AircraftVision`(판정+시각화 통합)으로 교체, 미사용 `aircraft_vision_cone`/`vision_cone_debug_visual` 제거.

- 2026-07-09 [결정] 게임 판정 소유권을 Aircraft → GameManager로 이관 — 엔티티가 게임 규칙을 배달하던 구조(Aircraft가 `_game_manager`/`_signal_input`을 들고 충돌·입력을 GameManager로 연결)를 뒤집음. `AircraftCollision`은 RefCounted 사실 제공자(`hazard_hit` 시그널 / `is_fully_parked()`), `Aircraft`는 그 사실만 재노출(게임/입력 의존 제거), `GameManager`(판정자)가 비행기 사실 + 확정 입력을 구독해 게임오버/성공을 정한다. 방향: `Aircraft→GameManager`(엔티티가 판정자 호출) → `GameManager→Aircraft`(판정자가 엔티티 구독). 물리적 사실("hit"·"parked")과 게임 해석("game over"·"success")을 분리하니 규칙이 한 곳에 모임. Aircraft에 `aircraft` 그룹 재부여. 35/35 통과.

- 2026-07-09 [결정] 이동/FSM을 씬 자식 Node → RefCounted 헬퍼로 전환 — MarshallerMovement/AircraftMovement/AircraftFSM을 씬 노드에서 떼어내 소유 엔티티(Marshaller/Aircraft)가 코드로 들고 `_process`/`_physics_process`에서 직접 구동. FSM은 `update(in_view, 받은신호, speed, delta)` 후 `forward()`/`turn()`으로 이동 의도를 노출하고, Aircraft가 command_delay 뒤 AircraftMovement.update로 적용. 조회도 일부 그룹→부모참조(`get_parent_node_3d`)로. 교훈: HESITATING 진입 시 `_hesitate.start()` 누락 + `_last_move_signal` 무조건 대입으로 멈칫이 깨졌던 것을 테스트로 잡음 — RefCounted 전환 시 노드 수명주기(_ready)에 기대던 초기화가 사라지니 주의. 문서(ARCHITECTURE/scene_diagram)도 새 구조로 갱신.

- 2026-07-09 [결정] 커스텀 충돌(OBB/SAT)을 Godot Area3D로 교체 — 매 프레임 SAT로 직접 판정하던 것을 Area3D `area_entered`/겹침으로 전환. 장애물·마샬러는 hazard 레이어 Area3D(진입 시 게임오버), 주차존은 parking 레이어 Area3D(겹치는 동안 비행기 AABB가 주차존 AABB에 `AABB.encloses`면 확정 대기). 모든 콜리전 도형을 Y로 길게 만들어 세로는 항상 겹치게 → 실질 XZ 판정이라 기존 탑다운 동작 유지 + 도형 Y 정렬 튜닝 불필요. 대상 분류는 그룹 대신 콜리전 레이어(1=aircraft/2=hazard/3=parking). `collision_2d.gd`/`collision_shapes.gd`/`collision_debug_visual.gd`(Godot가 도형을 직접 렌더)와 그 단위테스트, GameGroups의 obstacle/parking/aircraft 상수 제거. 도형 크기는 에디터에서 튜닝 필요, 충돌 동작은 인게임 플레이테스트 필요.

- 2026-07-09 [결정] 스크립트 참조를 `preload()` 상수→`class_name` 전역으로 통일 — 클래스처럼 쓰이던 12개 스크립트(SceneQuery/GameGroups/HandSignal/Countdown/Collision2D/CollisionShapes/ScreenBounds/TestLib/Aircraft/AircraftFSM/AircraftVisionCone/SignalInput)에 `class_name` 선언, 모든 `const X = preload(...)` 제거하고 호출부를 전역 이름으로 변경. 별칭이 파일명과 달랐던 것(CountdownScript→Countdown, AircraftScript→Aircraft, FsmScript→AircraftFSM, VisionConeScript→AircraftVisionCone, SignalInputScript→SignalInput)만 호출부 개명. 상속/파일명/동작 불변, 이름 충돌 없음(오토로드 0). 45/45 테스트 통과.

- 2026-07-09 [결정] 수신호 어휘(SignalType/is_move_signal)를 `signal_input.gd`→`hand_signal.gd`(HandSignal 도메인)로 추출 — FSM/Aircraft/Marshaller/Sprite 등 게임플레이 로직이 enum 하나 때문에 입력 장치 스크립트를 preload하던 의존을 끊음. 이제 입력·Pawn·표시·판단이 모두 중립 도메인을 공유하고, 입력 노드를 실제로 읽는 곳(HUD/테스트)만 `signal_input.gd`를 참조. HUD의 노드 타입은 `Node`로 완화. 45/45 테스트 통과.

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

- 2026-07-11 주차 등급 + 라이브 HUD + 키매핑 인디케이터 + 카메라 여백 — (1) 확정 게이트를 완전포함→겹침비율(0.7)로 완화하고 확정 순간 위치·각도 오차로 채점(신규 `ParkingGrade` 도메인, `AircraftCollision.parking_metrics`, `GameManager` 스냅샷, `SuccessHUD` 표시). (2) 라이브 등급 프리뷰를 게임 HUD(신규 `ParkingGradeHUD`, 우측)로, 튜닝용 수치(overlap/pos/ang)는 `DebugHUD`(백틱)로 분리. (3) 주차 패드에 방향 화살표(노란색). (4) `SignalIndicator`에 InputMap을 읽어 각 신호 아이콘 키캡(↑←→↓/Space) 표시 — 우상단·볼드·선택 시 함께 스케일. (5) 카메라 시선축 dolly((0,16,9)→(0,19.5,11)) 여백 +22%. 임계값·카메라·레이아웃은 실측 튜닝. 30/30 통과, 실물 실행 오류 없음.

- 2026-07-11 콜리전 폴리싱 + 엔티티 씬화/스폰 리팩터 — 마샬러 물리 블로킹(CharacterBody3D + 장애물 StaticBody3D, solid 레이어), 비행기 복합 히트박스(동체+날개). Marshaller/Aircraft/Obstacle을 `.tscn`으로 추출하고 GameManager가 스폰 마커에 인스턴싱. 비행기의 마샬러 참조를 전역 조회 → GameManager 주입(`set_perception_target`)으로. 시야를 shader `AircraftVision`으로 교체(미사용 cone/debug 제거). main 폴더 실물 실행 확인(오류 없음).

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
