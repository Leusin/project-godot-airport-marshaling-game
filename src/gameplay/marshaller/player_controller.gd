extends Node
## 플레이어 컨트롤러. Marshaller Pawn을 possess하고, 디바이스 입력(MovementInput/SignalInput)을
## possess한 Pawn의 상태로 라우팅한다(push). 언리얼의 PlayerController ↔ Pawn 관계.
## Pawn은 스폰한 주체(GameManager)가 possess()로 넣어준다 — 스스로 찾지 않고, 없으면 라우팅만 쉰다.
## 이 노드만 AI 컨트롤러로 갈아끼우면 같은 Pawn을 코드가 조종할 수 있다(입력과 무관하게).

var _pawn: Node
var _movement_input: Node
var _signal_input: Node

func _ready() -> void:
	# 입력 원천은 각각 독립적으로 연결한다 (하나가 없어도 나머지는 동작).
	_movement_input = SceneQuery.require_single(GameGroups.MOVEMENT_INPUT)
	if _movement_input != null:
		_movement_input.move_direction_changed.connect(_on_move_direction_changed)
	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	if _signal_input != null:
		_signal_input.hand_signal_changed.connect(_on_hand_signal_changed)

## Pawn을 possess하고 현재 입력 상태를 1회 동기화한다(possess 이전의 입력 이벤트를 놓쳤으므로).
func possess(pawn: Node) -> void:
	_pawn = pawn
	if _pawn == null:
		return
	if _movement_input != null:
		_pawn.set_move_intent(_movement_input.move_direction)
	if _signal_input != null:
		_pawn.set_hand_signal(_signal_input.get_signal())

func _on_move_direction_changed(direction: Vector3) -> void:
	if _pawn != null:
		_pawn.set_move_intent(direction)

func _on_hand_signal_changed(sig: HandSignal.SignalType) -> void:
	if _pawn != null:
		_pawn.set_hand_signal(sig)
