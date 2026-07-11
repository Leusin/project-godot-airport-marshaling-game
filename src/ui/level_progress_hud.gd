extends Control
## 레벨 로드맵 HUD. 상단 중앙에 캠페인 레벨 슬롯을 나열해 현재 레벨을 강조하고,
## 클리어한 레벨은 번호 대신 주차 등급(B/A/S/SS)을 보여준다. 캠페인 상태를 읽어 표시만 한다.

const TOP_MARGIN := 16.0
const SLOT_SIZE := 44.0
const SLOT_GAP := 10.0
const NUMBER_FONT_SIZE := 18
const GRADE_FONT_SIZE := 22
const BG_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const BG_CURRENT := Color(0.0, 0.0, 0.0, 0.6)
const BORDER_CURRENT := Color(1.0, 1.0, 1.0, 0.9)
const NUMBER_COLOR := Color(0.9, 0.9, 0.95, 0.75)
const GRADE_COLOR := Color(1.0, 0.9, 0.4)

var _campaign: Node

func _ready() -> void:
	_campaign = SceneQuery.require_single(GameGroups.CAMPAIGN_MANAGER)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _campaign == null:
		return
	var count: int = _campaign.level_count()
	if count == 0:
		return
	var current: int = _campaign.current_level()
	var font := ThemeDB.fallback_font
	var total_width := count * SLOT_SIZE + (count - 1) * SLOT_GAP
	var start_x := size.x / 2.0 - total_width / 2.0
	for i in count:
		var rect := Rect2(start_x + i * (SLOT_SIZE + SLOT_GAP), TOP_MARGIN, SLOT_SIZE, SLOT_SIZE)
		var is_current := i == current
		draw_rect(rect, BG_CURRENT if is_current else BG_COLOR)
		if is_current:
			draw_rect(rect, BORDER_CURRENT, false, 2.0)
		# 클리어한 레벨은 등급, 아니면 레벨 번호.
		var grade = _campaign.grade_of(i)
		var cleared := grade != null
		var text: String = ParkingGrade.label(grade) if cleared else str(i + 1)
		var font_size := GRADE_FONT_SIZE if cleared else NUMBER_FONT_SIZE
		var color := GRADE_COLOR if cleared else NUMBER_COLOR
		var ascent := font.get_ascent(font_size)
		var descent := font.get_descent(font_size)
		var baseline := rect.position.y + (SLOT_SIZE - ascent - descent) * 0.5 + ascent
		draw_string(font, Vector2(rect.position.x, baseline), text,
			HORIZONTAL_ALIGNMENT_CENTER, SLOT_SIZE, font_size, color)
