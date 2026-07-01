extends Node
## 비행기 충돌/도착 감지. Area3D 시그널 대신 XZ 거리 기반으로 매 물리 프레임 검사한다.
## (Node3D 부모를 직접 이동시키는 구조에서 Area3D entered 시그널이 불안정하기 때문)

@export var hit_radius: float = 1.5
@export var park_radius: float = 1.5

@onready var _aircraft: Node3D = get_parent()
@onready var _game_manager: Node = get_parent().get_parent().get_node("GameManager")
@onready var _marshaller: Node3D = get_parent().get_parent().get_node("Marshaller")
@onready var _parking: Node3D = get_parent().get_parent().get_node("ParkingSpot")
@onready var _obstacle: Node3D = get_parent().get_parent().get_node("Obstacle")

func _physics_process(_delta: float) -> void:
	var ap := Vector2(_aircraft.global_position.x, _aircraft.global_position.z)

	if _xz_dist(ap, _parking) < park_radius:
		_game_manager.trigger_success()
		return

	if _xz_dist(ap, _marshaller) < hit_radius:
		_game_manager.trigger_game_over()
		return

	if _xz_dist(ap, _obstacle) < hit_radius:
		_game_manager.trigger_game_over()
		return

func _xz_dist(from: Vector2, to_node: Node3D) -> float:
	return from.distance_to(Vector2(to_node.global_position.x, to_node.global_position.z))
