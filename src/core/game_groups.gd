class_name GameGroups
extends RefCounted
## 씬 그룹 이름 중앙 관리. 여러 파일에서 쓰는 그룹 문자열을 한 곳에 모아 오타로 인한
## 조용한 연결 실패를 막는다. (.tscn 의 groups=[...] 는 코드에서 참조할 수 없어 문자열 그대로 두지만,
## 코드 쪽 조회는 모두 이 상수를 쓴다.)

const MARSHALLER := &"marshaller"
const SIGNAL_INPUT := &"signal_input"
const MOVEMENT_INPUT := &"movement_input"
const AIRCRAFT := &"aircraft"
const AIRCRAFT_FSM := &"aircraft_fsm"
const GAME_MANAGER := &"game_manager"
const GAME_OVER_HUD := &"game_over_hud"
const SUCCESS_HUD := &"success_hud"
const OBSTACLE := &"obstacle"
const PARKING := &"parking"
