extends RefCounted
## XZ 평면 2D 도형 겹침 판정 (탑다운 충돌용).
## OBB(회전 사각형)는 center, half(가로반/세로반), forward(세로축 단위벡터)로 표현한다.

## 분리축 정리(SAT)로 두 OBB가 겹치는지. forward 는 단위벡터여야 한다.
static func obb_overlap(ca: Vector2, ha: Vector2, fa: Vector2, cb: Vector2, hb: Vector2, fb: Vector2) -> bool:
	var ra := Vector2(fa.y, -fa.x)  # a의 가로축 (forward에 수직)
	var rb := Vector2(fb.y, -fb.x)
	var delta := cb - ca
	for axis in [ra, fa, rb, fb]:
		var reach_a := ha.x * absf(ra.dot(axis)) + ha.y * absf(fa.dot(axis))
		var reach_b := hb.x * absf(rb.dot(axis)) + hb.y * absf(fb.dot(axis))
		if absf(delta.dot(axis)) > reach_a + reach_b:
			return false  # 이 축에서 분리됨 → 안 겹침
	return true

## OBB와 원이 겹치는지. 원 중심을 OBB 로컬 좌표로 옮겨 가장 가까운 점까지 거리로 판정.
static func obb_circle_overlap(c: Vector2, h: Vector2, f: Vector2, circle: Vector2, radius: float) -> bool:
	var right := Vector2(f.y, -f.x)
	var d := circle - c
	var local := Vector2(d.dot(right), d.dot(f))
	var closest := Vector2(clampf(local.x, -h.x, h.x), clampf(local.y, -h.y, h.y))
	return local.distance_to(closest) <= radius
