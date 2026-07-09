class_name HandSignal
extends RefCounted
## 마샬링 수신호 도메인. 수신호의 종류(SignalType)와 그 성질(is_move_signal)만 정의한다.
## 입력 장치(SignalInput)가 아니라 "신호 자체의 어휘"이므로 여기 둔다 —
## 입력(SignalInput)·Pawn(Marshaller/Aircraft)·표시(HUD/Sprite)·판단(FSM)이 모두 이걸 공유한다.
## (예전엔 signal_input.gd에 있어 게임플레이 로직이 입력 장치에 의존했다. 도메인으로 분리)

enum SignalType { NONE, ADVANCE, STOP, TURN_LEFT, TURN_RIGHT }

## 이동 신호(ADVANCE/TURN_LEFT/TURN_RIGHT)인지 판별. STOP/NONE은 이동 신호가 아니다.
static func is_move_signal(sig: SignalType) -> bool:
	return sig == SignalType.ADVANCE \
		or sig == SignalType.TURN_LEFT \
		or sig == SignalType.TURN_RIGHT
