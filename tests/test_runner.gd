extends Control
## 단위 테스트 러너 + 결과 출력.
##  - 창 모드(에디터 F6): 결과를 씬 화면(RichTextLabel)에 색상으로 렌더한다.
##  - 헤드리스(run_tests.ps1 / CI): 콘솔에 출력하고 실패 개수를 종료 코드로 반환한다.

const TestLib := preload("res://tests/test_lib.gd")
const ScreenBounds := preload("res://src/core/utils/screen_bounds.gd")
const Collision2D := preload("res://src/core/utils/collision_2d.gd")
const CountdownScript := preload("res://src/core/utils/countdown.gd")
const VisionConeScript := preload("res://src/gameplay/aircraft/aircraft_vision_cone.gd")
const FsmScript := preload("res://src/gameplay/aircraft/aircraft_fsm.gd")
const SignalInputScript := preload("res://src/gameplay/marshaller/signal_input.gd")
const AircraftScript := preload("res://src/gameplay/aircraft/aircraft.gd")
const FakeSignalInput := preload("res://tests/fakes/fake_signal_input.gd")

@onready var _report: RichTextLabel = $Report

func _ready() -> void:
	var t := TestLib.new()
	_test_screen_bounds(t)
	_test_countdown(t)
	_test_collision_2d(t)
	_test_vision_cone(t)
	_test_aircraft_fsm(t)

	if DisplayServer.get_name() == "headless":
		_print_console(t)
		get_tree().call_deferred("quit", t.failed)
	else:
		_render_scene(t)

func _print_console(t: TestLib) -> void:
	print("=== 단위 테스트 시작 ===")
	for r in t.results:
		print("  [%s] %s :: %s" % ["PASS" if r.ok else "FAIL", r.section, r.msg])
	print("──────────────────────────────")
	print(t.summary())

func _render_scene(t: TestLib) -> void:
	var out := PackedStringArray()
	var head_color := "#66bb6a" if t.failed == 0 else "#ef5350"
	out.append("[font_size=26][b][color=%s]%s[/color][/b][/font_size]\n" % [head_color, t.summary()])
	var section := ""
	for r in t.results:
		if r.section != section:
			section = r.section
			out.append("\n[b][color=#90caf9]%s[/color][/b]" % section)
		if r.ok:
			out.append("  [color=#66bb6a]PASS[/color]  %s" % r.msg)
		else:
			out.append("  [color=#ef5350]FAIL[/color]  %s" % r.msg)
	_report.text = "\n".join(out)

# ─────────────────────────────────────────────────────────
# screen_bounds: 카메라 orthogonal size + 뷰포트 비율로 절반 크기 계산 (순수 함수)
func _test_screen_bounds(t: TestLib) -> void:
	t.start("screen_bounds")
	var cam := Camera3D.new()
	cam.size = 20.0
	add_child(cam)

	var vp := get_viewport()
	var he := ScreenBounds.compute_half_extents(cam, vp)
	var vsize := vp.get_visible_rect().size
	var aspect := vsize.x / vsize.y

	t.check_almost(he.y, 10.0, "half_height = size / 2")
	t.check_almost(he.x, 10.0 * aspect, "half_width = half_height * aspect")

	cam.queue_free()

# ─────────────────────────────────────────────────────────
# countdown: 프레임 폴링 카운트다운 (딜레이/멈칫 타이머의 공용 구현)
func _test_countdown(t: TestLib) -> void:
	t.start("countdown")
	var c := CountdownScript.new()
	t.check(not c.is_running(), "초기 상태: 안 돎")
	t.check(not c.tick(0.1), "안 돌 때 tick → false")

	c.start(1.0)
	t.check(c.is_running(), "start 후 → 돎")
	t.check(not c.tick(0.4), "진행 중 (0.6 남음) → false")
	t.check(not c.tick(0.4), "진행 중 (0.2 남음) → false")
	t.check(c.tick(0.4), "0 도달 프레임 → true (한 번만)")
	t.check(not c.tick(0.1), "완료 후 → false")
	t.check(not c.is_running(), "완료 후: 안 돎")

	c.start(1.0)
	c.stop()
	t.check(not c.is_running(), "stop() → 즉시 멈춤")

# ─────────────────────────────────────────────────────────
# collision_2d: 모델 크기 기반 OBB/원 겹침 판정 (SAT). 회전이 결과를 바꾸는지 확인.
func _test_collision_2d(t: TestLib) -> void:
	t.start("collision_2d")
	var fz := Vector2(0.0, 1.0)

	t.check(Collision2D.obb_overlap(Vector2.ZERO, Vector2(1, 1), fz, Vector2.ZERO, Vector2(1, 1), fz),
		"같은 위치 → 겹침")
	t.check(not Collision2D.obb_overlap(Vector2.ZERO, Vector2(1, 1), fz, Vector2(5, 0), Vector2(1, 1), fz),
		"멀리 → 안 겹침")

	# 2×3 비행기 코앞 2.0 지점의 0.75×0.75 장애물: 정면이면 닿고, 옆으로 돌면 안 닿음
	var plane_half := Vector2(1.0, 1.5)
	var obs := Vector2(0.0, 2.0)
	var obs_half := Vector2(0.75, 0.75)
	t.check(Collision2D.obb_overlap(Vector2.ZERO, plane_half, Vector2(0, 1), obs, obs_half, fz),
		"정면이 장애물 향함 → 겹침")
	t.check(not Collision2D.obb_overlap(Vector2.ZERO, plane_half, Vector2(1, 0), obs, obs_half, fz),
		"옆으로 돌면 → 안 겹침 (회전 반영)")

	t.check(Collision2D.obb_circle_overlap(Vector2.ZERO, Vector2(1, 1), fz, Vector2(1.2, 0), 0.3),
		"원이 모서리 근처 → 겹침")
	t.check(not Collision2D.obb_circle_overlap(Vector2.ZERO, Vector2(1, 1), fz, Vector2(1.4, 0), 0.3),
		"원이 멀면 → 안 겹침")

# ─────────────────────────────────────────────────────────
# vision_cone: 정면(-Z) 기준 좌우 half_angle + 반경 판정 (상태 없는 기하)
func _test_vision_cone(t: TestLib) -> void:
	t.start("vision_cone")
	var aircraft := Node3D.new()
	add_child(aircraft)
	aircraft.global_position = Vector3.ZERO

	var cone := VisionConeScript.new()
	cone.half_angle_degrees = 35.0
	cone.view_radius = 10.0
	aircraft.add_child(cone)

	t.check(cone.is_point_in_view(Vector3(0, 0, -5)), "정면 5m → 시야 내")
	t.check(not cone.is_point_in_view(Vector3(0, 0, 5)), "후방 → 시야 밖")
	t.check(not cone.is_point_in_view(Vector3(0, 0, -15)), "반경 초과 → 시야 밖")

	var wide := deg_to_rad(40.0)
	t.check(not cone.is_point_in_view(Vector3(sin(wide), 0, -cos(wide)) * 5.0),
		"40도(>35) → 시야 밖")
	var narrow := deg_to_rad(20.0)
	t.check(cone.is_point_in_view(Vector3(sin(narrow), 0, -cos(narrow)) * 5.0),
		"20도(<35) → 시야 내")

	aircraft.queue_free()

# ─────────────────────────────────────────────────────────
# aircraft_fsm: 신호 해석 상태 전이 (페이크 비행기/시야/수신호로 구동)
func _test_aircraft_fsm(t: TestLib) -> void:
	t.start("aircraft_fsm")

	var marshaller := Node3D.new()
	marshaller.add_to_group("marshaller")
	add_child(marshaller)

	var sig := FakeSignalInput.new()
	sig.add_to_group("signal_input")
	add_child(sig)

	var aircraft := FakeAircraft.new()
	add_child(aircraft)
	var cone := FakeVisionCone.new()
	cone.name = "VisionCone"
	aircraft.add_child(cone)

	var fsm := FsmScript.new()
	fsm.hesitate_duration = 1.0
	aircraft.add_child(fsm)  # 자식 추가 시 fsm._ready 실행 → 그룹에서 marshaller/signal_input 획득

	cone.in_view = true

	t.check_eq(fsm._state, FsmScript.State.IDLE, "초기 상태 IDLE")

	# ADVANCE → MOVING + 비행기에 ADVANCE 명령
	sig.sig = SignalInputScript.SignalType.ADVANCE
	fsm._process(0.1)
	t.check_eq(fsm._state, FsmScript.State.MOVING, "ADVANCE → MOVING")
	t.check_eq(aircraft.last_command, AircraftScript.Command.ADVANCE, "ADVANCE 명령 전달")

	# 무신호(NONE) → HESITATING, 마지막 이동 명령 유지
	sig.sig = SignalInputScript.SignalType.NONE
	fsm._process(0.1)
	t.check_eq(fsm._state, FsmScript.State.HESITATING, "MOVING + NONE → HESITATING(멈칫)")
	t.check_eq(aircraft.last_command, AircraftScript.Command.ADVANCE, "멈칫 중 이동 유지")

	# 멈칫 시간 경과 → STOPPING
	fsm._process(1.0)
	t.check_eq(fsm._state, FsmScript.State.STOPPING, "멈칫 시간 경과 → STOPPING")
	t.check_eq(aircraft.last_command, AircraftScript.Command.STOP, "STOPPING 시 STOP 명령")

	# 속도 0 → IDLE 복귀
	aircraft.speed = 0.0
	fsm._process(0.1)
	t.check_eq(fsm._state, FsmScript.State.IDLE, "정지 완료 → IDLE")

	# STOP 신호는 멈칫 없이 즉시 STOPPING
	sig.sig = SignalInputScript.SignalType.ADVANCE
	fsm._process(0.1)
	t.check_eq(fsm._state, FsmScript.State.MOVING, "재이동 → MOVING")
	sig.sig = SignalInputScript.SignalType.STOP
	fsm._process(0.1)
	t.check_eq(fsm._state, FsmScript.State.STOPPING, "MOVING + STOP → 즉시 STOPPING(멈칫 없음)")

	# 시야 밖(이동 중)은 멈칫 없이 즉시 STOPPING (유도자를 놓치면 지체 없이 정지)
	aircraft.speed = 0.0
	fsm._process(0.1)  # STOPPING → IDLE
	sig.sig = SignalInputScript.SignalType.ADVANCE
	fsm._process(0.1)  # IDLE → MOVING
	cone.in_view = false
	fsm._process(0.1)
	t.check_eq(fsm._state, FsmScript.State.STOPPING, "시야 밖(이동 중) → 즉시 STOPPING")

	# 시야 밖에서는 이동 신호가 있어도 IDLE에서 출발하지 않음
	aircraft.speed = 0.0
	fsm._process(0.1)  # STOPPING → IDLE
	fsm._process(0.1)  # 시야 밖 + ADVANCE 여전히 → 그대로 IDLE
	t.check_eq(fsm._state, FsmScript.State.IDLE, "시야 밖에서는 출발하지 않음")

	marshaller.queue_free()
	sig.queue_free()
	aircraft.queue_free()

# ── 페이크 노드 ────────────────────────────────────────────
class FakeAircraft extends Node3D:
	var last_command: int = -1
	var speed: float = 0.0
	func issue_command(command: int) -> void:
		last_command = command
	func get_speed() -> float:
		return speed

class FakeVisionCone extends Node:
	var in_view: bool = true
	func is_point_in_view(_point: Vector3) -> bool:
		return in_view
