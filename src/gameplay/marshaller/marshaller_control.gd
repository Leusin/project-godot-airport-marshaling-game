extends Node
## 마샬러 이동 실행 컴포넌트. MoveInput의 방향과 부모 Marshaller의 speed로 부모를 움직인다.
## 입력 해석은 MoveInput이, 설정 관리는 Marshaller가 담당한다.

const MoveInputScript = preload("res://src/gameplay/input/move_input.gd")

@onready var _marshaller: Node3D = get_parent()
@onready var _move_input: MoveInputScript = $"../MoveInput"

func _physics_process(delta: float) -> void:
	var direction := _move_input.get_move_direction()
	if direction != Vector3.ZERO:
		var speed: float = _marshaller.speed
		_marshaller.position += direction * speed * delta
