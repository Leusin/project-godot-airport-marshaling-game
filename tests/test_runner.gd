extends Control
## 단위 테스트 러너 + 결과 출력.
##  - 창 모드(에디터 F6): 결과를 씬 화면(RichTextLabel)에 색상으로 렌더한다.
##  - 헤드리스(run_tests.ps1 / CI): 콘솔에 출력하고 실패 개수를 종료 코드로 반환한다.

@onready var _report: RichTextLabel = $Report

func _ready() -> void:
	var suite := TestLib.new()
	_test_screen_bounds(suite)
	_test_countdown(suite)
	_test_collision_2d(suite)
	_test_vision_cone(suite)
	_test_signal_input(suite)
	_test_aircraft_fsm(suite)

	if DisplayServer.get_name() == "headless":
		_print_console(suite)
		get_tree().call_deferred("quit", 1 if suite.failed > 0 else 0)
	else:
		_render_scene(suite)

func _print_console(suite: TestLib) -> void:
	print("=== 단위 테스트 시작 ===")
	for result in suite.results:
		print("  [%s] %s :: %s" % ["PASS" if result.ok else "FAIL", result.section, result.msg])
	print("──────────────────────────────")
	print(suite.summary())

func _render_scene(suite: TestLib) -> void:
	var output := PackedStringArray()
	var head_color := "#66bb6a" if suite.failed == 0 else "#ef5350"
	output.append("[font_size=26][b][color=%s]%s[/color][/b][/font_size]\n" % [head_color, suite.summary()])
	var current_section := ""
	for result in suite.results:
		if result.section != current_section:
			current_section = result.section
			output.append("\n[b][color=#90caf9]%s[/color][/b]" % current_section)
		if result.ok:
			output.append("  [color=#66bb6a]PASS[/color]  %s" % result.msg)
		else:
			output.append("  [color=#ef5350]FAIL[/color]  %s" % result.msg)
	_report.text = "\n".join(output)

# ─────────────────────────────────────────────────────────
# screen_bounds: 카메라 orthogonal size + 뷰포트 비율로 절반 크기 계산 (순수 함수)
func _test_screen_bounds(suite: TestLib) -> void:
	suite.start("screen_bounds")
	var camera := Camera3D.new()
	camera.size = 20.0
	add_child(camera)

	var viewport := get_viewport()
	var half_extents := ScreenBounds.compute_half_extents(camera, viewport)
	var viewport_size := viewport.get_visible_rect().size
	var aspect := viewport_size.x / viewport_size.y

	suite.check_almost(half_extents.y, 10.0, "half_height = size / 2")
	suite.check_almost(half_extents.x, 10.0 * aspect, "half_width = half_height * aspect")

	camera.queue_free()

# ─────────────────────────────────────────────────────────
# countdown: 프레임 폴링 카운트다운 (딜레이/멈칫 타이머의 공용 구현)
func _test_countdown(suite: TestLib) -> void:
	suite.start("countdown")
	var countdown := Countdown.new()
	suite.check(not countdown.is_running(), "초기 상태: 안 돎")
	suite.check(not countdown.tick(0.1), "안 돌 때 tick → false")

	countdown.start(1.0)
	suite.check(countdown.is_running(), "start 후 → 돎")
	suite.check(not countdown.tick(0.4), "진행 중 (0.6 남음) → false")
	suite.check(not countdown.tick(0.4), "진행 중 (0.2 남음) → false")
	suite.check(countdown.tick(0.4), "0 도달 프레임 → true (한 번만)")
	suite.check(not countdown.tick(0.1), "완료 후 → false")
	suite.check(not countdown.is_running(), "완료 후: 안 돎")

	countdown.start(1.0)
	countdown.stop()
	suite.check(not countdown.is_running(), "stop() → 즉시 멈춤")

# ─────────────────────────────────────────────────────────
# collision_2d: 모델 크기 기반 OBB/원 겹침 판정 (SAT). 회전이 결과를 바꾸는지 확인.
func _test_collision_2d(suite: TestLib) -> void:
	suite.start("collision_2d")
	var forward_z := Vector2(0.0, 1.0)

	suite.check(Collision2D.obb_overlap(Vector2.ZERO, Vector2(1, 1), forward_z, Vector2.ZERO, Vector2(1, 1), forward_z),
		"같은 위치 → 겹침")
	suite.check(not Collision2D.obb_overlap(Vector2.ZERO, Vector2(1, 1), forward_z, Vector2(5, 0), Vector2(1, 1), forward_z),
		"멀리 → 안 겹침")

	# 2×3 비행기 코앞 2.0 지점의 0.75×0.75 장애물: 정면이면 닿고, 옆으로 돌면 안 닿음
	var plane_half_extents := Vector2(1.0, 1.5)
	var obstacle_center := Vector2(0.0, 2.0)
	var obstacle_half_extents := Vector2(0.75, 0.75)
	suite.check(Collision2D.obb_overlap(Vector2.ZERO, plane_half_extents, Vector2(0, 1), obstacle_center, obstacle_half_extents, forward_z),
		"정면이 장애물 향함 → 겹침")
	suite.check(not Collision2D.obb_overlap(Vector2.ZERO, plane_half_extents, Vector2(1, 0), obstacle_center, obstacle_half_extents, forward_z),
		"옆으로 돌면 → 안 겹침 (회전 반영)")

	suite.check(Collision2D.obb_circle_overlap(Vector2.ZERO, Vector2(1, 1), forward_z, Vector2(1.2, 0), 0.3),
		"원이 모서리 근처 → 겹침")
	suite.check(not Collision2D.obb_circle_overlap(Vector2.ZERO, Vector2(1, 1), forward_z, Vector2(1.4, 0), 0.3),
		"원이 멀면 → 안 겹침")

	# obb_within_aabb: 완전 포함 판정 (주차 성공 조건)
	var parking_center := Vector2(0, 0)
	var parking_half := Vector2(1.5, 1.5)
	suite.check(Collision2D.obb_within_aabb(Vector2.ZERO, Vector2(1.0, 1.2), forward_z, parking_center, parking_half),
		"작은 OBB가 완전히 안에 있음 → 포함")
	suite.check(not Collision2D.obb_within_aabb(Vector2(1.0, 0), Vector2(1.0, 1.2), forward_z, parking_center, parking_half),
		"일부만 겹침(모서리가 밖) → 비포함")
	suite.check(not Collision2D.obb_within_aabb(Vector2(5.0, 5.0), Vector2(1.0, 1.2), forward_z, parking_center, parking_half),
		"완전히 밖 → 비포함")
	# 45도 회전하면 대각선 폭이 늘어나 같은 위치라도 밖으로 삐져나올 수 있음 (회전 반영 확인)
	var diag := Vector2(1, 1).normalized()
	suite.check(not Collision2D.obb_within_aabb(Vector2.ZERO, Vector2(1.0, 1.2), diag, parking_center, parking_half),
		"45도 회전 시 대각선 폭 초과 → 비포함")

# ─────────────────────────────────────────────────────────
# vision_cone: 정면(-Z) 기준 좌우 half_angle + 반경 판정 (상태 없는 기하)
func _test_vision_cone(suite: TestLib) -> void:
	suite.start("vision_cone")
	var aircraft := Node3D.new()
	add_child(aircraft)
	aircraft.global_position = Vector3.ZERO

	var vision_cone := AircraftVisionCone.new()
	vision_cone.half_angle_degrees = 35.0
	vision_cone.view_radius = 10.0
	aircraft.add_child(vision_cone)

	suite.check(vision_cone.is_point_in_view(Vector3(0, 0, -5)), "정면 5m → 시야 내")
	suite.check(not vision_cone.is_point_in_view(Vector3(0, 0, 5)), "후방 → 시야 밖")
	suite.check(not vision_cone.is_point_in_view(Vector3(0, 0, -15)), "반경 초과 → 시야 밖")

	var wide_angle := deg_to_rad(40.0)
	suite.check(not vision_cone.is_point_in_view(Vector3(sin(wide_angle), 0, -cos(wide_angle)) * 5.0),
		"40도(>35) → 시야 밖")
	var narrow_angle := deg_to_rad(20.0)
	suite.check(vision_cone.is_point_in_view(Vector3(sin(narrow_angle), 0, -cos(narrow_angle)) * 5.0),
		"20도(<35) → 시야 내")

	aircraft.queue_free()

# ─────────────────────────────────────────────────────────
# signal_input: 이벤트 기반 수신호 — 키 이벤트에 반응해 hand_signal 갱신 + 시그널 방출
func _test_signal_input(suite: TestLib) -> void:
	suite.start("signal_input")
	var si := SignalInput.new()
	add_child(si)

	suite.check_eq(si.get_signal(), HandSignal.SignalType.NONE, "초기 상태 NONE")

	var changes: Array = []
	si.hand_signal_changed.connect(func(s): changes.append(s))

	# ADVANCE 누름 → hand_signal 갱신 + 시그널 1회
	Input.action_press("signal_advance")
	si._unhandled_input(_action_event("signal_advance", true))
	suite.check_eq(si.get_signal(), HandSignal.SignalType.ADVANCE, "ADVANCE 누름 → ADVANCE")
	suite.check(changes.size() == 1, "바뀌면 hand_signal_changed 1회 방출")

	# 같은 상태의 이벤트가 또 와도 재방출 안 함
	si._unhandled_input(_action_event("signal_advance", true))
	suite.check(changes.size() == 1, "값 그대로면 재방출 없음")

	# 뗌 → NONE
	Input.action_release("signal_advance")
	si._unhandled_input(_action_event("signal_advance", false))
	suite.check_eq(si.get_signal(), HandSignal.SignalType.NONE, "뗌 → NONE")

	# 엔진정지 확정은 hand_signal과 무관한 단발 시그널
	var confirms: Array = []
	si.shutdown_confirmed.connect(func(): confirms.append(true))
	si._unhandled_input(_action_event("signal_shutdown", true))
	suite.check(confirms.size() == 1, "signal_shutdown 누름 → shutdown_confirmed 1회")
	suite.check_eq(si.get_signal(), HandSignal.SignalType.NONE, "확정은 hand_signal 안 바꿈")

	si.queue_free()

func _action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event

# ─────────────────────────────────────────────────────────
# aircraft_fsm: 신호 해석 상태 전이. FSM은 부모 Aircraft가 "받은 신호"/시야만 읽으므로
# 페이크 Aircraft가 received_signal()/sees_marshaller()를 제공한다 (시야 밖이면 received=NONE).
func _test_aircraft_fsm(suite: TestLib) -> void:
	suite.start("aircraft_fsm")

	var fake_aircraft := FakeAircraft.new()
	add_child(fake_aircraft)

	var fsm := AircraftFSM.new()
	fsm.hesitate_duration = 1.0
	fake_aircraft.add_child(fsm)  # 자식 추가 시 fsm._ready 실행 → aircraft = get_parent()

	fake_aircraft.in_view = true

	suite.check_eq(fsm._state, AircraftFSM.State.IDLE, "초기 상태 IDLE")

	# ADVANCE → MOVING + 비행기에 ADVANCE 명령
	fake_aircraft.received_sig = HandSignal.SignalType.ADVANCE
	fsm._process(0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.MOVING, "ADVANCE → MOVING")
	suite.check_eq(fake_aircraft.last_signal, HandSignal.SignalType.ADVANCE, "ADVANCE 신호 전달")

	# 무신호(NONE) → HESITATING, 마지막 이동 신호 유지
	fake_aircraft.received_sig = HandSignal.SignalType.NONE
	fsm._process(0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.HESITATING, "MOVING + NONE → HESITATING(멈칫)")
	suite.check_eq(fake_aircraft.last_signal, HandSignal.SignalType.ADVANCE, "멈칫 중 이동 유지")

	# 멈칫 시간 경과 → STOPPING
	fsm._process(1.0)
	suite.check_eq(fsm._state, AircraftFSM.State.STOPPING, "멈칫 시간 경과 → STOPPING")
	suite.check_eq(fake_aircraft.last_signal, HandSignal.SignalType.STOP, "STOPPING 시 STOP 신호")

	# 속도 0 → IDLE 복귀
	fake_aircraft.speed = 0.0
	fsm._process(0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.IDLE, "정지 완료 → IDLE")

	# STOP 신호는 멈칫 없이 즉시 STOPPING
	fake_aircraft.received_sig = HandSignal.SignalType.ADVANCE
	fsm._process(0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.MOVING, "재이동 → MOVING")
	fake_aircraft.received_sig = HandSignal.SignalType.STOP
	fsm._process(0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.STOPPING, "MOVING + STOP → 즉시 STOPPING(멈칫 없음)")

	# 시야 밖(이동 중)은 멈칫 없이 즉시 STOPPING (유도자를 놓치면 지체 없이 정지)
	fake_aircraft.speed = 0.0
	fsm._process(0.1)  # STOPPING → IDLE
	fake_aircraft.received_sig = HandSignal.SignalType.ADVANCE
	fsm._process(0.1)  # IDLE → MOVING
	fake_aircraft.in_view = false
	fsm._process(0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.STOPPING, "시야 밖(이동 중) → 즉시 STOPPING")

	# 시야 밖에서는 이동 신호가 있어도 IDLE에서 출발하지 않음
	fake_aircraft.speed = 0.0
	fsm._process(0.1)  # STOPPING → IDLE
	fsm._process(0.1)  # 시야 밖 + ADVANCE 여전히 → 그대로 IDLE
	suite.check_eq(fsm._state, AircraftFSM.State.IDLE, "시야 밖에서는 출발하지 않음")

	fake_aircraft.queue_free()

# ── 페이크 노드 ────────────────────────────────────────────
## 실제 Aircraft 대역. FSM은 이 노드의 received_signal()/sees_marshaller()/get_speed()만 읽고,
## issue_signal()으로 명령을 되돌려준다. 시야 밖이면 received_signal은 NONE (실제 Aircraft와 동일 게이팅).
class FakeAircraft extends Node3D:
	var last_signal: int = -1
	var speed: float = 0.0
	var received_sig: int = HandSignal.SignalType.NONE
	var in_view: bool = true
	func issue_signal(sig: int) -> void:
		last_signal = sig
	func get_speed() -> float:
		return speed
	func sees_marshaller() -> bool:
		return in_view
	func received_signal() -> int:
		return received_sig if in_view else HandSignal.SignalType.NONE
