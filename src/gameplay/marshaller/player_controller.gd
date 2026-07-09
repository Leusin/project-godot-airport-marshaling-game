extends Node
## 플레이어 컨트롤러. Marshaller Pawn을 possess하고, 디바이스 입력(MovementInput)의 방향을
## possess한 Pawn의 이동 의도로 라우팅한다(push). 언리얼의 PlayerController ↔ Pawn 관계.
## 이 노드만 AI 컨트롤러로 갈아끼우면 같은 Pawn을 코드가 조종할 수 있다(입력과 무관하게).

const SceneQuery = preload("res://src/core/utils/scene_query.gd")
const GameGroups = preload("res://src/core/game_groups.gd")

var _pawn: Node
var _input: Node

func _ready() -> void:
	_pawn = SceneQuery.require_single(GameGroups.MARSHALLER)
	_input = SceneQuery.require_single(GameGroups.MOVEMENT_INPUT)
	# 둘 중 하나라도 없으면 라우팅할 대상/원천이 없으므로 조용히 비활성 (경고는 require_single이 출력).
	if _pawn == null or _input == null:
		return
	_input.move_direction_changed.connect(_on_move_direction_changed)
	# 씬 시작 시 현재 입력 상태를 Pawn에 1회 동기화 (아직 이벤트가 없었으므로).
	_pawn.set_move_intent(_input.move_direction)

func _on_move_direction_changed(direction: Vector3) -> void:
	_pawn.set_move_intent(direction)
