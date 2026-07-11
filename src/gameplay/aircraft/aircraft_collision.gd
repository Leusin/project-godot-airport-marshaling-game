class_name AircraftCollision
extends RefCounted
## 비행기 히트박스(Area3D) 겹침 판정 컴포넌트. Aircraft가 소유하는 헬퍼(FSM·Movement·Vision과 동일 패턴)로,
## 씬의 콜리전 노드만 보고 판정 결과만 돌려준다. 게임 흐름/입력 연결은 소유자 Aircraft가 처리한다.
## - hazard = 물리 바디(장애물 StaticBody·마샬러 CharacterBody). 진입 → hazard_hit 방출.
## - parking = Area3D. 비행기 풋프린트(XZ)가 주차존과 MIN_PARK_RATIO 이상 겹치면 is_parked_enough()=true.
## 히트박스 mask=6(hazard+parking)이라 감지되는 바디는 전부 hazard, Area는 전부 주차존이다.

## 확정(성공 대기)을 허용하는 최소 겹침 비율. 완전포함을 요구하면 비스듬히 들어온 비행기는
## AABB가 주차존보다 커져 영영 확정이 안 되므로, "대부분 들어옴"으로 완화한다. 정밀도는 등급이 채점.
const MIN_PARK_RATIO := 0.7

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

## 비행기가 어느 주차존에든 충분히(MIN_PARK_RATIO 이상) 들어와 있으면 true. 매 프레임 폴링해도
## 되도록 상태를 캐시하지 않고 현재 트랜스폼으로 즉석 계산한다 (물리/입력 프레임 어디서 불러도 일관).
func is_parked_enough() -> bool:
	return parking_overlap_ratio() >= MIN_PARK_RATIO

## 겹침이 가장 큰 주차존 기준, 비행기 풋프린트(XZ) 중 주차존과 겹치는 비율 0..1.
func parking_overlap_ratio() -> float:
	var self_aabb := _world_aabb(_hitbox)
	var best := 0.0
	for area in _parking_areas:
		best = maxf(best, _footprint_ratio(self_aabb, _world_aabb(area)))
	return best

## 확정 순간 채점용 사실 묶음(겹침이 최대인 주차존 기준). 겹치는 주차존이 없으면 빈 사전.
## - overlap_ratio: 풋프린트 겹침 비율 0..1
## - position_error: 비행기 중심 ↔ 주차존 중심 수평 거리(m)
## - angle_error: 비행기 yaw ↔ 주차존 축 어긋남(도, 0=정렬 · 90=직각). 사각 주차존이라 180° 뒤집힘은 동일 취급.
func parking_metrics() -> Dictionary:
	var self_aabb := _world_aabb(_hitbox)
	var best_area: Area3D = null
	var best_ratio := 0.0
	for area in _parking_areas:
		var ratio := _footprint_ratio(self_aabb, _world_aabb(area))
		if ratio > best_ratio:
			best_ratio = ratio
			best_area = area
	if best_area == null:
		return {}
	var area_aabb := _world_aabb(best_area)
	var self_center := self_aabb.position + self_aabb.size * 0.5
	var area_center := area_aabb.position + area_aabb.size * 0.5
	var pos_error := Vector2(self_center.x - area_center.x, self_center.z - area_center.z).length()
	var yaw_diff := rad_to_deg(absf(wrapf(_hitbox.global_rotation.y - best_area.global_rotation.y, -PI, PI)))
	return {
		"overlap_ratio": best_ratio,
		"position_error": pos_error,
		"angle_error": minf(yaw_diff, 180.0 - yaw_diff),
	}

## 두 AABB의 XZ 풋프린트 겹침 넓이 ÷ a의 풋프린트 넓이 (0..1). Y(세로로 늘린 축)는 무시.
func _footprint_ratio(a: AABB, b: AABB) -> float:
	var inter := a.intersection(b)
	if inter.size.x <= 0.0 or inter.size.z <= 0.0:
		return 0.0
	var self_area := a.size.x * a.size.z
	if self_area <= 0.0:
		return 0.0
	return (inter.size.x * inter.size.z) / self_area

## 감지되는 바디는 전부 hazard 레이어(장애물·마샬러)이므로 진입 = 충돌.
func _on_body_entered(_body: Node3D) -> void:
	hazard_hit.emit()

## Area는 주차존만 넘어온다.
func _on_area_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(CollisionLayers.PARKING) and area not in _parking_areas:
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
