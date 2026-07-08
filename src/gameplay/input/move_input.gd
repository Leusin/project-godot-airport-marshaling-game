extends Node
## 이동 입력 전담. 방향키/WASD 이벤트에 반응해 현재 XZ 이동 방향을 상태(move_direction)로 보관한다.
## 이동은 연속(hold)이라 소비자(MarshallerControl)가 매 프레임 이 값을 읽어 적용한다.
## 그룹 'move_input'으로 조회된다 (특정 엔티티에 종속되지 않음).

var move_direction: Vector3 = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if not _is_move_event(event):
		return
	# 이벤트 시점의 현재 눌림 상태로 방향을 다시 계산한다 (누름/뗌 모두 반영).
	var input_2d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_direction = Vector3(input_2d.x, 0.0, input_2d.y)

func _is_move_event(event: InputEvent) -> bool:
	return event.is_action("move_left") or event.is_action("move_right") \
		or event.is_action("move_up") or event.is_action("move_down")
