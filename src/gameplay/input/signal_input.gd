extends Node
## 마샬러 수신호 입력 전담. 키 이벤트에 반응해 현재 신호를 상태(hand_signal)로 보관하고,
## 바뀔 때 hand_signal_changed를 방출한다. 인식/판정은 하지 않는다.
## 유지(hold) 신호: 떼면 NONE. NONE(무신호)≠STOP(정지 명령) — 둘을 같게 볼지는 AircraftFSM이 판단.
## 엔진 정지(목 긋기) 확정은 "누르는 순간"만 의미 있는 단발성이라 shutdown_confirmed 시그널로 분리.
## 그룹 'signal_input'으로 조회된다.

signal hand_signal_changed(sig: SignalType)
signal shutdown_confirmed

enum SignalType { NONE, ADVANCE, STOP, TURN_LEFT, TURN_RIGHT }

var hand_signal: SignalType = SignalType.NONE

## 현재 유지 중인 수신호 (이벤트로 갱신된 캐시). 폴링 소비자(FSM/HUD/스프라이트)가 읽는다.
func get_signal() -> SignalType:
	return hand_signal

## 이동 신호(ADVANCE/TURN_LEFT/TURN_RIGHT)인지 판별. STOP/NONE은 이동 신호가 아니다.
## 신호 자체의 성질이므로 신호 도메인(여기)에 둔다 — FSM의 지식이 아니다.
static func is_move_signal(sig: SignalType) -> bool:
	return sig == SignalType.ADVANCE \
		or sig == SignalType.TURN_LEFT \
		or sig == SignalType.TURN_RIGHT

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("signal_shutdown"):
		shutdown_confirmed.emit()
	if _is_signal_event(event):
		var current := _read_signal()
		if current != hand_signal:
			hand_signal = current
			hand_signal_changed.emit(hand_signal)

func _read_signal() -> SignalType:
	if Input.is_action_pressed("signal_advance"):
		return SignalType.ADVANCE
	if Input.is_action_pressed("signal_turn_left"):
		return SignalType.TURN_LEFT
	if Input.is_action_pressed("signal_turn_right"):
		return SignalType.TURN_RIGHT
	if Input.is_action_pressed("signal_down"):
		return SignalType.STOP
	return SignalType.NONE

func _is_signal_event(event: InputEvent) -> bool:
	return event.is_action("signal_advance") or event.is_action("signal_turn_left") \
		or event.is_action("signal_turn_right") or event.is_action("signal_down")
