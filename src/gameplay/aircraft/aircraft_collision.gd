extends Node
## 비행기 충돌/도착 감지. XZ 거리 기반으로 매 물리 프레임 검사한다.
## (Node3D 부모를 직접 이동시키는 구조에서 Area3D entered 시그널이 불안정하기 때문)
## 대상은 씬 계층 경로가 아니라 그룹으로 찾는다 (트리 위치에 독립적, 다중 배치 지원).
##   parking  그룹 진입 -> 유도 성공
##   marshaller / obstacle 그룹 접촉 -> 게임 오버

const SceneQuery = preload("res://src/core/utils/scene_query.gd")

@export var hit_radius: float = 1.5
@export var park_radius: float = 1.5

@onready var _aircraft: Node3D = get_parent()

var _game_manager: Node

func _ready() -> void:
	_game_manager = SceneQuery.get_singleton(get_tree(), "game_manager", "AircraftCollision")
	# GameManager가 없으면 판정할 대상이 없으므로 물리 처리를 끈다 (경고는 위에서 출력됨).
	set_physics_process(_game_manager != null)

func _physics_process(_delta: float) -> void:
	var ap := Vector2(_aircraft.global_position.x, _aircraft.global_position.z)

	for spot in get_tree().get_nodes_in_group("parking"):
		if _xz_dist(ap, spot) < park_radius:
			_game_manager.trigger_success()
			return

	for hazard in get_tree().get_nodes_in_group("marshaller"):
		if _xz_dist(ap, hazard) < hit_radius:
			_game_manager.trigger_game_over()
			return

	for hazard in get_tree().get_nodes_in_group("obstacle"):
		if _xz_dist(ap, hazard) < hit_radius:
			_game_manager.trigger_game_over()
			return

func _xz_dist(from: Vector2, to_node: Node3D) -> float:
	return from.distance_to(Vector2(to_node.global_position.x, to_node.global_position.z))
