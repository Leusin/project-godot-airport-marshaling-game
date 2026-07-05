extends Node
## 비행기 정면 기준 70도 시야 원뿔 판정. 마샬러가 원뿔 안에 있는지 bool만 반환한다.
## 판정만 담당하며 상태를 갖지 않는다 (FSM/신호 해석은 AircraftFSM에서 처리).

@export var half_angle_degrees: float = 35.0
@export var view_radius: float = 10.0

func is_point_in_view(point: Vector3) -> bool:
	var aircraft := get_parent() as Node3D
	var offset := point - aircraft.global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > view_radius:
		return false
	if distance < 0.001:
		return true

	var forward := -aircraft.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var angle := rad_to_deg(forward.angle_to(offset.normalized()))
	return angle <= half_angle_degrees
