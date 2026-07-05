extends Node
## 비행기 충돌/도착 감지. 매 물리 프레임, 보이는 모델 크기(메쉬 AABB) 기준으로 겹침을 본다.
## (Node3D 부모를 직접 이동시키는 구조에서 Area3D entered 시그널이 불안정해 직접 판정한다.)
## 비행기는 회전하는 사각형(OBB), 대상은 축정렬 사각형으로 보고 SAT로 겹침 판정.
## 대상은 씬 계층 경로가 아니라 그룹으로 찾는다 (트리 위치에 독립적, 다중 배치 지원).
##   parking  그룹 겹침 -> 유도 성공
##   marshaller / obstacle 그룹 겹침 -> 게임 오버

const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const Collision2D = preload("res://src/core/utils/collision_2d.gd")

@onready var _aircraft: Node3D = get_parent()

var _game_manager: Node
var _self_half: Vector2 = Vector2(0.5, 0.5)  # 비행기 XZ 반크기 (메쉬에서 읽음)

func _ready() -> void:
	_game_manager = SceneQuery.get_singleton(get_tree(), "game_manager", "AircraftCollision")
	_self_half = _xz_half_extents(_aircraft)
	# GameManager가 없으면 판정할 대상이 없으므로 물리 처리를 끈다 (경고는 위에서 출력됨).
	set_physics_process(_game_manager != null)

func _physics_process(_delta: float) -> void:
	var center := _xz(_aircraft.global_position)
	var forward := _xz_forward(_aircraft)

	for spot in get_tree().get_nodes_in_group("parking"):
		if _overlaps(center, forward, spot):
			_game_manager.trigger_success()
			return

	for hazard in get_tree().get_nodes_in_group("marshaller"):
		if _overlaps(center, forward, hazard):
			_game_manager.trigger_game_over()
			return

	for hazard in get_tree().get_nodes_in_group("obstacle"):
		if _overlaps(center, forward, hazard):
			_game_manager.trigger_game_over()
			return

## 비행기(OBB) vs 대상(축정렬 사각형) 겹침. 대상은 회전 안 한다고 보고 forward = +Z.
func _overlaps(center: Vector2, forward: Vector2, target: Node3D) -> bool:
	return Collision2D.obb_overlap(
		center, _self_half, forward,
		_xz(target.global_position), _xz_half_extents(target), Vector2(0.0, 1.0))

func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

## 비행기 정면(-Z)을 XZ 단위벡터로.
func _xz_forward(node: Node3D) -> Vector2:
	var f := -node.global_transform.basis.z
	return Vector2(f.x, f.z).normalized()

## 노드의 첫 MeshInstance3D를 찾아 그 메쉬의 XZ 반크기를 반환 (보이는 모델 크기에 맞춤).
func _xz_half_extents(node: Node) -> Vector2:
	var mesh_instance := _find_mesh_instance(node)
	if mesh_instance == null or mesh_instance.mesh == null:
		return Vector2(0.5, 0.5)
	var size := mesh_instance.mesh.get_aabb().size
	return Vector2(size.x, size.z) * 0.5

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found != null:
			return found
	return null
