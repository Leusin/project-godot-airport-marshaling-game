extends Node3D
## 마샬러 Pawn. 정체성/설정(speed)과 "명령받은 이동 의도(move_intent)"만 보유한다.
## 입력은 전혀 모른다 — PlayerController가 possess해 set_move_intent()로 의도를 밀어넣고,
## 자식 MarshallerMovement가 그 의도를 읽어 실제로 움직인다 (Aircraft가 command를 보관하는 것과 대칭).

signal move_intent_changed(direction: Vector3)

@export var speed: float = 5.0

## 정규화된 XZ 이동 방향(0이면 정지). 소유자(Controller)가 밀어넣는다.
var move_intent: Vector3 = Vector3.ZERO

## 이동 의도를 갱신한다. 바뀐 경우에만 move_intent_changed를 방출해 이동 컴포넌트를 깨운다.
func set_move_intent(direction: Vector3) -> void:
	if direction == move_intent:
		return
	move_intent = direction
	move_intent_changed.emit(move_intent)
