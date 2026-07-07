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

## 이동 신호(ADVANCE/TURN_LEFT/TURN_RIGHT)인지 판별. STOP/NONE은 이동 신호가 아니다.
## 신호 자체의 성질이므로 신호 도메인(여기)에 둔다 — FSM의 지식이 아니다.
static func is_move_signal(sig: SignalType) -> bool:
	return sig == SignalType.ADVANCE \
		or sig == SignalType.TURN_LEFT \
		or sig == SignalType.TURN_RIGHT

## 엔진 정지(목 긋기) 확정 버튼. 이동 신호(SignalType)와는 별개로, 주차 확정처럼
## "누르는 순간"만 의미 있는 단발성 입력이라 별도 메서드로 분리한다.
func is_shutdown_confirm_pressed() -> bool:
	return Input.is_action_just_pressed("signal_shutdown")
