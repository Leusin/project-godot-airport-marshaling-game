class_name AircraftMovement
extends RefCounted

var _current_speed := 0.0

func get_speed() -> float:
	return _current_speed

func update(
	body: Node3D,
	forward: float,
	turn: float,
	max_speed: float,
	acceleration: float,
	deceleration: float,
	turn_speed_degrees: float,
	delta: float
) -> void:

	var target_speed := forward * max_speed

	if target_speed > _current_speed:
		_current_speed = minf(
			_current_speed + acceleration * delta,
			target_speed
		)
	else:
		_current_speed = maxf(
			_current_speed - deceleration * delta,
			target_speed
		)

	if turn != 0.0:
		body.rotate_y(
			deg_to_rad(turn_speed_degrees * turn * delta)
		)

	body.position += body.global_transform.basis.z * _current_speed * delta
