class_name SignalInput
extends Node
## 마샬러 수신호 입력 전담(디바이스 계층). 키 이벤트에 반응해 현재 신호를 상태(hand_signal)로 보관하고,
## 바뀔 때 hand_signal_changed를 방출한다. 인식/판정은 하지 않는다.
## 유지(hold) 신호: 떼면 NONE. NONE(무신호)≠STOP(정지 명령) — 둘을 같게 볼지는 AircraftFSM이 판단.
## 엔진 정지(목 긋기) 확정은 "누르는 순간"만 의미 있는 단발성이라 shutdown_confirmed 시그널로 분리.
## 그룹 'signal_input'으로 조회된다. 신호 어휘(SignalType/is_move_signal)는 HandSignal 도메인에 있다.

signal hand_signal_changed(sig: HandSignal.SignalType)
signal shutdown_confirmed

## 입력 액션명. project.godot의 InputMap 키와 일치해야 한다 (오타로 인한 조용한 실패 방지).
const ACTION_ADVANCE := &"signal_advance"
const ACTION_TURN_LEFT := &"signal_turn_left"
const ACTION_TURN_RIGHT := &"signal_turn_right"
const ACTION_STOP := &"signal_down"  # STOP 신호. 액션 id는 'signal_down'
const ACTION_SHUTDOWN := &"signal_shutdown"

var hand_signal: HandSignal.SignalType = HandSignal.SignalType.NONE

## 현재 유지 중인 수신호 (이벤트로 갱신된 캐시). 폴링 소비자(HUD 등)가 읽는다.
func get_signal() -> HandSignal.SignalType:
	return hand_signal

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_SHUTDOWN):
		shutdown_confirmed.emit()
	if _is_signal_event(event):
		var current := _read_signal()
		if current != hand_signal:
			hand_signal = current
			hand_signal_changed.emit(hand_signal)

func _read_signal() -> HandSignal.SignalType:
	if Input.is_action_pressed(ACTION_ADVANCE):
		return HandSignal.SignalType.ADVANCE
	if Input.is_action_pressed(ACTION_TURN_LEFT):
		return HandSignal.SignalType.TURN_LEFT
	if Input.is_action_pressed(ACTION_TURN_RIGHT):
		return HandSignal.SignalType.TURN_RIGHT
	if Input.is_action_pressed(ACTION_STOP):
		return HandSignal.SignalType.STOP
	return HandSignal.SignalType.NONE

func _is_signal_event(event: InputEvent) -> bool:
	return event.is_action(ACTION_ADVANCE) or event.is_action(ACTION_TURN_LEFT) \
		or event.is_action(ACTION_TURN_RIGHT) or event.is_action(ACTION_STOP)
