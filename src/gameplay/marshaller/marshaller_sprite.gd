extends Sprite3D
## 마샬러 2.5D 빌보드 스프라이트. 현재 수신호에 맞춰 텍스처를 바꿔 낀다.
## 판정에는 관여하지 않고 SignalInput의 현재 값을 그대로 시각화한다 (signal_indicator_hud.gd와 동일 패턴).

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

var _signal_input: SignalInputScript
var _textures: Dictionary = {}

func _ready() -> void:
	_signal_input = SceneQuery.get_singleton(get_tree(), GameGroups.SIGNAL_INPUT, "MarshallerSprite")
	for sig in ICON_PATHS:
		_textures[sig] = load(ICON_PATHS[sig])
	texture = _textures[SignalInputScript.SignalType.NONE]

func _process(_delta: float) -> void:
	if _signal_input == null:
		return
	var current: SignalInputScript.SignalType = _signal_input.get_signal()
	var tex: Texture2D = _textures.get(current)
	if tex != null and tex != texture:
		texture = tex
