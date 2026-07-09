class_name AircraftFSM
extends Node
## 비행기 신호 해석 FSM (비행기의 brain).
## IDLE -> MOVING -> HESITATING -> STOPPING -> IDLE 전이.
## NONE(무신호): 이동 중이면 hesitate_duration만큼 멈칫(계속 이동)하다가 정지.
## STOP(명확한 정지): 즉시 정지 시작. NONE과 달리 멈칫 없음.
## 시야 밖: 마샬러를 놓치면 즉시 STOPPING (in-view 무신호의 멈칫보다 엄격 — 지체 없이 정지).
##   또한 IDLE에서는 시야 밖이면 이동 신호를 받아도 출발하지 않는다.
##
## 입력원은 SignalInput/마샬러/시야를 직접 보지 않고, 부모 Aircraft가 "받은 신호"를 읽는다.
## (Aircraft가 자기 시야로 마샬러를 관찰해 received_signal/sees_marshaller로 제공)
## 신호 어휘(SignalType/is_move_signal)는 입력 장치가 아니라 HandSignal 도메인에서 가져온다.

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

var _state: State = State.IDLE
var _hesitate := Countdown.new()
var _last_move_signal: HandSignal.SignalType = HandSignal.SignalType.ADVANCE

func _process(delta: float) -> void:
	var in_view: bool = aircraft.sees_marshaller()
	var hand_signal: HandSignal.SignalType = aircraft.received_signal()

	match _state:
		State.IDLE:
			_process_idle(hand_signal)
		State.MOVING:
			_process_moving(hand_signal, in_view)
		State.HESITATING:
			_process_hesitating(hand_signal, in_view, delta)
		State.STOPPING:
			_process_stopping(hand_signal)

## 현재 상태 이름 (디버그 표시용).
func state_name() -> String:
	return State.keys()[_state]

func _process_idle(hand_signal: HandSignal.SignalType) -> void:
	aircraft.issue_signal(HandSignal.SignalType.STOP)
	if HandSignal.is_move_signal(hand_signal):
		_last_move_signal = hand_signal
		_enter_moving()

func _process_moving(hand_signal: HandSignal.SignalType, in_view: bool) -> void:
	if not in_view or hand_signal == HandSignal.SignalType.STOP:
		_enter_stopping()
		return
	if hand_signal == HandSignal.SignalType.NONE:
		_enter_hesitating()
		return
	_last_move_signal = hand_signal
	aircraft.issue_signal(hand_signal)

func _process_hesitating(hand_signal: HandSignal.SignalType, in_view: bool, delta: float) -> void:
	aircraft.issue_signal(_last_move_signal)

	if not in_view or hand_signal == HandSignal.SignalType.STOP:
		_enter_stopping()
		return
	if HandSignal.is_move_signal(hand_signal):
		_last_move_signal = hand_signal
		_state = State.MOVING
		return

	if _hesitate.tick(delta):
		_enter_stopping()

func _process_stopping(hand_signal: HandSignal.SignalType) -> void:
	aircraft.issue_signal(HandSignal.SignalType.STOP)
	if HandSignal.is_move_signal(hand_signal):
		_last_move_signal = hand_signal
		_enter_moving()
		return
	if aircraft.get_speed() < STOP_SPEED_EPSILON:
		_state = State.IDLE

func _enter_moving() -> void:
	_state = State.MOVING
	aircraft.issue_signal(_last_move_signal)

func _enter_hesitating() -> void:
	_state = State.HESITATING
	_hesitate.start(hesitate_duration)

func _enter_stopping() -> void:
	_state = State.STOPPING
	aircraft.issue_signal(HandSignal.SignalType.STOP)
