extends Node
## 마샬러 수신호 입력 전담. 키 입력을 신호 타입으로 변환만 하며, 인식/판정은 하지 않는다.
## 모든 신호는 방향키를 누르고 있는 동안만 유지된다 (hold-to-move). 떼면 NONE(무신호).
## NONE(무신호)과 STOP(정지 명령)은 서로 다른 의미다 — 둘을 같게 취급할지는 AircraftFSM이 판단한다.

enum SignalType { NONE, ADVANCE, STOP, TURN_LEFT, TURN_RIGHT }

func get_signal() -> SignalType:
	if Input.is_action_pressed("signal_advance"):
		return SignalType.ADVANCE
	if Input.is_action_pressed("signal_turn_left"):
		return SignalType.TURN_LEFT
	if Input.is_action_pressed("signal_turn_right"):
		return SignalType.TURN_RIGHT
	if Input.is_action_pressed("signal_down"):
		return SignalType.STOP
	return SignalType.NONE
