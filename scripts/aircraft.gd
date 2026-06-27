extends Node3D
## 비행기 위치/속도/회전 갱신. 딜레이(명령 수신 후 반응 지연) + 관성(가속/감속)으로 움직인다.
## 신호 해석/오인식은 AircraftFSM이 담당하고, 여기서는 Command를 받아 물리적으로만 반영한다.

const ScreenBoundsScript = preload("res://scripts/common/screen_bounds.gd")

enum Command { STOP, ADVANCE, TURN_LEFT, TURN_RIGHT }

@export var max_speed: float = 3.0
@export var acceleration: float = 2.0
@export var deceleration: float = 4.0
@export var turn_speed_degrees: float = 25.0
@export var command_delay: float = 0.6
@export var edge_margin: float = 1.0

var _active_command: Command = Command.STOP
var _pending_command: Command = Command.STOP
var _pending_timer: float = 0.0
var _current_speed: float = 0.0

var _bounds_x: float = 0.0
var _bounds_z: float = 0.0

func issue_command(command: Command) -> void:
	if command == _pending_command:
		return
	_pending_command = command
	_pending_timer = command_delay

func _ready() -> void:
	get_viewport().size_changed.connect(_update_bounds)
	_update_bounds()

func _update_bounds() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var half_extents := ScreenBoundsScript.compute_half_extents(camera, get_viewport())
	_bounds_x = half_extents.x - edge_margin
	_bounds_z = half_extents.y - edge_margin

func _physics_process(delta: float) -> void:
	if _pending_timer > 0.0:
		_pending_timer = maxf(_pending_timer - delta, 0.0)
		if _pending_timer == 0.0:
			_active_command = _pending_command

	var target_speed := max_speed if _active_command == Command.ADVANCE else 0.0
	if target_speed > _current_speed:
		_current_speed = minf(_current_speed + acceleration * delta, target_speed)
	else:
		_current_speed = maxf(_current_speed - deceleration * delta, target_speed)

	var turn_direction := 0.0
	if _active_command == Command.TURN_LEFT:
		turn_direction = 1.0
	elif _active_command == Command.TURN_RIGHT:
		turn_direction = -1.0
	if turn_direction != 0.0:
		rotate_y(deg_to_rad(turn_speed_degrees * turn_direction * delta))

	position += (-global_transform.basis.z) * _current_speed * delta
	position.x = clampf(position.x, -_bounds_x, _bounds_x)
	position.z = clampf(position.z, -_bounds_z, _bounds_z)
