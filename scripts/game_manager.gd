extends Node
## 게임 전체 상태 관리. 충돌 -> 게임 오버 / 주차 완료 -> 유도 성공.

@onready var _game_over_hud: Control = get_node("../HUD/GameOverHUD")
@onready var _success_hud: Control = get_node("../HUD/SuccessHUD")

var _is_game_over: bool = false
var _is_success: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func trigger_game_over() -> void:
	if _is_game_over or _is_success:
		return
	_is_game_over = true
	_game_over_hud.show_game_over()
	get_tree().paused = true

func trigger_success() -> void:
	if _is_success or _is_game_over:
		return
	_is_success = true
	_success_hud.show_success()
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if not (_is_game_over or _is_success):
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
		get_tree().reload_current_scene()
