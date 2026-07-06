extends Sprite3D
## 마샬러 2.5D 빌보드 스프라이트. 현재 수신호에 맞춰 텍스처를 바꿔 낀다.
## 판정에는 관여하지 않고 SignalInput / GameManager의 현재 값을 그대로 시각화한다
## (signal_indicator_hud.gd와 동일 패턴).
## 비행기가 주차존에 완전히 들어와 확정 대기 상태면, 평소 신호와 무관하게
## 엔진 정지(확정) 포즈로 덮어써서 HUD의 확정 아이콘 표시와 짝을 맞춘다.

const SignalInputScript = preload("res://src/gameplay/marshaller/signal_input.gd")
const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")

const ICON_PATHS := {
	SignalInputScript.SignalType.NONE: "res://assets/sprites/marshaller/signal_none.png",
	SignalInputScript.SignalType.ADVANCE: "res://assets/sprites/marshaller/signal_advance.png",
	SignalInputScript.SignalType.STOP: "res://assets/sprites/marshaller/signal_stop.png",
	SignalInputScript.SignalType.TURN_LEFT: "res://assets/sprites/marshaller/signal_turn_left.png",
	SignalInputScript.SignalType.TURN_RIGHT: "res://assets/sprites/marshaller/signal_turn_right.png",
}
const SHUTDOWN_ICON_PATH := "res://assets/sprites/marshaller/signal_shutdown.png"

var _signal_input: SignalInputScript
var _game_manager: Node
var _textures: Dictionary = {}
var _shutdown_texture: Texture2D

func _ready() -> void:
	_signal_input = SceneQuery.get_singleton(get_tree(), GameGroups.SIGNAL_INPUT, "MarshallerSprite")
	_game_manager = SceneQuery.get_singleton(get_tree(), GameGroups.GAME_MANAGER, "MarshallerSprite")
	for sig in ICON_PATHS:
		_textures[sig] = load(ICON_PATHS[sig])
	_shutdown_texture = load(SHUTDOWN_ICON_PATH)
	texture = _textures[SignalInputScript.SignalType.NONE]

func _process(_delta: float) -> void:
	if _signal_input == null:
		return

	if _game_manager != null and _game_manager.is_awaiting_shutdown_confirm:
		if texture != _shutdown_texture:
			texture = _shutdown_texture
		return

	var current: SignalInputScript.SignalType = _signal_input.get_signal()
	var tex: Texture2D = _textures.get(current)
	if tex != null and tex != texture:
		texture = tex
