class_name ScreenBounds
extends RefCounted
## 탑다운 카메라의 실제 가시 영역을 계산하는 공용 유틸리티.

## (직교 전용, 틸트/오프셋 미고려) 카메라 orthogonal size + 화면 비율로 절반 크기만 계산.
static func compute_half_extents(camera: Camera3D, viewport: Viewport) -> Vector2:
	var viewport_size := viewport.get_visible_rect().size
	var aspect := viewport_size.x / viewport_size.y
	var half_height := camera.size / 2.0
	var half_width := half_height * aspect
	return Vector2(half_width, half_height)
