extends Control
## 메인 로비(타이틀) 화면. 시작 입력을 받아 메인 게임 씬으로 전환한다.
## 캠페인의 진입점이며, 추후 레벨 선택·설정이 붙을 자리.

const MAIN_SCENE := "res://src/core/main_game/Main.tscn"

const TITLE_COLOR := Color(1.0, 0.9, 0.4)
const SUBTITLE_COLOR := Color(0.8, 0.8, 0.85)
const START_COLOR := Color(0.9, 0.95, 1.0)
const QUIT_COLOR := Color(0.6, 0.6, 0.65)
const VERSION_COLOR := Color(0.5, 0.5, 0.55)
const BG_COLOR := Color(0.08, 0.1, 0.14)

var _version := "0.0.0"

func _ready() -> void:
	_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file(MAIN_SCENE)
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	var cx := size.x
	var cy := size.y / 2.0
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, cy - 60.0), "AIRPORT MARSHALLER SIMULATOR",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 56, TITLE_COLOR)
	draw_string(font, Vector2(0, cy + 70.0), "시작: Enter",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 28, START_COLOR)
	draw_string(font, Vector2(0, cy + 105.0), "종료: ESC",
		HORIZONTAL_ALIGNMENT_CENTER, cx, 20, QUIT_COLOR)
	draw_string(font, Vector2(0, size.y - 24.0), "v" + _version,
		HORIZONTAL_ALIGNMENT_CENTER, cx, 14, VERSION_COLOR)
