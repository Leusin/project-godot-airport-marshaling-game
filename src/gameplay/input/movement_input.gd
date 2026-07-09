extends Node
## 이동 입력 전담(디바이스 계층). 방향키/WASD 이벤트에 반응해 현재 XZ 이동 방향을
## 상태(move_direction)로 보관하고, 바뀔 때 move_direction_changed를 방출한다.
## 특정 엔티티에 종속되지 않는다 — PlayerController가 이 값을 possess한 Pawn으로 라우팅한다.
## 그룹 'movement_input'으로 조회된다. (SignalInput의 hand_signal_changed와 동일 패턴)

signal move_direction_changed(direction: Vector3)

var move_direction: Vector3 = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if not _is_move_event(event):
		return
	# 이벤트 시점의 현재 눌림 상태로 방향을 다시 계산한다 (누름/뗌 모두 반영).
	var input_2d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current := Vector3(input_2d.x, 0.0, input_2d.y)
	if current != move_direction:
		move_direction = current
		move_direction_changed.emit(move_direction)

func _is_move_event(event: InputEvent) -> bool:
	return event.is_action("move_left") or event.is_action("move_right") \
		or event.is_action("move_up") or event.is_action("move_down")
