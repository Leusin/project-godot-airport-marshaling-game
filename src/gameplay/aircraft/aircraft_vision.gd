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
	
func contains(point: Vector3) -> bool:
	var offset := point - self.global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > _radius:
		return false
	if distance < COINCIDENT_EPSILON:
		return true

	var forward := global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var angle := rad_to_deg(forward.angle_to(offset.normalized()))
	return angle <= _half_angle

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
