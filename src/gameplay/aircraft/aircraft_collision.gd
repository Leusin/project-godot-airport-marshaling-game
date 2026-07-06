extends Node
## 비행기 충돌/도착 감지. 매 물리 프레임, 보이는 모델 크기(메쉬 AABB) 기준으로 겹침을 본다.
## (Node3D 부모를 직접 이동시키는 구조에서 Area3D entered 시그널이 불안정해 직접 판정한다.)
## 비행기는 회전하는 사각형(OBB), 대상은 축정렬 사각형으로 보고 SAT로 겹침 판정.
## 대상은 씬 계층 경로가 아니라 그룹으로 찾는다 (트리 위치에 독립적, 다중 배치 지원).
##   parking  그룹: 비행기가 완전히 들어와야(포함) 유도 성공
##   marshaller 그룹: 원형 히트박스로 판정 (사람은 사각형보다 원이 자연스러움) -> 게임 오버
##   obstacle 그룹: 사각형 겹침 -> 게임 오버

const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const Collision2D = preload("res://src/core/utils/collision_2d.gd")
const CollisionShapes = preload("res://src/core/utils/collision_shapes.gd")
const GameGroups = preload("res://src/core/game_groups.gd")

## 마샬러는 3D 모델이 아니라 빌보드 스프라이트라 메쉬 크기를 못 읽으므로 고정 반지름을 쓴다.
const MARSHALLER_HIT_RADIUS := 0.45

@onready var _aircraft: Node3D = get_parent()

var _game_manager: Node
var _self_half_extents := Vector2.ZERO  # 비행기 XZ 반크기 (메쉬에서 읽음)

func _ready() -> void:
	_game_manager = SceneQuery.get_singleton(get_tree(), GameGroups.GAME_MANAGER, "AircraftCollision")
	_self_half_extents = CollisionShapes.half_extents_xz(_aircraft)
	# GameManager가 없으면 판정할 대상이 없으므로 물리 처리를 끈다 (경고는 위에서 출력됨).
	set_physics_process(_game_manager != null)

func _physics_process(_delta: float) -> void:
	var center := _to_xz(_aircraft.global_position)
	var forward := _forward_xz(_aircraft)

	for parking_spot in get_tree().get_nodes_in_group(GameGroups.PARKING):
		if _fully_within(center, forward, parking_spot):
			_game_manager.trigger_success()
			return

	for hazard in get_tree().get_nodes_in_group(GameGroups.MARSHALLER):
		if _hits_marshaller(center, forward, hazard):
			_game_manager.trigger_game_over()
			return

	for hazard in get_tree().get_nodes_in_group(GameGroups.OBSTACLE):
		if _overlaps(center, forward, hazard):
			_game_manager.trigger_game_over()
			return

## 비행기(OBB) vs 대상(축정렬 사각형) 겹침. 대상은 회전 안 한다고 보고 forward = +Z.
func _overlaps(center: Vector2, forward: Vector2, target: Node3D) -> bool:
	return Collision2D.obb_overlap(
		center, _self_half_extents, forward,
		_to_xz(target.global_position), CollisionShapes.half_extents_xz(target), Vector2(0.0, 1.0))

## 비행기(OBB)가 마샬러(원)와 겹치는지.
func _hits_marshaller(center: Vector2, forward: Vector2, marshaller: Node3D) -> bool:
	return Collision2D.obb_circle_overlap(
		center, _self_half_extents, forward, _to_xz(marshaller.global_position), MARSHALLER_HIT_RADIUS)

## 비행기(OBB)가 대상(축정렬 사각형) 안에 완전히 들어와 있는지. 대상은 회전 안 한다고 봄.
func _fully_within(center: Vector2, forward: Vector2, target: Node3D) -> bool:
	return Collision2D.obb_within_aabb(
		center, _self_half_extents, forward,
		_to_xz(target.global_position), CollisionShapes.half_extents_xz(target))

## Vector3의 x, z 만 뽑아 XZ 평면 좌표로.
func _to_xz(world_position: Vector3) -> Vector2:
	return Vector2(world_position.x, world_position.z)

## 비행기 정면(-Z)을 XZ 평면 단위벡터로.
func _forward_xz(node: Node3D) -> Vector2:
	var forward := -node.global_transform.basis.z
	return Vector2(forward.x, forward.z).normalized()
