extends Node
## 게임 전체 상태 관리. 충돌 -> 게임 오버 / 주차 완료 -> 유도 성공.
## HUD 참조는 계층 경로가 아니라 그룹으로 찾는다 (씬 트리 위치에 독립적).

const SceneQuery = preload("res://src/core/utils/scene_query.gd")

var _game_over_hud: Control
var _success_hud: Control

var _is_game_over: bool = false
var _is_success: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game_over_hud = SceneQuery.get_singleton(get_tree(), "game_over_hud", "GameManager")
	_success_hud = SceneQuery.get_singleton(get_tree(), "success_hud", "GameManager")

func trigger_game_over() -> void:
	if _is_game_over or _is_success:
		return
	_is_game_over = true
	if _game_over_hud != null:
		_game_over_hud.show_game_over()
	get_tree().paused = true

func trigger_success() -> void:
	if _is_success or _is_game_over:
		return
	_is_success = true
	if _success_hud != null:
		_success_hud.show_success()
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if not (_is_game_over or _is_success):
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
		get_tree().reload_current_scene()
