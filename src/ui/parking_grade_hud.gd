extends Control
## 주차 등급 라이브 표시 HUD. 비행기가 주차존에 충분히 들어와 확정 가능한 동안, 확정 시 받을
## 등급(B/A/S/SS)을 우측에 큰 글씨로 미리 보여준다(플레이어가 확정 전에 위치를 다듬을 수 있게).
## 판정에는 관여하지 않고, 판정자(GameManager)와 같은 규칙(ParkingGrade)으로 계산한 프리뷰만 그린다.

const RIGHT_MARGIN := 24.0
const CENTER_Y_RATIO := 0.26  # 세로: 화면 중앙에서 위쪽
const GRADE_FONT_SIZE := 64
const GRADE_COLOR := Color(1.0, 0.9, 0.4)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var aircraft := get_tree().get_first_node_in_group(GameGroups.AIRCRAFT)
	if aircraft == null or not aircraft.has_method("parking_metrics"):
		return
	if not aircraft.is_parked_enough():
		return  # 확정 가능(주차 충분)할 때만 등급을 노출한다.
	var metrics: Dictionary = aircraft.parking_metrics()
	if metrics.is_empty():
		return
	var grade := ParkingGrade.evaluate(metrics["position_error"], metrics["angle_error"])

	var font := ThemeDB.fallback_font
	var width := size.x - RIGHT_MARGIN
	var grade_y := size.y * CENTER_Y_RATIO + GRADE_FONT_SIZE
	draw_string(font, Vector2(0.0, grade_y), ParkingGrade.label(grade),
		HORIZONTAL_ALIGNMENT_RIGHT, width, GRADE_FONT_SIZE, GRADE_COLOR)
