extends Node
## 이동 입력 전담. 방향키/WASD를 XZ 평면 방향 벡터로 변환만 한다.

func get_move_direction() -> Vector3:
	var input_2d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return Vector3(input_2d.x, 0.0, input_2d.y)
