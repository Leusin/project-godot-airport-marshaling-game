extends Control
## 유도 성공 시 전체화면 오버레이.
## CanvasLayer는 자식 Control에 크기를 주지 않으므로 _ready에서 viewport 크기로 직접 설정.

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)

func _fit_to_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func show_success() -> void:
	visible = true
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0.25, 0, 0.65))
	var cx := size.x
	var cy := size.y / 2.0
	draw_string(ThemeDB.fallback_font, Vector2(0, cy - 10.0), "유도 성공!",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 48, Color(0.3, 1.0, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(0, cy + 50.0), "엔터 / ESC 로 재시작",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 24, Color(0.8, 0.8, 0.8))
