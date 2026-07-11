class_name AircraftVision
extends MeshInstance3D

const VISION_SHADER := preload("res://src/shaders/aircraft_vision.gdshader")
const COINCIDENT_EPSILON := 0.001

var _radius := 10.0
var _half_angle := 35.0
@export var color_seen := Color(0, 1, 0, 0.3)
@export var color_not_seen := Color(1, 0, 0, 0.3)

var _material: ShaderMaterial

func setup(radius: float, half_angle: float):
	_radius = radius
	_half_angle = half_angle
	_rebuild()

func set_seen(seen: bool):
	_material.set_shader_parameter(
		"vision_color",
		color_seen if seen else color_not_seen
	)
	
## 대상이 실제로 보이는가: 반경 → 각도 → 시야선(장애물 차폐) 순으로, 하나라도 실패하면 안 보임.
func can_see(target: Node3D) -> bool:
	if not _inside_radius(target):
		return false
	if not _inside_angle(target):
		return false
	if not _has_line_of_sight(target):
		return false
	return true

## XZ 평면상 대상까지의 오프셋(Y 무시).
func _planar_offset(target: Node3D) -> Vector3:
	var offset := target.global_position - global_position
	offset.y = 0.0
	return offset

func _inside_radius(target: Node3D) -> bool:
	return _planar_offset(target).length() <= _radius

func _inside_angle(target: Node3D) -> bool:
	var offset := _planar_offset(target)
	if offset.length() < COINCIDENT_EPSILON:
		return true  # 거의 겹치면 각도는 의미 없음 → 통과
	var forward := global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	return rad_to_deg(forward.angle_to(offset.normalized())) <= _half_angle

## 비행기→대상 사이에 solid(장애물)이 없으면 true. solid만 마스킹하므로 마샬러(hazard)·비행기 자신은
## 레이에 안 걸려 self exclude 불필요. 장애물이 가리면 시야 원뿔 안이어도 못 본다.
func _has_line_of_sight(target: Node3D) -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position, target.global_position, CollisionLayers.bit(CollisionLayers.SOLID))
	return space.intersect_ray(query).is_empty()

func _ready():
	_material = ShaderMaterial.new()
	_material.shader = VISION_SHADER
	material_override = _material
	_rebuild()

func _rebuild():
	var quad := mesh as QuadMesh
	quad.size = Vector2(_radius * 2.0, _radius * 2.0)

	_material.set_shader_parameter("radius", _radius)
	_material.set_shader_parameter("half_angle", _half_angle)
