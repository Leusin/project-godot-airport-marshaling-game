extends RefCounted
## 탑다운 카메라의 실제 가시 영역을 계산하는 공용 유틸리티.

## (직교 전용, 틸트/오프셋 미고려) 카메라 orthogonal size + 화면 비율로 절반 크기만 계산.
static func compute_half_extents(camera: Camera3D, viewport: Viewport) -> Vector2:
	var viewport_size := viewport.get_visible_rect().size
	var aspect := viewport_size.x / viewport_size.y
	var half_height := camera.size / 2.0
	var half_width := half_height * aspect
	return Vector2(half_width, half_height)

## 기울어진(틸트) 카메라가 y=0 지면과 만나는 실제 가시 영역을 계산한다.
## 직교/원근 모두 지원. 원근일 때는 화면에 가장 가까운 변(반경이 가장 좁은 변) 기준으로
## 폭을 계산해, 어느 깊이에서도 안전하게 보이는 사각형(내접 사각형)을 반환한다.
## 반환: { "center": Vector2(월드 XZ), "half_extents": Vector2(half_x, half_z) }
static func compute_ground_frustum(camera: Camera3D, viewport: Viewport) -> Dictionary:
	var cam_pos := camera.global_position
	var forward := -camera.global_transform.basis.z
	var height := cam_pos.y
	var tilt := acos(clampf(forward.dot(Vector3.DOWN), -1.0, 1.0))

	var viewport_size := viewport.get_visible_rect().size
	var aspect := viewport_size.x / viewport_size.y

	var dir_xz := Vector2(forward.x, forward.z)
	dir_xz = dir_xz.normalized() if dir_xz.length() > 0.0001 else Vector2(0.0, -1.0)
	var ground_below_cam := Vector2(cam_pos.x, cam_pos.z)

	var half_width: float
	var half_depth: float
	var center: Vector2

	if camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
		var half_vfov := deg_to_rad(camera.fov) / 2.0
		var half_hfov := atan(tan(half_vfov) * aspect)
		var near_angle := tilt - half_vfov
		var far_angle := minf(tilt + half_vfov, deg_to_rad(89.0))
		var depth_near := height * tan(near_angle)
		var depth_far := height * tan(far_angle)
		# 가장 좁은 변(근거리)의 폭을 기준으로 잡아 원거리에서도 항상 시야 안에 들도록 함.
		var slant_near := height / cos(near_angle)
		half_width = slant_near * tan(half_hfov)
		half_depth = (depth_far - depth_near) / 2.0
		center = ground_below_cam + dir_xz * ((depth_near + depth_far) / 2.0)
	else:
		var half_height_ortho := camera.size / 2.0
		half_width = half_height_ortho * aspect
		half_depth = half_height_ortho / cos(tilt)
		center = ground_below_cam + dir_xz * (height * tan(tilt))

	return {"center": center, "half_extents": Vector2(half_width, half_depth)}
