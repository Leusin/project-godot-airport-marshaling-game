class_name GameGroups
extends RefCounted
## 씬 그룹 이름 중앙 관리. 문자열을 한 곳에 모아 오타로 인한 조용한 연결 실패를 막는다.
## (.tscn의 groups=[...]는 코드에서 참조 불가라 문자열로 두고, 코드 조회는 모두 이 상수를 쓴다.)

# SYSTEM
const GAME_MANAGER := &"game_manager"
const SIGNAL_INPUT := &"signal_input"
const MOVEMENT_INPUT := &"movement_input"

# ENTITY
const MARSHALLER := &"marshaller"
const AIRCRAFT := &"aircraft"

# HUD LAYER
const GAME_OVER_HUD := &"game_over_hud"
const SUCCESS_HUD := &"success_hud"
