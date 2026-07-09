extends MeshInstance3D
## 디버그용 시야 원뿔 시각화. VisionCone 판정 결과에 따라 초록/빨강으로 바닥에 부채꼴을 그린다.
## 실제 게임플레이 로직에는 관여하지 않는다.

const SEGMENTS := 24
const VISUAL_HEIGHT := 0.05

@onready var vision_cone: Node = get_parent().get_node("VisionCone")

# 마샬러는 계층 경로가 아니라 그룹으로 찾는다 (씬 트리 위치에 독립적).
var marshaller: Node3D

var _material := StandardMaterial3D.new()

func _ready() -> void:
	marshaller = SceneQuery.require_single(GameGroups.MARSHALLER)
	# 디버그 시각화 전용이므로 마샬러가 없으면 색상 갱신만 끈다 (부채꼴 메쉬는 그대로 표시).
	if marshaller == null:
		set_process(false)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color(1, 0, 0, 0.35)
	mesh = _build_sector_mesh(vision_cone.half_angle_degrees, vision_cone.view_radius)
	set_surface_override_material(0, _material)

func _process(_delta: float) -> void:
	var in_view: bool = vision_cone.is_point_in_view(marshaller.global_position)
	_material.albedo_color = Color(0, 1, 0, 0.35) if in_view else Color(1, 0, 0, 0.35)

func _build_sector_mesh(half_angle_deg: float, radius: float) -> ArrayMesh:
	var half_angle := deg_to_rad(half_angle_deg)
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()

	verts.append(Vector3(0, VISUAL_HEIGHT, 0))
	for i in range(SEGMENTS + 1):
		var t := -half_angle + (2.0 * half_angle) * (float(i) / float(SEGMENTS))
		var x := sin(t) * radius
		var z := -cos(t) * radius
		verts.append(Vector3(x, VISUAL_HEIGHT, z))

	for i in range(1, SEGMENTS + 1):
		indices.append(0)
		indices.append(i)
		indices.append(i + 1)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh
