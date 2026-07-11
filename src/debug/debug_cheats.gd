extends Node
## 개발용 치트 입력. 디버그 빌드에서만 동작하며 릴리스에서는 스스로 꺼진다.
##  - F1: 다음 레벨로 강제 스킵 (캠페인에 위임)
##  - F2: 플레이어 무적 토글 (GameManager의 debug_invincible — hazard 충돌을 무시)
## 키 안내는 디버그 HUD 좌측 상단에 표시된다.

var _campaign: Node
var _game_manager: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		set_process_input(false)
		return
	_campaign = SceneQuery.require_single(GameGroups.CAMPAIGN_MANAGER)
	_game_manager = SceneQuery.require_single(GameGroups.GAME_MANAGER)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_next_level"):
		if _campaign != null and not _campaign.is_complete:
			_campaign.next_level()
	elif event.is_action_pressed("debug_invincible"):
		if _game_manager != null:
			_game_manager.debug_invincible = not _game_manager.debug_invincible
