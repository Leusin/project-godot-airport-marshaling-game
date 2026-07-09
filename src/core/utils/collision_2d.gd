class_name Collision2D
extends RefCounted
## XZ 평면 2D 도형 겹침 판정 (탑다운 충돌용).
## OBB(회전 사각형)는 center, half_extents(가로반/세로반), forward(세로축 단위벡터)로 표현한다.

## 분리축 정리(SAT)로 두 OBB가 겹치는지. forward 는 단위벡터여야 한다.
static func obb_overlap(
		center_a: Vector2, half_extents_a: Vector2, forward_a: Vector2,
		center_b: Vector2, half_extents_b: Vector2, forward_b: Vector2) -> bool:
	var right_a := Vector2(forward_a.y, -forward_a.x)  # forward_a 에 수직인 가로축
	var right_b := Vector2(forward_b.y, -forward_b.x)
	var offset := center_b - center_a
	for axis in [right_a, forward_a, right_b, forward_b]:
		var reach_a := half_extents_a.x * absf(right_a.dot(axis)) + half_extents_a.y * absf(forward_a.dot(axis))
		var reach_b := half_extents_b.x * absf(right_b.dot(axis)) + half_extents_b.y * absf(forward_b.dot(axis))
		if absf(offset.dot(axis)) > reach_a + reach_b:
			return false  # 이 축에서 분리됨 → 안 겹침
	return true

## OBB와 원이 겹치는지. 원 중심을 OBB 로컬 좌표로 옮겨 가장 가까운 점까지 거리로 판정.
static func obb_circle_overlap(
		center: Vector2, half_extents: Vector2, forward: Vector2,
		circle_center: Vector2, radius: float) -> bool:
	var right := Vector2(forward.y, -forward.x)
	var offset := circle_center - center
	var local := Vector2(offset.dot(right), offset.dot(forward))
	var closest := Vector2(clampf(local.x, -half_extents.x, half_extents.x), clampf(local.y, -half_extents.y, half_extents.y))
	return local.distance_to(closest) <= radius

## 회전하는 OBB의 네 꼭짓점 (월드 좌표).
static func obb_corners(center: Vector2, half_extents: Vector2, forward: Vector2) -> PackedVector2Array:
	var right := Vector2(forward.y, -forward.x)
	return PackedVector2Array([
		center - right * half_extents.x - forward * half_extents.y,
		center + right * half_extents.x - forward * half_extents.y,
		center + right * half_extents.x + forward * half_extents.y,
		center - right * half_extents.x + forward * half_extents.y,
	])

## 회전하는 OBB가 축정렬 사각형(AABB) 안에 완전히 들어와 있는지 (네 꼭짓점 모두 포함되는지로 판정).
static func obb_within_aabb(
		center: Vector2, half_extents: Vector2, forward: Vector2,
		aabb_center: Vector2, aabb_half_extents: Vector2) -> bool:
	for corner in obb_corners(center, half_extents, forward):
		var local := corner - aabb_center
		if absf(local.x) > aabb_half_extents.x or absf(local.y) > aabb_half_extents.y:
			return false
	return true
