extends Node3D
## 마샬러 이동만 담당. 입력은 MoveInput에서 받아온다.

const MoveInputScript = preload("res://src/gameplay/marshaller/move_input.gd")

@export var speed: float = 5.0

@onready var move_input: MoveInputScript = $MoveInput

func _physics_process(delta: float) -> void:
	var direction := move_input.get_move_direction()
	if direction != Vector3.ZERO:
		position += direction * speed * delta
