extends Sprite3D
## 마샬러 2.5D 빌보드 스프라이트. 현재 수신호에 맞춰 텍스처를 바꿔 낀다.
## 판정에는 관여하지 않고 Pawn(Marshaller)이 받은 수신호 / GameManager의 현재 값을 그대로 시각화한다.
## 입력(SignalInput)을 직접 보지 않고, Controller가 Pawn에 넣어준 hand_signal을 참조한다.
## 확정 버튼(스페이스)을 누른 직후의 짧은 유예 구간에만, 평소 신호와 무관하게
## 엔진 정지(확정) 포즈로 덮어쓴다 (누르기 전 대기 중에는 평소 신호 포즈 유지).

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
