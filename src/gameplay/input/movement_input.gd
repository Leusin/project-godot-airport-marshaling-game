extends Node
## 이동 입력 전담(디바이스 계층). 방향키/WASD 이벤트로 XZ 이동 방향을 move_direction에 보관하고
## 바뀔 때 move_direction_changed를 방출한다. 특정 엔티티에 종속되지 않고 PlayerController가
## possess한 Pawn으로 라우팅한다. 그룹 'movement_input'으로 조회 (SignalInput과 동일 패턴).

signal move_direction_changed(direction: Vector3)

## 입력 액션명. project.godot의 InputMap 키와 일치해야 한다 (오타로 인한 조용한 실패 방지).
const ACTION_LEFT := &"move_left"
const ACTION_RIGHT := &"move_right"
const ACTION_UP := &"move_up"
const ACTION_DOWN := &"move_down"

var move_direction: Vector3 = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if not _is_move_event(event):
		return
	# 이벤트 시점의 현재 눌림 상태로 방향을 다시 계산한다 (누름/뗌 모두 반영).
	var input_2d := Input.get_vector(ACTION_LEFT, ACTION_RIGHT, ACTION_UP, ACTION_DOWN)
	var current := Vector3(input_2d.x, 0.0, input_2d.y)
	if current != move_direction:
		move_direction = current
		move_direction_changed.emit(move_direction)

func _is_move_event(event: InputEvent) -> bool:
	return event.is_action(ACTION_LEFT) or event.is_action(ACTION_RIGHT) \
		or event.is_action(ACTION_UP) or event.is_action(ACTION_DOWN)
