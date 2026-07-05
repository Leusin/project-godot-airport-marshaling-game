extends RefCounted
## 초 단위 카운트다운. 매 프레임 tick(delta)로 줄이고, 0에 도달한 그 프레임에 한 번만 true.
## 프레임 폴링 로직(FSM 전이, 명령 딜레이)에서 손으로 돌리던 `t -= delta; if t <= 0` 패턴을 대체.

var _remaining: float = 0.0

func start(duration: float) -> void:
	_remaining = maxf(duration, 0.0)

func stop() -> void:
	_remaining = 0.0

func is_running() -> bool:
	return _remaining > 0.0

## delta만큼 진행. 이번 호출에 0에 '도달'하면 true (한 번만). 멈춰 있으면 false.
func tick(delta: float) -> bool:
	if _remaining <= 0.0:
		return false
	_remaining = maxf(_remaining - delta, 0.0)
	return _remaining == 0.0
