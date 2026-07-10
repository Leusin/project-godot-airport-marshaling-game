extends Control
## 단위 테스트 러너 + 결과 출력.
##  - 창 모드(에디터 F6): 결과를 씬 화면(RichTextLabel)에 색상으로 렌더한다.
##  - 헤드리스(run_tests.ps1 / CI): 콘솔에 출력하고 실패 개수를 종료 코드로 반환한다.

@onready var _report: RichTextLabel = $Report

func _ready() -> void:
	var suite := TestLib.new()
	_test_countdown(suite)
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
# aircraft_fsm: 신호 해석 상태 전이. RefCounted FSM에 (시야, 받은 신호, 속도, delta)를 넣고
# 상태와 이동 출력(forward/turn)을 확인한다.
func _test_aircraft_fsm(suite: TestLib) -> void:
	suite.start("aircraft_fsm")

	var fsm := AircraftFSM.new()
	fsm.hesitate_duration = 1.0

	suite.check_eq(fsm._state, AircraftFSM.State.IDLE, "초기 상태 IDLE")

	# 시야 내 ADVANCE → MOVING + 전진
	fsm.update(true, HandSignal.SignalType.ADVANCE, 0.0, 0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.MOVING, "ADVANCE → MOVING")
	suite.check_almost(fsm.forward(), 1.0, "MOVING+ADVANCE → forward=1")

	# 회전 신호 → turn 출력 (여전히 MOVING)
	fsm.update(true, HandSignal.SignalType.TURN_LEFT, 0.0, 0.1)
	suite.check_almost(fsm.turn(), 1.0, "TURN_LEFT → turn=1")
	suite.check_almost(fsm.forward(), 0.0, "회전 중 forward=0")
	fsm.update(true, HandSignal.SignalType.ADVANCE, 0.0, 0.1)  # 다시 전진으로

	# 무신호(NONE) → HESITATING, 마지막 이동 신호로 계속 전진
	fsm.update(true, HandSignal.SignalType.NONE, 1.0, 0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.HESITATING, "MOVING + NONE → HESITATING(멈칫)")
	suite.check_almost(fsm.forward(), 1.0, "멈칫 중에도 전진 유지")

	# 멈칫 시간 경과 → STOPPING, 전진 멈춤
	fsm.update(true, HandSignal.SignalType.NONE, 1.0, 1.0)
	suite.check_eq(fsm._state, AircraftFSM.State.STOPPING, "멈칫 시간 경과 → STOPPING")
	suite.check_almost(fsm.forward(), 0.0, "STOPPING이면 forward=0")

	# 속도 0 → IDLE 복귀
	fsm.update(true, HandSignal.SignalType.NONE, 0.0, 0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.IDLE, "정지 완료 → IDLE")

	# STOP 신호는 멈칫 없이 즉시 STOPPING
	fsm.update(true, HandSignal.SignalType.ADVANCE, 0.0, 0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.MOVING, "재이동 → MOVING")
	fsm.update(true, HandSignal.SignalType.STOP, 1.0, 0.1)
	suite.check_eq(fsm._state, AircraftFSM.State.STOPPING, "MOVING + STOP → 즉시 STOPPING(멈칫 없음)")

	# 시야 밖(이동 중)은 멈칫 없이 즉시 STOPPING (유도자를 놓치면 지체 없이 정지)
	fsm.update(true, HandSignal.SignalType.NONE, 0.0, 0.1)      # STOPPING → IDLE
	fsm.update(true, HandSignal.SignalType.ADVANCE, 0.0, 0.1)   # IDLE → MOVING
	fsm.update(false, HandSignal.SignalType.ADVANCE, 1.0, 0.1)  # 시야 밖 → STOPPING
	suite.check_eq(fsm._state, AircraftFSM.State.STOPPING, "시야 밖(이동 중) → 즉시 STOPPING")

	# 시야 밖에서는 이동 신호가 있어도 IDLE에서 출발하지 않음
	fsm.update(true, HandSignal.SignalType.NONE, 0.0, 0.1)      # STOPPING → IDLE
	fsm.update(false, HandSignal.SignalType.ADVANCE, 0.0, 0.1)  # 시야 밖 + ADVANCE → IDLE 유지
	suite.check_eq(fsm._state, AircraftFSM.State.IDLE, "시야 밖에서는 출발하지 않음")
