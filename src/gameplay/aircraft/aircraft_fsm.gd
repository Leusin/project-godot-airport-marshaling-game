extends Node
## 비행기 신호 해석 FSM.
## IDLE -> MOVING -> HESITATING -> STOPPING -> IDLE 전이.
## NONE(무신호): 이동 중이면 hesitate_duration만큼 멈칫(계속 이동)하다가 정지.
## STOP(명확한 정지): 즉시 정지 시작. NONE과 달리 멈칫 없음.
## 시야 밖: 마샬러를 놓치면 즉시 STOPPING (in-view 무신호의 멈칫보다 엄격 — 지체 없이 정지).
##   또한 IDLE에서는 시야 밖이면 이동 신호를 받아도 출발하지 않는다.

const SignalInputScript = preload("res://src/gameplay/marshaller/signal_input.gd")
const AircraftScript = preload("res://src/gameplay/aircraft/aircraft.gd")
const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const CountdownScript = preload("res://src/core/utils/countdown.gd")

## 이 속도 미만이면 "정지 완료"로 보고 STOPPING -> IDLE 전이.
const STOP_SPEED_EPSILON := 0.05

enum State {
	IDLE,
	MOVING,
	HESITATING,
	STOPPING,
}

@export var hesitate_duration: float = 1.0

@onready var aircraft: Node3D = get_parent()
@onready var vision_cone: Node = get_parent().get_node("VisionCone")

# 마샬러/수신호는 계층 경로가 아니라 그룹으로 찾는다 (씬 트리 위치에 독립적).
var marshaller: Node3D
var signal_input: SignalInputScript

func _ready() -> void:
	marshaller = SceneQuery.get_singleton(get_tree(), "marshaller", "AircraftFSM")
	signal_input = SceneQuery.get_singleton(get_tree(), "signal_input", "AircraftFSM")
	# 필수 참조가 없으면 _process에서 크래시하는 대신 조용히 비활성화 (경고는 위에서 출력됨).
	if marshaller == null or signal_input == null:
		set_process(false)

var _state: State = State.IDLE
var _hesitate := CountdownScript.new()
var _last_move_command: AircraftScript.Command = AircraftScript.Command.ADVANCE

func _process(delta: float) -> void:
	var in_view: bool = vision_cone.is_point_in_view(marshaller.global_position)
	var hand_signal: SignalInputScript.SignalType = signal_input.get_signal() if in_view else SignalInputScript.SignalType.NONE

	match _state:
		State.IDLE:
			_process_idle(hand_signal)
		State.MOVING:
			_process_moving(hand_signal, in_view)
		State.HESITATING:
			_process_hesitating(hand_signal, in_view, delta)
		State.STOPPING:
			_process_stopping(hand_signal)

func _process_idle(hand_signal: SignalInputScript.SignalType) -> void:
	aircraft.issue_command(AircraftScript.Command.STOP)
	if _is_move_signal(hand_signal):
		_last_move_command = _to_command(hand_signal)
		_enter_moving()

func _process_moving(hand_signal: SignalInputScript.SignalType, in_view: bool) -> void:
	if not in_view or hand_signal == SignalInputScript.SignalType.STOP:
		_enter_stopping()
		return
	if hand_signal == SignalInputScript.SignalType.NONE:
		_enter_hesitating()
		return
	_last_move_command = _to_command(hand_signal)
	aircraft.issue_command(_last_move_command)

func _process_hesitating(hand_signal: SignalInputScript.SignalType, in_view: bool, delta: float) -> void:
	aircraft.issue_command(_last_move_command)

	if not in_view or hand_signal == SignalInputScript.SignalType.STOP:
		_enter_stopping()
		return
	if _is_move_signal(hand_signal):
		_last_move_command = _to_command(hand_signal)
		_state = State.MOVING
		return

	if _hesitate.tick(delta):
		_enter_stopping()

func _process_stopping(hand_signal: SignalInputScript.SignalType) -> void:
	aircraft.issue_command(AircraftScript.Command.STOP)
	if _is_move_signal(hand_signal):
		_last_move_command = _to_command(hand_signal)
		_enter_moving()
		return
	if aircraft.get_speed() < STOP_SPEED_EPSILON:
		_state = State.IDLE

func _enter_moving() -> void:
	_state = State.MOVING
	aircraft.issue_command(_last_move_command)

func _enter_hesitating() -> void:
	_state = State.HESITATING
	_hesitate.start(hesitate_duration)

func _enter_stopping() -> void:
	_state = State.STOPPING
	aircraft.issue_command(AircraftScript.Command.STOP)

func _is_move_signal(s: SignalInputScript.SignalType) -> bool:
	return s == SignalInputScript.SignalType.ADVANCE \
		or s == SignalInputScript.SignalType.TURN_LEFT \
		or s == SignalInputScript.SignalType.TURN_RIGHT

func _to_command(s: SignalInputScript.SignalType) -> AircraftScript.Command:
	match s:
		SignalInputScript.SignalType.ADVANCE: return AircraftScript.Command.ADVANCE
		SignalInputScript.SignalType.TURN_LEFT: return AircraftScript.Command.TURN_LEFT
		SignalInputScript.SignalType.TURN_RIGHT: return AircraftScript.Command.TURN_RIGHT
		_: return AircraftScript.Command.STOP
