extends Control
## 개발용 디버그 오버레이. 화면 우상단에 버전 / FPS / 비행기 FSM 상태 / 현재 수신호를 표시.
## DebugLayer(layer 128, Process Mode Always) 아래라 일시정지 중에도 갱신된다.
## 개발 빌드에서는 ` (백틱) 키로 껐다 켤 수 있고, 릴리스 빌드에서는 아예 숨긴다.

const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")
const HandSignal = preload("res://src/gameplay/hand_signal.gd")

const RIGHT_MARGIN := 12.0
const TOP_MARGIN := 24.0
const LINE_HEIGHT := 20.0
const FONT_SIZE := 16
const TEXT_COLOR := Color(0.9, 0.9, 0.95, 0.85)

var _version := "0.0.0"
var _signal_input: Node
var _aircraft_fsm: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

	# 릴리스 빌드에서는 디버그 오버레이를 숨기고 비활성화한다.
	if not OS.is_debug_build():
		visible = false
		set_process(false)
		set_process_input(false)
		return

	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	_aircraft_fsm = SceneQuery.require_single(GameGroups.AIRCRAFT_FSM)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var lines := PackedStringArray()
	lines.append("v%s   %d FPS" % [_version, Engine.get_frames_per_second()])
	if _aircraft_fsm != null:
		lines.append("FSM: %s" % _aircraft_fsm.state_name())
	if _signal_input != null:
		lines.append("SIGNAL: %s" % _current_signal_name())

	var font := ThemeDB.fallback_font
	for index in lines.size():
		var baseline := TOP_MARGIN + index * LINE_HEIGHT
		draw_string(font, Vector2(0.0, baseline), lines[index],
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - RIGHT_MARGIN, FONT_SIZE, TEXT_COLOR)

func _current_signal_name() -> String:
	return HandSignal.SignalType.keys()[_signal_input.get_signal()]
