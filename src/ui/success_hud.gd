extends Control
## 유도 성공 시 전체화면 오버레이.
## HudRoot(full-rect Control) 아래에서 full-rect 앵커로 뷰포트 크기를 자동으로 따라간다.

var _grade: ParkingGrade.Grade = ParkingGrade.Grade.B

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func show_success(grade: ParkingGrade.Grade) -> void:
	_grade = grade
	visible = true
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0.25, 0, 0.65))
	var cx := size.x
	var cy := size.y / 2.0
	draw_string(ThemeDB.fallback_font, Vector2(0, cy - 40.0), "CLEAR",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 48, Color(0.3, 1.0, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(0, cy + 30.0), ParkingGrade.label(_grade),
		HORIZONTAL_ALIGNMENT_CENTER, cx, 72, Color(1.0, 0.9, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(0, cy + 90.0), "엔터 / ESC 로 계속",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 24, Color(0.8, 0.8, 0.8))
