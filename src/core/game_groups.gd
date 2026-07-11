class_name GameGroups
extends RefCounted
## 씬 그룹 이름 중앙 관리. 문자열을 한 곳에 모아 오타로 인한 조용한 연결 실패를 막는다.
## (.tscn의 groups=[...]는 코드에서 참조 불가라 문자열로 두고, 코드 조회는 모두 이 상수를 쓴다.)

# SYSTEM
const GAME_MANAGER := &"game_manager"
const CAMPAIGN_MANAGER := &"campaign_manager"
const SIGNAL_INPUT := &"signal_input"
const MOVEMENT_INPUT := &"movement_input"
const PLAYER_CONTROLLER := &"player_controller"

# WORLD ROOT (캠페인이 레벨을 교체하는 슬롯 / GameManager가 엔티티를 스폰하는 슬롯)
const LEVEL_ROOT := &"level_root"
const ENTITY_ROOT := &"entity_root"

# ENTITY
const MARSHALLER := &"marshaller"
const AIRCRAFT := &"aircraft"

# SPAWN (레벨별 스폰 지점 마커 — GameManager가 여기에 엔티티를 인스턴싱한다)
const MARSHALLER_SPAWN := &"marshaller_spawn"
const AIRCRAFT_SPAWN := &"aircraft_spawn"

# HUD LAYER
const GAME_OVER_HUD := &"game_over_hud"
const SUCCESS_HUD := &"success_hud"
