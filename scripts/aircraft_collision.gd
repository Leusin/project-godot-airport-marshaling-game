extends Area3D
## 비행기 충돌 감지. 마샬러 또는 장애물과 겹치면 GameManager에 게임 오버를 알린다.

@onready var _game_manager: Node = get_node("../../GameManager")

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("collision_marshaller") or area.is_in_group("collision_obstacle"):
		_game_manager.trigger_game_over()
