extends Node
## 플레이어 컨트롤러. Marshaller Pawn을 possess하고, 디바이스 입력(MovementInput/SignalInput)을
## possess한 Pawn의 상태로 라우팅한다(push). 언리얼의 PlayerController ↔ Pawn 관계.
## 이 노드만 AI 컨트롤러로 갈아끼우면 같은 Pawn을 코드가 조종할 수 있다(입력과 무관하게).

const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")
const SignalInputScript = preload("res://src/gameplay/input/signal_input.gd")

var _pawn: Node
var _movement_input: Node
var _signal_input: Node

func _ready() -> void:
	_pawn = SceneQuery.require_single(GameGroups.MARSHALLER)
	# possess할 Pawn이 없으면 라우팅할 대상이 없으므로 조용히 비활성 (경고는 require_single이 출력).
	if _pawn == null:
		return

	# 입력 원천은 각각 독립적으로 연결한다 (하나가 없어도 나머지는 동작).
	_movement_input = SceneQuery.require_single(GameGroups.MOVEMENT_INPUT)
	if _movement_input != null:
		_movement_input.move_direction_changed.connect(_on_move_direction_changed)
		# 씬 시작 시 현재 입력 상태를 Pawn에 1회 동기화 (아직 이벤트가 없었으므로).
		_pawn.set_move_intent(_movement_input.move_direction)

	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	if _signal_input != null:
		_signal_input.hand_signal_changed.connect(_on_hand_signal_changed)
		_pawn.set_hand_signal(_signal_input.get_signal())

func _on_move_direction_changed(direction: Vector3) -> void:
	_pawn.set_move_intent(direction)

func _on_hand_signal_changed(sig: SignalInputScript.SignalType) -> void:
	_pawn.set_hand_signal(sig)
