extends Control
## 캠페인 완료 화면. 전 레벨 클리어 후(campaign.is_complete) 레벨별 등급 요약을 전체 화면으로
## 보여준다. 캠페인 상태를 읽어 표시만 하고, 진행(로비 복귀)은 기존 확인 입력 경로가 처리한다.

const TITLE_COLOR := Color(0.3, 1.0, 0.3)
const LEVEL_COLOR := Color(0.85, 0.85, 0.9)
const GRADE_COLOR := Color(1.0, 0.9, 0.4)
const PROMPT_COLOR := Color(0.8, 0.8, 0.8)
const BG_COLOR := Color(0.02, 0.08, 0.05, 0.92)
const ROW_HEIGHT := 38.0

var _campaign: Node

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_campaign = SceneQuery.require_single(GameGroups.CAMPAIGN_MANAGER)

func _process(_delta: float) -> void:
	visible = _campaign != null and _campaign.is_complete
	if visible:
		queue_redraw()

func _draw() -> void:
	if _campaign == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	var font := ThemeDB.fallback_font
	var cx := size.x
	var count: int = _campaign.level_count()
	var rows_height := count * ROW_HEIGHT
	var top := size.y / 2.0 - rows_height / 2.0

	draw_string(font, Vector2(0, top - 60.0), "ALL CLEAR",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 48, TITLE_COLOR)

	# 레벨별 등급 요약: "LEVEL n     등급" 두 열을 중앙 기준으로 나란히.
	for i in count:
		var y := top + i * ROW_HEIGHT + ROW_HEIGHT * 0.7
		var grade = _campaign.grade_of(i)
		var grade_text: String = ParkingGrade.label(grade) if grade != null else "—"
		draw_string(font, Vector2(0, y), "LEVEL %d" % (i + 1),
			HORIZONTAL_ALIGNMENT_RIGHT, cx / 2.0 - 16.0, 24, LEVEL_COLOR)
		draw_string(font, Vector2(cx / 2.0 + 16.0, y), grade_text,
			HORIZONTAL_ALIGNMENT_LEFT, cx / 2.0, 24, GRADE_COLOR)

	draw_string(font, Vector2(0, top + rows_height + 50.0), "로비로 이동하기: 엔터 / ESC",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 24, PROMPT_COLOR)
