extends Node
## 비행기 움직임 실행 컴포넌트. 부모 Aircraft의 명령/설정을 읽어 속도 관성(가속/감속) +
## 회전 + 전진을 매 물리 프레임 부모에 반영한다. 명령/설정 자체의 관리는 Aircraft가 한다.
## 부모가 먼저 명령 딜레이를 해소한 뒤 이 자식이 움직이고(부모 → 자식 실행 순서), 충돌 판정
## 컴포넌트보다 앞에 배치돼 이번 프레임의 위치가 판정에 반영된다.

const AircraftScript = preload("res://src/gameplay/aircraft/aircraft.gd")

@onready var _aircraft: Node3D = get_parent()

var _current_speed: float = 0.0

func get_speed() -> float:
	return _current_speed

func _physics_process(delta: float) -> void:
	var command: AircraftScript.Command = _aircraft.active_command()

	var target_speed: float = _aircraft.max_speed if command == AircraftScript.Command.ADVANCE else 0.0
	if target_speed > _current_speed:
		_current_speed = minf(_current_speed + _aircraft.acceleration * delta, target_speed)
	else:
		_current_speed = maxf(_current_speed - _aircraft.deceleration * delta, target_speed)

	var turn_direction := 0.0
	if command == AircraftScript.Command.TURN_LEFT:
		turn_direction = 1.0
	elif command == AircraftScript.Command.TURN_RIGHT:
		turn_direction = -1.0
	if turn_direction != 0.0:
		_aircraft.rotate_y(deg_to_rad(_aircraft.turn_speed_degrees * turn_direction * delta))

	_aircraft.position += (-_aircraft.global_transform.basis.z) * _current_speed * delta
