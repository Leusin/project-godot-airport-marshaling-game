extends Control
## 충돌 이펙트 표시. GameManager가 충돌 월드 좌표로 show_impact를 부르면 화면 좌표로 투영해
## 이펙트 이미지를 띄운다(히트스톱 동안 정지화면 위에 노출). 판정에 관여하지 않는 표시 전용.
## 이미지는 IMPACT_PATH에 있으면 그걸 쓰고, 없으면 임시 스파크 도형을 그린다(그림 교체 가능).

const IMPACT_PATH := "res://assets/sprites/effects/impact.png"
const IMPACT_SIZE := 60.0
const PLACEHOLDER_COLOR := Color(1.0, 0.55, 0.1, 0.95)

var _texture: Texture2D
var _screen_pos := Vector2.ZERO

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(IMPACT_PATH):
		_texture = load(IMPACT_PATH)

## 충돌 지점(월드)을 화면에 투영해 이펙트를 표시한다.
func show_impact(world_position: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	_screen_pos = camera.unproject_position(world_position)
	visible = true
	queue_redraw()

func hide_impact() -> void:
	visible = false

func _draw() -> void:
	if _texture != null:
		var rect := Rect2(_screen_pos - Vector2.ONE * IMPACT_SIZE / 2.0, Vector2.ONE * IMPACT_SIZE)
		draw_texture_rect(_texture, rect, false)
		return
	# 임시 스파크: 8방향 삼각 가시. impact.png를 넣으면 그걸로 대체된다.
	for i in 8:
		var angle := TAU * i / 8.0
		var dir := Vector2.from_angle(angle)
		var side := Vector2.from_angle(angle + TAU / 4.0)
		var tip_len := IMPACT_SIZE * (0.5 if i % 2 == 0 else 0.32)
		draw_colored_polygon(PackedVector2Array([
			_screen_pos + dir * tip_len,
			_screen_pos + side * IMPACT_SIZE * 0.08,
			_screen_pos - side * IMPACT_SIZE * 0.08,
		]), PLACEHOLDER_COLOR)
