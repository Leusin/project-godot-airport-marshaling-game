class_name CollisionShapes
extends RefCounted
## 노드의 보이는 모델(첫 MeshInstance3D의 메쉬 AABB)에서 XZ 충돌 사각형 반크기를 뽑는다.
## 충돌 판정(aircraft_collision)과 디버그 시각화(collision_debug_visual)가 같은 소스를 써서
## "그려진 박스 = 실제 판정 범위" 를 보장한다.

const DEFAULT_HALF_EXTENT := 0.5

## 노드의 첫 MeshInstance3D 메쉬 AABB에서 XZ 반크기(Vector2).
static func half_extents_xz(node: Node) -> Vector2:
	var mesh_instance := find_mesh_instance(node)
	if mesh_instance == null or mesh_instance.mesh == null:
		return Vector2(DEFAULT_HALF_EXTENT, DEFAULT_HALF_EXTENT)
	var mesh_size := mesh_instance.mesh.get_aabb().size
	return Vector2(mesh_size.x, mesh_size.z) * 0.5

## 노드 자신 또는 하위에서 첫 MeshInstance3D를 찾는다.
static func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := find_mesh_instance(child)
		if found != null:
			return found
	return null
