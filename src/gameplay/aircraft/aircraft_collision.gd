class_name AircraftCollision
extends RefCounted
## 비행기 히트박스(Area3D) 겹침 판정 컴포넌트. Aircraft가 소유하는 헬퍼(FSM·Movement·Vision과 동일 패턴)로,
## 씬의 콜리전 노드만 보고 판정 결과만 돌려준다. 게임 흐름/입력 연결은 소유자 Aircraft가 처리한다.
## - hazard = 물리 바디(장애물 StaticBody·마샬러 CharacterBody). 진입 → hazard_hit 방출.
## - parking = Area3D. 비행기 AABB가 주차존 AABB에 완전히 포함되면(AABB.encloses) is_fully_parked()=true.
## 히트박스 mask=6(hazard+parking)이라 감지되는 바디는 전부 hazard, Area는 전부 주차존이다.

## 콜리전 레이어 번호 (1=aircraft, 2=hazard, 3=parking, 4=solid).
const LAYER_PARKING := 3

## hazard(장애물·마샬러) 진입 순간 방출. Aircraft가 게임오버로 연결한다.
signal hazard_hit

var _hitbox: Area3D
var _parking_areas: Array[Area3D] = []  # 현재 겹치는 주차 Area3D들

func _init(hitbox: Area3D) -> void:
	_hitbox = hitbox
	hitbox.area_entered.connect(_on_area_entered)
	hitbox.area_exited.connect(_on_area_exited)
	# hazard는 이제 물리 바디(장애물·마샬러)로 들어온다.
	hitbox.body_entered.connect(_on_body_entered)

## 비행기가 어느 주차존에든 완전히 들어와 있으면 true. 매 프레임 폴링해도 되도록 상태를
## 캐시하지 않고 현재 트랜스폼으로 즉석 계산한다 (물리/입력 프레임 어디서 불러도 일관).
func is_fully_parked() -> bool:
	var self_aabb := _world_aabb(_hitbox)
	for area in _parking_areas:
		if _world_aabb(area).encloses(self_aabb):
			return true
	return false

## 감지되는 바디는 전부 hazard 레이어(장애물·마샬러)이므로 진입 = 충돌.
func _on_body_entered(_body: Node3D) -> void:
	hazard_hit.emit()

## Area는 주차존만 넘어온다.
func _on_area_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(LAYER_PARKING) and area not in _parking_areas:
		_parking_areas.append(area)

func _on_area_exited(area: Area3D) -> void:
	_parking_areas.erase(area)

## Area3D의 모든 CollisionShape3D(BoxShape3D)를 합친 월드 AABB. 회전은 감싸는 AABB로 반영된다.
## 히트박스는 복합 형상(동체+날개)이라 여러 셰입을 병합해야 날개 끝까지 포함된다.
## (히트박스 / 주차존만 넘어오며 둘 다 BoxShape3D — hazard는 여기 안 옴)
func _world_aabb(area: Area3D) -> AABB:
	var merged: AABB
	var first := true
	for node in area.find_children("*", "CollisionShape3D"):
		var cs := node as CollisionShape3D
		var box := cs.shape as BoxShape3D
		var world := cs.global_transform * AABB(-box.size * 0.5, box.size)
		if first:
			merged = world
			first = false
		else:
			merged = merged.merge(world)
	return merged
