extends Node
## 마샬러 이동 실행 컴포넌트. MoveInput의 방향과 부모 Marshaller의 speed로 부모를 움직인다.
## 입력 해석은 MoveInput(그룹 조회)이, 설정 관리는 Marshaller가 담당한다.

const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")

@onready var _marshaller: Node3D = get_parent()

var _move_input: Node

func _ready() -> void:
	_move_input = SceneQuery.require_single(GameGroups.MOVE_INPUT)
	# MoveInput이 없으면 방향을 못 읽으므로 조용히 비활성화 (경고는 require_single이 출력).
	if _move_input == null:
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	var direction: Vector3 = _move_input.move_direction
	if direction != Vector3.ZERO:
		var speed: float = _marshaller.speed
		_marshaller.position += direction * speed * delta
