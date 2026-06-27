extends Node
## 디버그 전용. AircraftFSM/SignalInput이 구현되기 전까지 Aircraft에 명령을 순환 전달해
## 딜레이+관성 동작을 눈으로 확인하기 위한 임시 스크립트. FSM이 만들어지면 제거한다.

const AircraftScript = preload("res://scripts/aircraft.gd")

@onready var aircraft: Node3D = get_parent()

var _sequence: Array = [
	[AircraftScript.Command.ADVANCE, 3.0],
	[AircraftScript.Command.STOP, 1.5],
	[AircraftScript.Command.TURN_LEFT, 1.5],
	[AircraftScript.Command.STOP, 1.0],
	[AircraftScript.Command.ADVANCE, 2.0],
	[AircraftScript.Command.TURN_RIGHT, 2.0],
	[AircraftScript.Command.STOP, 1.0],
]
var _index: int = 0
var _timer: float = 0.0

func _ready() -> void:
	_apply_step(0)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_apply_step((_index + 1) % _sequence.size())

func _apply_step(index: int) -> void:
	_index = index
	aircraft.issue_command(_sequence[_index][0])
	_timer = _sequence[_index][1]
