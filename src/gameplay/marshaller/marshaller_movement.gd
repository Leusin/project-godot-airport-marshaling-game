class_name MarshallerMovement
extends RefCounted

func update(body: Node3D, direction: Vector3, speed: float, delta: float):
	body.position += direction * speed * delta
