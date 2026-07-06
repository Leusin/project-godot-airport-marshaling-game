extends Control
## 마샬러가 현재 입력 중인 수신호를 화면에 아이콘으로 표시하는 HUD.
## 판정에는 관여하지 않고 SignalInput의 현재 값을 그대로 시각화한다.
##   - 하단 중앙: 가능한 모든 신호를 나열, 현재 신호만 밝게 강조 (강조 자체가 현재 신호 표시를 겸함)
## 아이콘은 제공받은 마샬링 수신호 참고 이미지를 그대로 잘라 쓴다 (assets/sprites/hud_icons/).

const SignalInputScript = preload("res://src/gameplay/marshaller/signal_input.gd")
const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")

const DIM_ALPHA := 0.35
const ROW_ICON_SIZE := 70.0
const ROW_GAP := 14.0
const ROW_BOTTOM_MARGIN := 24.0

# 화면 중앙에 나열할 순서 (게임플레이에서 실제로 가능한 신호)
const ROW_SIGNALS: Array = [
	SignalInputScript.SignalType.NONE,
	SignalInputScript.SignalType.ADVANCE,
	SignalInputScript.SignalType.STOP,
	SignalInputScript.SignalType.TURN_LEFT,
	SignalInputScript.SignalType.TURN_RIGHT,
]
const ICON_PATHS := {
	SignalInputScript.SignalType.NONE: "res://assets/sprites/hud_icons/signal_none.png",
	SignalInputScript.SignalType.ADVANCE: "res://assets/sprites/hud_icons/signal_advance.png",
	SignalInputScript.SignalType.STOP: "res://assets/sprites/hud_icons/signal_stop.png",
	SignalInputScript.SignalType.TURN_LEFT: "res://assets/sprites/hud_icons/signal_turn_left.png",
	SignalInputScript.SignalType.TURN_RIGHT: "res://assets/sprites/hud_icons/signal_turn_right.png",
}

var _signal_input: SignalInputScript
var _textures: Dictionary = {}

func _ready() -> void:
	_signal_input = SceneQuery.get_singleton(get_tree(), GameGroups.SIGNAL_INPUT, "SignalIndicator")
	for sig in ICON_PATHS:
		_textures[sig] = load(ICON_PATHS[sig])

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _signal_input == null:
		return
	var current: SignalInputScript.SignalType = _signal_input.get_signal()

	# 하단 중앙: 가능한 모든 신호를 가로로 나열, 현재 신호만 강조 (화면 정중앙은 시야를 가려 하단으로 배치)
	var total_width := ROW_SIGNALS.size() * ROW_ICON_SIZE + (ROW_SIGNALS.size() - 1) * ROW_GAP
	var start_x := size.x / 2.0 - total_width / 2.0
	var row_y := size.y - ROW_ICON_SIZE - ROW_BOTTOM_MARGIN
	for i in ROW_SIGNALS.size():
		var sig: SignalInputScript.SignalType = ROW_SIGNALS[i]
		var is_active := sig == current
		var icon_rect := Rect2(start_x + i * (ROW_ICON_SIZE + ROW_GAP), row_y, ROW_ICON_SIZE, ROW_ICON_SIZE)
		if is_active:
			icon_rect = icon_rect.grow(8.0)
		_draw_icon(icon_rect, sig, 1.0 if is_active else DIM_ALPHA)

func _draw_icon(rect: Rect2, sig: SignalInputScript.SignalType, alpha: float) -> void:
	var tex: Texture2D = _textures.get(sig)
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, alpha))
