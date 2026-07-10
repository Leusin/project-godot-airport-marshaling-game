class_name MarshallerMovement
extends RefCounted

## 이동 의도를 속도로 바꿔 물리 이동시킨다. 장애물(StaticBody3D) 블로킹은 move_and_slide가 처리.
func update(body: CharacterBody3D, direction: Vector3, speed: float):
	body.velocity = direction * speed
	body.move_and_slide()
