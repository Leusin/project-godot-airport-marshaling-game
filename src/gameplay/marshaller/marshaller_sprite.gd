extends Sprite3D
## 마샬러 2.5D 빌보드 스프라이트. 판정에 관여하지 않고 Pawn의 hand_signal에 맞춰 텍스처를 바꿔 낀다
## (입력을 직접 보지 않고 Controller가 넣어준 값을 참조).
## 확정 직후 유예 구간(is_confirming_shutdown)에만 평소 신호와 무관하게 엔진정지 포즈로 덮어쓴다.

const ICON_PATHS := {
	HandSignal.SignalType.NONE: "res://assets/sprites/marshaller/signal_none.png",
	HandSignal.SignalType.ADVANCE: "res://assets/sprites/marshaller/signal_advance.png",
	HandSignal.SignalType.STOP: "res://assets/sprites/marshaller/signal_stop.png",
	HandSignal.SignalType.TURN_LEFT: "res://assets/sprites/marshaller/signal_turn_left.png",
	HandSignal.SignalType.TURN_RIGHT: "res://assets/sprites/marshaller/signal_turn_right.png",
}
const SHUTDOWN_ICON_PATH := "res://assets/sprites/marshaller/signal_shutdown.png"

var _marshaller: Marshaller
var _game_manager: Node
var _textures: Dictionary = {}
var _shutdown_texture: Texture2D

func _ready() -> void:
	_marshaller = get_parent_node_3d()
	_game_manager = SceneQuery.require_single(GameGroups.GAME_MANAGER)
	for sig in ICON_PATHS:
		_textures[sig] = load(ICON_PATHS[sig])
	_shutdown_texture = load(SHUTDOWN_ICON_PATH)
	texture = _textures[HandSignal.SignalType.NONE]

func _process(_delta: float) -> void:
	if _marshaller == null:
		return

	if _game_manager != null and _game_manager.is_confirming_shutdown:
		if texture != _shutdown_texture:
			texture = _shutdown_texture
		return

	var current: HandSignal.SignalType = _marshaller.hand_signal
	var tex: Texture2D = _textures.get(current)
	if tex != null and tex != texture:
		texture = tex
