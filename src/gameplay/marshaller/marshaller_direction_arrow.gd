extends Sprite3D
## 좌회전/우회전 신호일 때 마샬러 머리 위에 방향 화살표를 띄운다.
## marshaller_left.png/marshaller_right.png 포즈가 서로 좌우 대칭이라 순간적으로
## 구분하기 어려워서, 확실한 방향 표시로 보완한다 (판정에는 관여하지 않음).

const SignalInputScript = preload("res://src/gameplay/marshaller/signal_input.gd")
const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")

const ARROW_LEFT := preload("res://assets/sprites/marshaller/arrow_left.svg")
const ARROW_RIGHT := preload("res://assets/sprites/marshaller/arrow_right.svg")

var _signal_input: SignalInputScript

func _ready() -> void:
	_signal_input = SceneQuery.get_singleton(get_tree(), GameGroups.SIGNAL_INPUT, "MarshallerDirectionArrow")
	visible = false

func _process(_delta: float) -> void:
	if _signal_input == null:
		return
	match _signal_input.get_signal():
		SignalInputScript.SignalType.TURN_LEFT:
			texture = ARROW_LEFT
			visible = true
		SignalInputScript.SignalType.TURN_RIGHT:
			texture = ARROW_RIGHT
			visible = true
		_:
			visible = false
