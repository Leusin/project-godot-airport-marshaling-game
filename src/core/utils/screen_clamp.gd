extends Node
## 부모 Node3D를 탑다운 카메라 가시 영역 안으로 매 물리 프레임 클램프하는 컴포넌트.
## Marshaller/Aircraft가 각자 부모를 이동시킨 뒤(부모 _physics_process가 자식보다 먼저 실행됨)
## 이 자식 노드가 경계로 되돌린다. 경계 계산은 screen_bounds 유틸을 공유한다.
## 카메라가 기울어져 있으면(원근/직교 모두) 가시 영역 중심이 월드 원점과 다를 수 있으므로
## 중심(center) 기준으로 클램프한다.

const ScreenBoundsScript = preload("res://src/core/utils/screen_bounds.gd")

@export var edge_margin: float = 0.5

@onready var _target: Node3D = get_parent()

var _center: Vector2 = Vector2.ZERO
var _half_x: float = 0.0
var _half_z: float = 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(_update_bounds)
	_update_bounds()

func _update_bounds() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var frustum := ScreenBoundsScript.compute_ground_frustum(camera, get_viewport())
	_center = frustum["center"]
	var half_extents: Vector2 = frustum["half_extents"]
	_half_x = half_extents.x - edge_margin
	_half_z = half_extents.y - edge_margin

func _physics_process(_delta: float) -> void:
	_target.position.x = clampf(_target.position.x, _center.x - _half_x, _center.x + _half_x)
	_target.position.z = clampf(_target.position.z, _center.y - _half_z, _center.y + _half_z)
