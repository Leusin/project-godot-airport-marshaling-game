extends Node
## Main 씬 루트 = 조립(배선) 지점. CampaignManager(레벨 교체)와 GameManager(현재 레벨 플레이)를
## 시그널로 잇는다 — 두 매니저는 서로를 직접 참조하지 않고, 연결 관계는 여기 한 곳에만 있다.
## 씬 사이 내비게이션(캠페인 종료 → 로비)도 조립 지점인 여기가 담당한다.

const LOBBY_SCENE := "res://src/ui/lobby/lobby.tscn"

@onready var _campaign: Node = $Systems/CampaignManager
@onready var _game: Node = $Systems/GameManager

func _ready() -> void:
	_campaign.level_loaded.connect(_game.start_level)
	_campaign.campaign_finished.connect(_on_campaign_finished)
	_game.level_completed.connect(_campaign.on_level_completed)
	_game.level_failed.connect(_campaign.on_level_failed)
	_game.advance_requested.connect(_campaign.advance)
	# 배선이 끝난 뒤 첫 레벨을 로드한다.
	_campaign.restart_level()

func _on_campaign_finished() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LOBBY_SCENE)
