extends Node
## Main 씬 루트 = 조립(배선) 지점. CampaignManager(레벨 교체)와 GameManager(현재 레벨 플레이)를
## 시그널로 잇는다 — 두 매니저는 서로를 직접 참조하지 않고, 연결 관계는 여기 한 곳에만 있다.

@onready var _campaign: Node = $Systems/CampaignManager
@onready var _game: Node = $Systems/GameManager

func _ready() -> void:
	_campaign.level_loaded.connect(_game.start_level)
	_game.level_completed.connect(_campaign.on_level_completed)
	_game.level_failed.connect(_campaign.on_level_failed)
	_game.advance_requested.connect(_campaign.advance)
	# 배선이 끝난 뒤 첫 레벨을 로드한다.
	_campaign.restart_level()
