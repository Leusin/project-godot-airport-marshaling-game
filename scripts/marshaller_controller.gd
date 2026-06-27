extends Node3D
## 마샬러 이동만 담당. 입력은 MoveInput에서 받아온다.
## 화면 경계 클램프는 탑다운 카메라의 실제 가시 범위(orthogonal size + 화면 비율)를 기준으로 계산한다.

const MoveInputScript = preload("res://scripts/move_input.gd")

@export var speed: float = 5.0
@export var edge_margin: float = 0.5

@onready var move_input: MoveInputScript = $MoveInput

var bounds_x: float = 0.0
var bounds_z: float = 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(_update_bounds)
	_update_bounds()

func _update_bounds() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / viewport_size.y
	var half_height := camera.size / 2.0
	var half_width := half_height * aspect
	bounds_z = half_height - edge_margin
	bounds_x = half_width - edge_margin

func _physics_process(delta: float) -> void:
	var dir := move_input.get_move_direction()
	if dir != Vector3.ZERO:
		position += dir * speed * delta

	position.x = clampf(position.x, -bounds_x, bounds_x)
	position.z = clampf(position.z, -bounds_z, bounds_z)
