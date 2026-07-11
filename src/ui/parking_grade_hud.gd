extends Control
## 주차 등급 라이브 표시 HUD. 확정 가능한 동안 지금 받을 등급(B/A/S/SS)을 우측에 크게 미리 보여준다.
## 판정에 관여하지 않고 판정자(GameManager)가 계산한 프리뷰만 읽어 표시한다(비행기 직접 참조 안 함).

const RIGHT_MARGIN := 24.0
const CENTER_Y_RATIO := 0.26  # 세로: 화면 중앙에서 위쪽
const GRADE_FONT_SIZE := 64
const GRADE_COLOR := Color(1.0, 0.9, 0.4)

var _game_manager: Node

func _ready() -> void:
	_game_manager = SceneQuery.require_single(GameGroups.GAME_MANAGER)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _game_manager == null or not _game_manager.is_awaiting_shutdown_confirm:
		return  # 확정 가능(주차 충분)할 때만 등급을 노출한다.
	var grade: ParkingGrade.Grade = _game_manager.current_grade()

	var font := ThemeDB.fallback_font
	var width := size.x - RIGHT_MARGIN
	var grade_y := size.y * CENTER_Y_RATIO + GRADE_FONT_SIZE
	draw_string(font, Vector2(0.0, grade_y), ParkingGrade.label(grade),
		HORIZONTAL_ALIGNMENT_RIGHT, width, GRADE_FONT_SIZE, GRADE_COLOR)
