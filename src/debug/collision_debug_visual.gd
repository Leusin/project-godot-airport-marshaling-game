extends MeshInstance3D
## 디버그: 충돌 판정에 쓰는 XZ 사각형을 바닥 위에 선으로 그린다.
## 판정과 같은 소스(CollisionShapes.half_extents_xz)를 쓰므로 "그려진 박스 = 실제 판정 범위".
##   비행기 = 회전하는 사각형(시안), 주차 = 초록, 장애물/마샬러(위험) = 빨강.
## 개발 빌드 전용. ` (백틱 = toggle_debug)로 껐다 켤 수 있다.

const DRAW_HEIGHT := 0.08
const AIRCRAFT_COLOR := Color(0.2, 0.9, 1.0)
const GOAL_COLOR := Color(0.2, 1.0, 0.3)
const HAZARD_COLOR := Color(1.0, 0.3, 0.2)

var _immediate_mesh := ImmediateMesh.new()
var _material := StandardMaterial3D.new()
var _aircraft: Node3D

func _ready() -> void:
	if not OS.is_debug_build():
		set_process(false)
		set_process_input(false)
		visible = false
		return

	process_mode = Node.PROCESS_MODE_ALWAYS  # 일시정지 중에도 토글/표시가 되도록
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	mesh = _immediate_mesh
	material_override = _material
	_aircraft = get_tree().get_first_node_in_group(GameGroups.AIRCRAFT)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible

func _process(_delta: float) -> void:
	if not visible:
		return
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	if _aircraft != null:
		var forward := -_aircraft.global_transform.basis.z
		_add_rect(
			_to_xz(_aircraft.global_position),
			CollisionShapes.half_extents_xz(_aircraft),
			Vector2(forward.x, forward.z).normalized(),
			AIRCRAFT_COLOR)

	for parking_spot in get_tree().get_nodes_in_group(GameGroups.PARKING):
		_add_axis_aligned_rect(parking_spot, GOAL_COLOR)
	for hazard in get_tree().get_nodes_in_group(GameGroups.OBSTACLE):
		_add_axis_aligned_rect(hazard, HAZARD_COLOR)
	for hazard in get_tree().get_nodes_in_group(GameGroups.MARSHALLER):
		_add_axis_aligned_rect(hazard, HAZARD_COLOR)

	_immediate_mesh.surface_end()

func _add_axis_aligned_rect(node: Node3D, color: Color) -> void:
	_add_rect(_to_xz(node.global_position), CollisionShapes.half_extents_xz(node), Vector2(0.0, 1.0), color)

## center/half_extents/forward(단위)로 정의한 사각형의 4변을 선으로 추가.
## 코너는 판정과 동일한 Collision2D.obb_corners를 써서 "그려진 박스 = 실제 판정 범위"를 보장한다.
func _add_rect(center: Vector2, half_extents: Vector2, forward: Vector2, color: Color) -> void:
	var corners := Collision2D.obb_corners(center, half_extents, forward)
	for i in corners.size():
		_add_line(corners[i], corners[(i + 1) % corners.size()], color)

func _add_line(from: Vector2, to: Vector2, color: Color) -> void:
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(Vector3(from.x, DRAW_HEIGHT, from.y))
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(Vector3(to.x, DRAW_HEIGHT, to.y))

func _to_xz(world_position: Vector3) -> Vector2:
	return Vector2(world_position.x, world_position.z)
