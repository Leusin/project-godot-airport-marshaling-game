class_name AircraftFSM
extends RefCounted

const STOP_SPEED_EPSILON := 0.05

enum State {
	IDLE,
	MOVING,
	HESITATING,
	STOPPING,
}

@export var hesitate_duration: float = 1.0

var _state := State.IDLE
var _hesitate := Countdown.new()
var _last_move_signal := HandSignal.SignalType.ADVANCE

func forward() -> float:
	match _state:
		State.MOVING, State.HESITATING:
			if _last_move_signal == HandSignal.SignalType.ADVANCE:
				return 1.0
	return 0.0

func turn() -> float:
	match _state:
		State.MOVING, State.HESITATING:
			match _last_move_signal:
				HandSignal.SignalType.TURN_LEFT:
					return 1.0
				HandSignal.SignalType.TURN_RIGHT:
					return -1.0
	return 0.0

func update(
	in_view: bool, 
	hand_signal: HandSignal.SignalType, 
	speed: float, 
	delta: float) -> void:
	# 마지막 "이동" 신호만 기억한다 (멈칫 중 이 방향으로 계속 이동). NONE/STOP엔 덮어쓰지 않음.
	if HandSignal.is_move_signal(hand_signal):
		_last_move_signal = hand_signal
	match _state:
		State.IDLE:
			_process_idle(in_view, hand_signal)
		State.MOVING:
			_process_moving(in_view, hand_signal)
		State.HESITATING:
			_process_hesitating(in_view, hand_signal, delta)
		State.STOPPING:
			_process_stopping(hand_signal, speed)
	
func _process_idle(in_view: bool, hand_signal: HandSignal.SignalType) -> void:
	if in_view and HandSignal.is_move_signal(hand_signal):
		_state = State.MOVING

func _process_moving(in_view: bool, hand_signal: HandSignal.SignalType) -> void:
	if not in_view or hand_signal == HandSignal.SignalType.STOP:
		_state = State.STOPPING
		return
		
	if hand_signal == HandSignal.SignalType.NONE:
		_hesitate.start(hesitate_duration)
		_state = State.HESITATING
		return

func _process_hesitating(in_view: bool, hand_signal: HandSignal.SignalType, delta: float) -> void:
	if not in_view or hand_signal == HandSignal.SignalType.STOP:
		_state = State.STOPPING
		return
		
	if HandSignal.is_move_signal(hand_signal):
		_state = State.MOVING
		return

	if _hesitate.tick(delta):
		_state = State.STOPPING
		return
		
func _process_stopping(hand_signal: HandSignal.SignalType, speed: float) -> void:
	if HandSignal.is_move_signal(hand_signal):
		_state = State.MOVING
		return
		
	if speed < STOP_SPEED_EPSILON:
		_state = State.IDLE
		return
