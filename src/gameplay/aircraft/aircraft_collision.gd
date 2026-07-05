extends Node
## 비행기 충돌/도착 감지. XZ 거리 기반으로 매 물리 프레임 검사한다.
## (Node3D 부모를 직접 이동시키는 구조에서 Area3D entered 시그널이 불안정하기 때문)
## 대상은 씬 계층 경로가 아니라 그룹으로 찾는다 (트리 위치에 독립적, 다중 배치 지원).
##   parking  그룹 진입 -> 유도 성공
##   marshaller / obstacle 그룹 접촉 -> 게임 오버

@export var hit_radius: float = 1.5
@export var park_radius: float = 1.5

@onready var _aircraft: Node3D = get_parent()

func _physics_process(_delta: float) -> void:
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager == null:
		return

	var ap := Vector2(_aircraft.global_position.x, _aircraft.global_position.z)

	for spot in get_tree().get_nodes_in_group("parking"):
		if _xz_dist(ap, spot) < park_radius:
			game_manager.trigger_success()
			return

	for hazard in get_tree().get_nodes_in_group("marshaller"):
		if _xz_dist(ap, hazard) < hit_radius:
			game_manager.trigger_game_over()
			return

	for hazard in get_tree().get_nodes_in_group("obstacle"):
		if _xz_dist(ap, hazard) < hit_radius:
			game_manager.trigger_game_over()
			return

func _xz_dist(from: Vector2, to_node: Node3D) -> float:
	return from.distance_to(Vector2(to_node.global_position.x, to_node.global_position.z))
