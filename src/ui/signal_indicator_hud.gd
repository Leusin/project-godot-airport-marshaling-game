extends Control
## 마샬러가 현재 입력 중인 수신호를 화면에 아이콘으로 표시하는 HUD.
## 판정에는 관여하지 않고 SignalInput / GameManager의 현재 값을 그대로 시각화한다.
##   - 평소: 하단 중앙에 가능한 모든 신호를 나열, 현재 신호만 밝게 강조
##   - 비행기가 주차존에 완전히 들어와 확정 대기 상태면: 목록 대신 확정(엔진 정지) 아이콘 하나만 표시
## 아이콘은 제공받은 마샬링 수신호 참고 이미지를 그대로 잘라 쓴다 (assets/sprites/hud_icons/).

const SignalInputScript = preload("res://src/gameplay/input/signal_input.gd")
const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")

const DIM_ALPHA := 0.35
const ROW_ICON_SIZE := 70.0
const ROW_GAP := 14.0
const ROW_BOTTOM_MARGIN := 24.0
const CONFIRM_ICON_SIZE := 110.0

# 하단에 나열할 순서 (게임플레이에서 실제로 가능한 신호)
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
const CONFIRM_ICON_PATH := "res://assets/sprites/hud_icons/signal_shutdown.png"

var _signal_input: SignalInputScript
var _game_manager: Node
var _textures: Dictionary = {}
var _confirm_texture: Texture2D

func _ready() -> void:
	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	_game_manager = SceneQuery.require_single(GameGroups.GAME_MANAGER)
	for sig in ICON_PATHS:
		_textures[sig] = load(ICON_PATHS[sig])
	_confirm_texture = load(CONFIRM_ICON_PATH)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _signal_input == null:
		return

	if _game_manager != null and _game_manager.is_awaiting_shutdown_confirm:
		_draw_confirm_prompt()
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
		_draw_texture(_textures.get(sig), icon_rect, 1.0 if is_active else DIM_ALPHA)

## 비행기가 주차존에 완전히 들어와 확정 대기 상태일 때: 가능한 액션이 확정 하나뿐이므로
## 목록 대신 그 아이콘만 하단 중앙에 크게 표시.
func _draw_confirm_prompt() -> void:
	var rect := Rect2(size.x / 2.0 - CONFIRM_ICON_SIZE / 2.0,
		size.y - CONFIRM_ICON_SIZE - ROW_BOTTOM_MARGIN, CONFIRM_ICON_SIZE, CONFIRM_ICON_SIZE)
	_draw_texture(_confirm_texture, rect, 1.0)

func _draw_texture(tex: Texture2D, rect: Rect2, alpha: float) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, alpha))
