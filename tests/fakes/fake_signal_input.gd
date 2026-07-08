extends "res://src/gameplay/input/signal_input.gd"
## 테스트용 가짜 수신호 입력. 실제 키 입력 대신 sig 변수 값을 그대로 반환한다.
## 실제 SignalInput을 상속하므로 SignalType 타입 검사를 통과한다.

var sig: SignalType = SignalType.NONE

func get_signal() -> SignalType:
	return sig
