class_name AircraftCollision
extends RefCounted
## 비행기 히트박스(Area3D) 겹침 판정 컴포넌트. Aircraft가 소유하는 헬퍼(FSM·Movement·VisionCone과 동일 패턴)로,
## 씬의 Area3D 노드만 보고 판정 결과만 돌려준다. 게임 흐름/입력 연결은 소유자 Aircraft가 처리한다.
## 콜리전 도형을 Y로 길게 만들어 세로는 항상 겹치므로 실질적으로 XZ 평면 판정 (Y 정렬 튜닝 불필요).
## - hazard 레이어(장애물·마샬러) 진입 → hazard_hit 방출
## - parking 레이어: 비행기 AABB가 주차존 AABB에 완전히 포함되면(AABB.encloses) is_fully_parked()=true

## 콜리전 레이어 번호 (1=aircraft, 2=hazard, 3=parking).
const LAYER_HAZARD := 2
const LAYER_PARKING := 3

## hazard(장애물·마샬러) 진입 순간 방출. Aircraft가 게임오버로 연결한다.
signal hazard_hit

var _hitbox: Area3D
var _parking_areas: Array[Area3D] = []  # 현재 겹치는 주차 Area3D들

func _init(hitbox: Area3D) -> void:
	_hitbox = hitbox
	hitbox.area_entered.connect(_on_area_entered)
	hitbox.area_exited.connect(_on_area_exited)

## 비행기가 어느 주차존에든 완전히 들어와 있으면 true. 매 프레임 폴링해도 되도록 상태를
## 캐시하지 않고 현재 트랜스폼으로 즉석 계산한다 (물리/입력 프레임 어디서 불러도 일관).
func is_fully_parked() -> bool:
	var self_aabb := _world_aabb(_hitbox)
	for area in _parking_areas:
		if _world_aabb(area).encloses(self_aabb):
			return true
	return false

func _on_area_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(LAYER_HAZARD):
		hazard_hit.emit()
	elif area.get_collision_layer_value(LAYER_PARKING) and area not in _parking_areas:
		_parking_areas.append(area)

func _on_area_exited(area: Area3D) -> void:
	_parking_areas.erase(area)

## Area3D 첫 CollisionShape3D(BoxShape3D)의 월드 AABB. 회전은 감싸는 AABB로 반영된다.
## (히트박스 / 주차존만 넘어오며 둘 다 BoxShape3D — hazard는 여기 안 옴)
func _world_aabb(area: Area3D) -> AABB:
	var cs := area.get_node("CollisionShape3D") as CollisionShape3D
	var box := cs.shape as BoxShape3D
	return cs.global_transform * AABB(-box.size * 0.5, box.size)
