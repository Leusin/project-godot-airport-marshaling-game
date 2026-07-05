진행 로그. 
작업할 때마다 위에서부터 최신 항목 추가 

작성 형식: 

```
- YYYY-MM-DD [유형] 한 일 요약
  - 세부 내용 (필요시)
```

유형:
- [결정] - 설계/구현/툴체인 의사결정. 안정화되면 README.md 설계 섹션으로 승급한다.
- [세션] - 진행한 작업 세션 요약.
- [에러] - 재발 가능한 함정. 증상 / 원인 / 해결 / 교훈 순으로 기록.

## Log

- 2026-07-05 [세션] 손수 돌리던 타이머를 Countdown 유틸로 승격 + 로직 매직 넘버 상수화.
	- src/core/utils/countdown.gd: 초 단위 카운트다운. tick(delta)가 0 도달 프레임에 한 번만 true. aircraft.gd(_pending_timer)와 aircraft_fsm.gd(_hesitate_timer)에 복붙돼 있던 `t -= delta; if t <= 0` 패턴을 대체.
	  - Godot Timer 노드 대신 순수 함수 유틸 선택: FSM/비행기가 매 프레임 폴링 구조라 시그널 노드보다 잘 붙고, 헤드리스 테스트가 됨 (테스트 9개 추가).
	- 매직 넘버 상수화: aircraft_fsm STOP_SPEED_EPSILON(0.05), aircraft_vision_cone COINCIDENT_EPSILON(0.001), aircraft_collision DEFAULT_HALF_EXTENT(0.5).
	  - HUD 그리기 좌표/폰트 크기 같은 순수 레이아웃 상수는 의도적으로 그대로 둠 (다 상수화하면 오히려 잡음, 프로토타입엔 과함).
	- 테스트 34/34 통과, 게임 정상.

- 2026-07-05 [세션] 충돌을 원(거리) → 모델 크기 기반 사각형(OBB)으로 교체.
	- 기존 aircraft_collision은 XZ 거리 + 고정 반지름(1.5)이라 2×3 비행기/1.5×1.5 장애물/3×3 주차를 원 하나로 뭉뚱그렸음. 사용자 요청으로 보이는 메쉬 크기에 맞춤.
	- src/core/utils/collision_2d.gd: XZ 평면 SAT(분리축) OBB-OBB 겹침 + OBB-원 겹침. 순수 함수.
	- aircraft_collision: 비행기를 회전하는 OBB(정면=-Z), 대상을 축정렬 사각형으로 보고 겹침 판정. 각 도형의 반크기는 노드의 MeshInstance3D 메쉬 AABB에서 읽어와 모델이 바뀌면 자동으로 따라감. hit_radius/park_radius export 제거.
	- 테스트 6개 추가(collision_2d): 기본 겹침/분리, "정면이면 닿고 옆으로 돌면 안 닿음"으로 회전 반영 확인, 원 판정. 총 25/25 통과.
	- [참고] Godot 물리(Area3D) 대신 수동 SAT 유지 — 예전에 Area3D 시그널 불안정으로 걷어낸 경로라서. 순수 함수라 헤드리스 테스트도 가능.

- 2026-07-05 [세션] 테스트 결과 씬 출력 + 그룹 조회 널 가드/싱글턴 정리.
	- tests: 창 모드(에디터 F6)면 결과를 씬 화면(RichTextLabel, 색상 BBCode)에 렌더, 헤드리스(run_tests.ps1/CI)면 콘솔 출력 + 실패 수를 종료 코드로. DisplayServer.get_name()=="headless"로 분기.
	  - test_lib은 결과를 누적만 하도록 바꾸고(출력은 러너가 담당), tests.tscn을 Control+ColorRect+RichTextLabel 구조로 교체.
	- src/core/utils/scene_query.gd: 그룹 단일 인스턴스 조회 유틸. 0개면 null+경고, 2개 이상이면 첫 번째+경고(싱글턴 가정 위반을 드러냄). 흩어져 있던 get_first_node_in_group + 널 처리를 한 곳으로.
	- 적용: aircraft_fsm(마샬러/수신호 없으면 set_process(false)), game_manager(HUD 널 가드 + trigger_*에서 null 체크), aircraft_collision(game_manager를 _ready에서 1회 캐시 → 매 프레임 조회 제거, 없으면 set_physics_process(false)), vision_cone_debug_visual(마샬러 없으면 색상 갱신만 off), signal_indicator_hud(_draw가 이미 널 가드).
	- 게임/테스트 모두 정상 (실 씬엔 싱글턴이 다 있어 경고 없음, 테스트 19/19 유지).

- 2026-07-05 [세션] 화면 경계 중복 제거(ScreenClamp 컴포넌트) + 단위 테스트 도입.
	- src/core/utils/screen_clamp.gd: 부모 Node3D를 카메라 가시 영역으로 클램프하는 재사용 컴포넌트. aircraft.gd/marshaller_controller.gd에 복붙돼 있던 _update_bounds + 클램프 로직을 이 자식 노드 하나로 통합. Marshaller(edge_margin 0.5)/Aircraft(1.0)에 부착. 부모가 자식보다 먼저 _physics_process → 부모 이동 후 클램프되는 순서 보장.
	- aircraft.gd/marshaller_controller.gd에서 경계 관련 코드 전부 제거(각 스크립트가 이동 로직만 남음).
	- tests/: 외부 애드온 없는 경량 자체 테스트 하네스.
	  - test_lib.gd(check/check_eq/check_almost/report), test_runner.gd(러너 + 페이크 노드), tests.tscn, fakes/fake_signal_input.gd.
	  - 커버: screen_bounds(순수 계산), aircraft_vision_cone(각도/반경 기하), aircraft_fsm(상태 전이 — 페이크로 구동). 19개 단언.
	  - 실행: godot --headless --path . res://tests/tests.tscn → 실패 개수를 종료 코드로 반환.
	- [교훈] FSM 테스트가 주석-코드 불일치를 잡음: 주석엔 "시야 밖=무신호(멈칫)"였지만 실제 코드는 시야 밖이면 즉시 STOPPING(멈칫 없음)이었다. "유도자를 놓치면 지체 없이 정지"가 더 안전한 동작이라 코드를 정답으로 두고 주석을 정정.

- 2026-07-05 [세션] DebugLayer에 디버그 오버레이(FPS + 버전) 추가.
	- src/debug/debug_hud.gd: DebugRoot에 부착. 화면 우상단에 "v{버전} {FPS} FPS" 표시. ProjectSettings의 application/config/version을 읽음. process_mode=Always라 일시정지 중에도 갱신.
	- project.godot에 config/version="0.1.0" 추가 (기존엔 없어서 0.0.0으로 표시됐음).
	- docs/scene_diagram.svg: 스크립트 관계도 → 실제 씬 계층 트리(레이어/그룹/Process Mode 뱃지 포함)로 전면 갱신.

- 2026-07-05 [결정] 씬 계층 구조를 표준 레이어 트리로 재편.
	- 기존 평평한 root(Node3D) 아래 모든 노드 나열 → MainGame(Always) / Systems / World(Pausable) / HudLayer / PauseLayer / TransitionLayer / DebugLayer 로 재편.
	- World 아래 LevelRoot(배경: Ground/Obstacle/ParkingSpot) / EntityRoot(핵심: Marshaller/Aircraft) / EffectRoot(향후 효과) 로 분리. TopDownCamera는 World 직속.
	- CanvasLayer 레이어 번호: HudLayer=10, PauseLayer=20, TransitionLayer=100, DebugLayer=128. 각 Layer 아래 *Root(Control, mouse_filter=Ignore) 를 두고 그 밑에 UI 배치.
	- Pause/Transition/Debug 는 Process Mode Always, World/HudLayer 는 Pausable → 게임오버/성공 시 tree.paused=true 로 World가 멈춰도 오버레이(각 노드 process_mode=Always)는 계속 동작.
	- 크로스 트리 참조를 계층 경로(get_parent().get_parent().get_node()) → 그룹 조회(get_tree().get_first_node_in_group / get_nodes_in_group)로 전환. 그룹: game_manager, marshaller, signal_input, game_over_hud, success_hud, obstacle, parking. 트리 위치에 독립적이고 다중 배치도 지원.
	- 거리 기반 감지로 이미 미사용이던 Area3D 히트박스 + CollisionShape(마샬러/장애물/주차) 제거, 그룹을 엔티티 루트 노드에 직접 부착. 관련 미사용 sub_resource도 정리.
	- GameOverHUD/SuccessHUD: HudRoot(full-rect) 아래 full-rect 앵커로 자동 사이징 → _ready의 수동 size 설정 + size_changed 연결 제거 (앵커 경고 해소).
	- 템플릿의 "BehaviorRecursive Disabled"는 표준 Godot 속성이 아니라 생략, "Layer 0"(World)은 3D 노드라 무의미해 생략.
	- run_project로 참조 깨짐/경고 없음 확인.

- 2026-07-05 [결정] 폴더 구조를 src/ 트리로 재편.
	- 기존 scenes/ + 평평한 scripts/ 구조 → src/{core,gameplay,ui,debug} 로 역할별 분리.
	- src/core/main_game(Main.tscn, game_manager.gd), src/core/utils(screen_bounds.gd), src/gameplay/aircraft, src/gameplay/marshaller, src/ui, src/debug(vision_cone_debug_visual, apply_project_settings).
	- 다른 프로젝트 예시 구조를 참고하되 우리 규모(스크립트 14개)에 맞게 levels/resources/shaders/autoload 등 빈 폴더는 생략.
	- 이동 후 preload 경로, Main.tscn ext_resource path, project.godot main_scene 모두 갱신. run_project로 참조 깨짐 없음 확인.
	- 미사용 aircraft_signal_receiver.gd(AircraftFSM으로 대체된 임시 브릿지) 삭제.
	- apply_project_settings.gd(EditorScript)를 tools/ → src/debug/로 이동.

- 2026-07-01 [세션] A→B 유도 성공 판정 구현 완료.
	- scenes/Main.tscn: ParkingSpot 노드 추가 (위치 (-3, 0, 3), 밝은 초록 납작 박스). Area3D에 collision_parking 그룹 부착. 충돌 감지용 BoxShape3D(3×2×3) — 높이 2로 y=0.3에 있는 비행기를 잡을 수 있게.
	- scripts/aircraft_collision.gd: collision_parking 그룹 감지 시 trigger_success() 호출 (기존 collision_marshaller/collision_obstacle는 trigger_game_over() 유지). 주차 성공이 충돌보다 우선.
	- scripts/game_manager.gd: trigger_success() 추가. _is_success 플래그로 중복 방지. 성공/실패 모두 엔터/ESC로 재시작.
	- scripts/success_hud.gd: 초록 오버레이 + "유도 성공!" 텍스트. game_over_hud.gd와 동일한 구조.
	- 다음: MVP 완성 — 플레이테스트 및 밸런스 조정.
- 2026-07-01 [세션] 충돌 → 게임 오버 구현 완료.
	- scripts/aircraft_collision.gd: Aircraft 자식 Area3D. collision_marshaller / collision_obstacle 그룹에 속한 Area3D와 겹치면 GameManager.trigger_game_over() 호출.
	- scripts/game_manager.gd: trigger_game_over() → 트리 일시정지 + GameOverHUD 표시. 엔터/ESC → reload_current_scene()으로 재시작. process_mode=ALWAYS로 일시정지 중에도 입력 수신.
	- scripts/game_over_hud.gd: 전체화면 Control. show_game_over() 호출 시 _draw()로 어두운 오버레이 + "GAME OVER" 텍스트 표시. process_mode=ALWAYS.
	- Main.tscn: Aircraft/AircraftHitbox(Area3D + BoxShape 2×0.6×3), Marshaller/MarshallerHitbox(Area3D + CapsuleShape, 그룹 collision_marshaller), Obstacle(주황 박스, ObstacleHitbox에 그룹 collision_obstacle), GameManager 스크립트 부착, HUD/GameOverHUD 추가.
	- 다음: A->B 유도 성공/실패 판정.
- 2026-07-01 [세션] 비행기 FSM 구현 완료 (AircraftFSM).
	- scripts/aircraft_fsm.gd: IDLE/MOVING/HESITATING/STOPPING 4상태 FSM. aircraft_signal_receiver.gd(임시 브릿지)를 완전히 대체.
	- NONE(무신호)와 STOP(명확한 정지)를 다르게 처리:
	  - NONE: 이동 중이면 hesitate_duration(1.0s) 동안 멈칫(계속 이동)한 뒤 STOPPING으로 전이.
	  - STOP: 즉시 STOPPING 전이 (멈칫 없음).
	  - 시야 밖(out-of-view)은 NONE과 동일하게 처리.
	- STOPPING → IDLE 전이는 aircraft.get_speed() < 0.05로 실제 정지 감지 (고정 타이머 아님).
	- scripts/aircraft.gd에 get_speed() 추가 (FSM이 실제 속도를 확인하기 위해).
	- Main.tscn: AircraftSignalReceiver 노드 이름 → AircraftFSM, 스크립트 교체.
	- 다음: 충돌 → 게임 오버 (비행기-장애물, 사람-비행기).
- 2026-06-28 [세션] 수신호 입력 시스템 구현 완료 (SignalInput + AircraftSignalReceiver + SignalIndicatorHUD).
	- scripts/signal_input.gd: 방향키 -> 신호 타입(NONE/ADVANCE/STOP/TURN_LEFT/TURN_RIGHT) 변환만, 판정은 안 함. 모두 hold-to-move (누르고 있는 동안만 유지).
	- 마샬러 이동(WASD)과 수신호(방향키)를 분리해 두 입력이 충돌하지 않게 함. move_left/right/up/down에서 방향키 바인딩 제거.
	- scripts/aircraft_signal_receiver.gd: 시야 원뿔 + SignalInput을 조합해 Aircraft에 명령 전달하는 임시 브릿지. 시야 밖/무신호/정지는 모두 정지로 처리하지만, NONE과 STOP은 SignalType에서 별개 값으로 유지 (AircraftFSM에서 무신호=모호함/멈칫, STOP=명확한 정지로 다르게 다룰 수 있도록).
	- 기존 aircraft_debug_autopilot.gd(자동 순환 디버그)는 삭제하고 실제 입력 경로로 대체.
	- scripts/signal_indicator_hud.gd: 현재 신호를 화면 좌상단에 아이콘(원+화살표/X)으로 표시. 텍스처 없이 Control._draw()로 직접 그림.
	- Aircraft.turn_speed_degrees 50 -> 25로 감소 (회전이 너무 빨라 보임).
	- 중간에 "더블탭=천천히(SLOW)" 신호를 시도했다가, hold 방식과 일관성이 안 맞아 제거하고 4종 신호(전진/정지/좌우회전) 모두 hold로 통일.
	- 다음: 비행기 FSM (IDLE/INTERPRETING/MOVING/STOPPING, 모호한 신호 처리).
- 2026-06-28 [결정] 수신호 NONE과 STOP을 같은 값으로 합치지 않기로 함.
	- 실제 마샬링 수신호에서도 "신호 없음"과 "정지하라는 명확한 신호"는 다른 의미 (무신호=지시 없음/모호, 정지=명확한 정지 명령). 지금은 AircraftFSM이 없어서 둘 다 정지로 동작은 같지만, SignalType enum에서 값을 분리해둬야 나중에 FSM이 "모호한 신호는 멈칫"을 구현할 수 있음.
- 2026-06-28 [세션] 비행기 기본 이동 + 딜레이/관성 구현 완료 (Aircraft).
	- scripts/aircraft.gd: Command(STOP/ADVANCE/TURN_LEFT/TURN_RIGHT) 수신 -> command_delay(0.6s) 뒤에 반영, 가속/감속으로 속도 점진 변화. 회전도 turn_speed_degrees로 일정 각속도.
	- scripts/screen_bounds.gd: 탑다운 카메라 가시 영역(half extents) 계산을 마샬러/비행기가 공유하는 유틸리티로 분리. marshaller_controller.gd도 이걸 쓰도록 리팩터링.
	- Aircraft에도 화면 경계 클램프 적용 (사용자 확인: 화면 밖으로 안 나가는 것 확인).
	- scripts/aircraft_debug_autopilot.gd: AircraftFSM/SignalInput 구현 전까지 Command를 순환시켜 딜레이+관성을 눈으로 확인하기 위한 임시 디버그 스크립트. FSM 만들면 제거.
	- 다음: 수신호 입력 시스템 (전진/정지/좌우회전, 시야 안에서만 인식).
- 2026-06-28 [세션] 비행기 시야 원뿔 구현 완료 (AircraftVisionCone).
	- scripts/aircraft_vision_cone.gd: 정면(-Z) 기준 좌우 35도 + 반경(view_radius) 안에 점이 있는지 bool만 반환. 상태 없음.
	- Aircraft를 Y 180도 회전시켜 기본 정면이 Marshaller 스폰 방향(+Z)을 향하도록 함. NoseMarker(파란 작은 박스)로 정면 표시.
	- 디버그 전용 vision_cone_debug_visual.gd 추가: 부채꼴 메쉬를 절차적으로 생성해 마샬러가 원뿔 안/밖일 때 초록/빨강으로 표시. 실제 판정 로직과는 분리되어 있고 게임플레이에는 관여하지 않음.
	- 사용자 확인: 정상 동작.
	- 다음: 비행기 기본 이동 + 딜레이/관성.
- 2026-06-28 [에러] MeshInstance3D에 mesh 할당 전 set_surface_override_material 호출.
	- 증상: "Index p_surface = 0 is out of bounds (surface_override_materials.size() = 0)".
	- 원인: surface override는 mesh의 surface 개수를 기준으로 검증되는데, mesh를 아직 할당하기 전(surface 0개)에 머티리얼을 먼저 설정함.
	- 해결: mesh 할당 후에 set_surface_override_material 호출하도록 순서 변경.
	- 교훈: 절차적 메쉬를 만들 때는 mesh 대입 -> 머티리얼 오버라이드 순서를 지킬 것.
- 2026-06-28 [세션] 마샬러 직접 이동 구현 완료 (MarshallerController/MoveInput).
	- Ground(50x50)/MarshallerMesh(캡슐)/AircraftMesh(박스) 임시 비주얼 추가.
	- project.godot에 move_left/right/up/down 입력 액션 등록.
	- 화면 경계 클램프를 고정값이 아니라 TopDownCamera의 orthogonal size + 뷰포트 비율로 실시간 계산하도록 구현 (_update_bounds, viewport size_changed에 연결).
	- 사용자 확인: 화면 가장자리에서 정확히 멈추는 것 확인됨.
	- 다음: 비행기 70도 시야 원뿔 + 시야 안 판정.
- 2026-06-28 [에러] GDScript class_name과 const 별칭 이름 충돌.
	- 증상: "The constant MoveInput has the same name as a global class defined in move_input.gd" 경고 + 최초 실행 시 "Could not find type MoveInput in the current scope" 파서 에러.
	- 원인: move_input.gd에 class_name MoveInput 선언, marshaller_controller.gd에서 동시에 const MoveInput = preload(...)로 같은 이름 사용. 전역 클래스 캐시(.godot)가 즉시 갱신되지 않아 처음엔 타입을 못 찾고, 나중엔 이름 충돌 경고로 바뀜.
	- 해결: class_name 선언 제거하고 preload 기반 const(이름을 MoveInputScript로 변경)만 사용.
	- 교훈: MCP로 매번 새 헤드리스 godot 프로세스를 띄우는 구조라 전역 스크립트 클래스 캐시 갱신 타이밍이 불안정함. 작은 유틸 스크립트는 class_name 없이 preload로 참조하는 게 안전.
- 2026-06-28 [세션] godot-mcp 연동 확인 (get_godot_version/launch_editor 정상). 프로젝트 토대 작업 완료.
	- project.godot 생성 (worktree 루트, AirportMarshalingPrototype 폴더 밖). scenes/scripts/assets 폴더 생성.
	- scenes/Main.tscn 생성, root(Node3D) 아래 TopDownCamera(Orthogonal, y=15 내려보기)/Marshaller/Aircraft/GameManager 노드 뼈대 추가.
	- run_project로 정상 구동 확인.
	- 다음: 마샬러(플레이어) 직접 이동 구현.
- 2026-06-27 [세션] 다른 PC 프로토타입 미동기화 확인, 기억으로 README 복원, 관리문서 3종(README/DEVLOG/MEMORY) 도입.
	- 다음: 폴더구조/노드규칙 확정 + Godot 프로젝트 생성.
