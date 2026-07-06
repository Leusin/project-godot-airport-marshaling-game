extends Control
## 마샬러가 현재 입력 중인 수신호를 화면에 픽토그램으로 표시하는 HUD.
## 판정에는 관여하지 않고 SignalInput의 현재 값을 그대로 시각화한다.
##   - 상단 중앙: 현재 신호를 큰 아이콘으로 강조
##   - 화면 중앙: 가능한 모든 신호를 나열, 현재 신호만 밝게 강조
## 아이콘은 노란 사각형 배경 + 검은 사람 실루엣 + 빨간 배트로, 실제 마샬링 수신호 표를 참고했다.

const SignalInputScript = preload("res://src/gameplay/marshaller/signal_input.gd")
const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")

const BG_COLOR := Color(0.98, 0.82, 0.05)
const OUTLINE_COLOR := Color(0.05, 0.05, 0.05)
const BAT_COLOR := Color(0.82, 0.1, 0.1)
const DIM_ALPHA := 0.35

const TOP_ICON_SIZE := 96.0
const TOP_MARGIN := 20.0
const ROW_ICON_SIZE := 60.0
const ROW_GAP := 16.0
const LABEL_FONT_SIZE := 14

# 화면 중앙에 나열할 순서 (게임플레이에서 실제로 가능한 신호)
const ROW_SIGNALS: Array = [
	SignalInputScript.SignalType.NONE,
	SignalInputScript.SignalType.ADVANCE,
	SignalInputScript.SignalType.STOP,
	SignalInputScript.SignalType.TURN_LEFT,
	SignalInputScript.SignalType.TURN_RIGHT,
]
const SIGNAL_LABELS := {
	SignalInputScript.SignalType.NONE: "무신호",
	SignalInputScript.SignalType.ADVANCE: "전진",
	SignalInputScript.SignalType.STOP: "정지",
	SignalInputScript.SignalType.TURN_LEFT: "좌회전",
	SignalInputScript.SignalType.TURN_RIGHT: "우회전",
}

var _signal_input: SignalInputScript
var _style_box := StyleBoxFlat.new()

func _ready() -> void:
	_signal_input = SceneQuery.get_singleton(get_tree(), GameGroups.SIGNAL_INPUT, "SignalIndicator")
	_style_box.bg_color = BG_COLOR
	_style_box.set_corner_radius_all(10)
	_style_box.border_color = OUTLINE_COLOR
	_style_box.set_border_width_all(4)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _signal_input == null:
		return
	var current: SignalInputScript.SignalType = _signal_input.get_signal()

	# 상단 중앙: 현재 신호 강조
	var top_rect := Rect2(size.x / 2.0 - TOP_ICON_SIZE / 2.0, TOP_MARGIN, TOP_ICON_SIZE, TOP_ICON_SIZE)
	_draw_icon(top_rect, current, 1.0)
	_draw_label(top_rect, current, 1.0)

	# 화면 중앙: 가능한 모든 신호 나열, 현재 신호만 강조
	var total_width := ROW_SIGNALS.size() * ROW_ICON_SIZE + (ROW_SIGNALS.size() - 1) * ROW_GAP
	var start_x := size.x / 2.0 - total_width / 2.0
	var row_y := size.y / 2.0 - ROW_ICON_SIZE / 2.0
	for i in ROW_SIGNALS.size():
		var sig: SignalInputScript.SignalType = ROW_SIGNALS[i]
		var is_active := sig == current
		var icon_rect := Rect2(start_x + i * (ROW_ICON_SIZE + ROW_GAP), row_y, ROW_ICON_SIZE, ROW_ICON_SIZE)
		if is_active:
			icon_rect = icon_rect.grow(6.0)
		_draw_icon(icon_rect, sig, 1.0 if is_active else DIM_ALPHA)
		_draw_label(icon_rect, sig, 1.0 if is_active else DIM_ALPHA)

## 픽토그램 하나를 rect 안에 alpha 농도로 그린다. 100x100 디자인 좌표계를 rect에 맞춰 스케일한다.
func _draw_icon(rect: Rect2, sig: SignalInputScript.SignalType, alpha: float) -> void:
	var bg := _style_box.duplicate()
	bg.bg_color = Color(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, alpha)
	bg.border_color = Color(OUTLINE_COLOR.r, OUTLINE_COLOR.g, OUTLINE_COLOR.b, alpha)
	draw_style_box(bg, rect)

	var outline := Color(OUTLINE_COLOR.r, OUTLINE_COLOR.g, OUTLINE_COLOR.b, alpha)
	var bat := Color(BAT_COLOR.r, BAT_COLOR.g, BAT_COLOR.b, alpha)
	var scale := rect.size.x / 100.0
	var to_screen := func(p: Vector2) -> Vector2: return rect.position + p * scale
	var line_w := 4.0 * scale

	# 머리 + 몸통
	draw_circle(to_screen.call(Vector2(50, 32)), 13.0 * scale, outline)
	draw_line(to_screen.call(Vector2(50, 45)), to_screen.call(Vector2(50, 78)), outline, line_w)
	# 다리
	draw_line(to_screen.call(Vector2(50, 78)), to_screen.call(Vector2(40, 96)), outline, line_w)
	draw_line(to_screen.call(Vector2(50, 78)), to_screen.call(Vector2(60, 96)), outline, line_w)

	match sig:
		SignalInputScript.SignalType.ADVANCE:
			# 양팔을 곧게 위로, 배트가 더 위로 뻗음
			draw_line(to_screen.call(Vector2(50, 52)), to_screen.call(Vector2(32, 18)), outline, line_w)
			draw_line(to_screen.call(Vector2(50, 52)), to_screen.call(Vector2(68, 18)), outline, line_w)
			draw_line(to_screen.call(Vector2(32, 18)), to_screen.call(Vector2(28, -2)), bat, line_w * 1.3)
			draw_line(to_screen.call(Vector2(68, 18)), to_screen.call(Vector2(72, -2)), bat, line_w * 1.3)
		SignalInputScript.SignalType.STOP:
			# 양팔을 위로 올려 머리 위에서 배트가 X자로 교차
			draw_line(to_screen.call(Vector2(50, 52)), to_screen.call(Vector2(38, 22)), outline, line_w)
			draw_line(to_screen.call(Vector2(50, 52)), to_screen.call(Vector2(62, 22)), outline, line_w)
			draw_line(to_screen.call(Vector2(30, 8)), to_screen.call(Vector2(70, 26)), bat, line_w * 1.3)
			draw_line(to_screen.call(Vector2(70, 8)), to_screen.call(Vector2(30, 26)), bat, line_w * 1.3)
		SignalInputScript.SignalType.TURN_LEFT:
			# 오른팔(화면 우측)은 위로 꺾어 배트를 세우고, 왼팔은 옆으로 뻗어 배트를 가리킴
			draw_line(to_screen.call(Vector2(50, 52)), to_screen.call(Vector2(66, 30)), outline, line_w)
			draw_line(to_screen.call(Vector2(66, 30)), to_screen.call(Vector2(66, 6)), bat, line_w * 1.3)
			draw_line(to_screen.call(Vector2(50, 58)), to_screen.call(Vector2(18, 58)), outline, line_w)
			draw_line(to_screen.call(Vector2(18, 58)), to_screen.call(Vector2(0, 58)), bat, line_w * 1.3)
		SignalInputScript.SignalType.TURN_RIGHT:
			# 좌회전의 좌우 반전
			draw_line(to_screen.call(Vector2(50, 52)), to_screen.call(Vector2(34, 30)), outline, line_w)
			draw_line(to_screen.call(Vector2(34, 30)), to_screen.call(Vector2(34, 6)), bat, line_w * 1.3)
			draw_line(to_screen.call(Vector2(50, 58)), to_screen.call(Vector2(82, 58)), outline, line_w)
			draw_line(to_screen.call(Vector2(82, 58)), to_screen.call(Vector2(100, 58)), bat, line_w * 1.3)
		_:
			# 무신호: 팔을 몸에 붙인 채 대기
			draw_line(to_screen.call(Vector2(50, 52)), to_screen.call(Vector2(38, 76)), outline, line_w)
			draw_line(to_screen.call(Vector2(50, 52)), to_screen.call(Vector2(62, 76)), outline, line_w)

func _draw_label(rect: Rect2, sig: SignalInputScript.SignalType, alpha: float) -> void:
	var text: String = SIGNAL_LABELS.get(sig, "")
	var font := ThemeDB.fallback_font
	var text_color := Color(1.0, 1.0, 1.0, alpha)
	draw_string(font, Vector2(rect.position.x, rect.position.y + rect.size.y + LABEL_FONT_SIZE + 2.0),
		text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, LABEL_FONT_SIZE, text_color)
