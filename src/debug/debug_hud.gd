extends Control
## 개발용 디버그 오버레이. 화면 우상단에 버전 / FPS / 비행기 FSM 상태 / 현재 수신호를 표시.
## DebugLayer(layer 128, Process Mode Always) 아래라 일시정지 중에도 갱신된다.
## 개발 빌드에서는 ` (백틱) 키로 껐다 켤 수 있고, 릴리스 빌드에서는 아예 숨긴다.

const RIGHT_MARGIN := 12.0
const TOP_MARGIN := 24.0
const LINE_HEIGHT := 20.0
const FONT_SIZE := 16
const TEXT_COLOR := Color(0.9, 0.9, 0.95, 0.85)

var _version := "0.0.0"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

	if not OS.is_debug_build():
		visible = false
		set_process(false)
		set_process_input(false)
		return

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var lines := PackedStringArray()
	lines.append("v%s   %d FPS" % [_version, Engine.get_frames_per_second()])
	lines.append_array(_parking_lines())

	for index in lines.size():
		var baseline := TOP_MARGIN + index * LINE_HEIGHT
		draw_string(font, Vector2(0.0, baseline), lines[index],
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - RIGHT_MARGIN, FONT_SIZE, TEXT_COLOR)

## 비행기가 주차존과 겹치는 동안의 정확도 수치(겹침·위치·각도)를 만든다. 겹침이 없으면 "PARK —".
## 등급 자체는 실제 게임 HUD(ParkingGradeHUD)가 표시하고, 여기선 튜닝용 원자료만 보여준다.
func _parking_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var aircraft := get_tree().get_first_node_in_group(GameGroups.AIRCRAFT)
	if aircraft == null or not aircraft.has_method("parking_metrics"):
		return lines
	var metrics: Dictionary = aircraft.parking_metrics()
	if metrics.is_empty():
		lines.append("PARK  —")
		return lines
	lines.append("overlap %d%%" % roundi(metrics["overlap_ratio"] * 100.0))
	lines.append("pos %.2f m" % metrics["position_error"])
	lines.append("ang %.1f deg" % metrics["angle_error"])
	return lines
