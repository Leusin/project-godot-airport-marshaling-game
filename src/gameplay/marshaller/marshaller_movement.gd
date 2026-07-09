extends Node
## 마샬러 이동 실행 컴포넌트(MovementComponent). 부모 Pawn(Marshaller)의 의도(move_intent)와
## speed만 읽어 매 물리프레임 부모를 움직인다. 입력은 전혀 모른다 — 의도는 PlayerController가 넣어준다.
## 의도가 0이 아닐 때만 physics_process가 켜져 이벤트로 게이팅된다 (정지 중엔 프레임 낭비 없음).

@onready var _marshaller: Node3D = get_parent()

var _direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	_marshaller.move_intent_changed.connect(_on_move_intent_changed)
	# 씬 시작 시점의 의도로 초기 상태를 맞춘다 (보통 정지).
	_direction = _marshaller.move_intent
	set_physics_process(_direction != Vector3.ZERO)

func _on_move_intent_changed(direction: Vector3) -> void:
	_direction = direction
	set_physics_process(_direction != Vector3.ZERO)

func _physics_process(delta: float) -> void:
	_marshaller.position += _direction * _marshaller.speed * delta
