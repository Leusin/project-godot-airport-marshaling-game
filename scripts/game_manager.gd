extends Node
## 게임 전체 상태 관리. 충돌 이벤트 수신 -> 게임 오버 / 재시작.

@onready var _game_over_hud: Control = get_node("../HUD/GameOverHUD")

var _is_game_over: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func trigger_game_over() -> void:
	if _is_game_over:
		return
	_is_game_over = true
	_game_over_hud.show_game_over()
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if not _is_game_over:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
		get_tree().reload_current_scene()
