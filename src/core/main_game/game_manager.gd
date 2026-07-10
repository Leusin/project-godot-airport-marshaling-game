extends Node
## 게임 전체 상태 관리(판정자). 비행기가 보고하는 사실(hazard 충돌 / 주차 완전 진입)과
## 확정 버튼 입력을 구독해 게임오버 / 유도 성공을 정한다. 비행기·HUD 참조는 그룹으로 찾는다.
## 엔티티는 게임 규칙을 모르고 사실만 노출 — 해석(판정)은 여기 한 곳에 모인다.

## 확정 버튼을 누른 뒤 실제 성공 처리(HUD 표시)까지의 유예 시간.
## 마샬러의 엔진정지 포즈가 잠깐 보인 뒤 성공 HUD가 뜨도록 하는 연출용 지연.
const SHUTDOWN_CONFIRM_DELAY := 1.0

var _aircraft: Aircraft
var _signal_input: Node
var _game_over_hud: Control
var _success_hud: Control

var _is_game_over: bool = false
var _is_success: bool = false

## 비행기가 주차존에 완전히 들어와 확정 버튼(스페이스)만 누르면 되는 상태.
## GameManager가 매 프레임 비행기에 물어 갱신, HUD가 읽어서 액션 목록을 확정 아이콘 하나로 바꾼다.
var is_awaiting_shutdown_confirm: bool = false

## 확정 버튼을 누른 직후부터 실제 성공 처리 전까지의 짧은 유예 구간.
## 마샬러 스프라이트가 이 구간에서만 엔진정지 포즈를 보여준다.
var is_confirming_shutdown: bool = false

var _confirm_delay := Countdown.new()

## 확정 버튼이 눌린 순간 호출. 즉시 성공 처리하지 않고 SHUTDOWN_CONFIRM_DELAY 만큼
## 기다렸다가 trigger_success()를 실행한다.
func begin_shutdown_confirm() -> void:
	if _is_success or _is_game_over or is_confirming_shutdown:
		return
	is_confirming_shutdown = true
	_confirm_delay.start(SHUTDOWN_CONFIRM_DELAY)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game_over_hud = SceneQuery.require_single(GameGroups.GAME_OVER_HUD)
	_success_hud = SceneQuery.require_single(GameGroups.SUCCESS_HUD)
	# 판정자로서 비행기의 사실(충돌/주차)과 확정 입력을 구독한다.
	_aircraft = SceneQuery.require_single(GameGroups.AIRCRAFT)
	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	if _aircraft != null:
		_aircraft.hazard_hit.connect(trigger_game_over)
	if _signal_input != null:
		_signal_input.shutdown_confirmed.connect(_on_shutdown_confirmed)

func _process(delta: float) -> void:
	# 비행기가 주차존에 완전히 들어왔는지 매 프레임 확인 (HUD 확정 아이콘의 근거).
	if _aircraft != null and not (_is_game_over or _is_success):
		is_awaiting_shutdown_confirm = _aircraft.is_fully_parked()
	if is_confirming_shutdown and _confirm_delay.tick(delta):
		is_confirming_shutdown = false
		trigger_success()

## 확정 버튼(스페이스) 이벤트. 비행기가 주차존에 완전히 들어온 상태에서만 성공 유예를 시작한다.
func _on_shutdown_confirmed() -> void:
	if _aircraft != null and _aircraft.is_fully_parked():
		begin_shutdown_confirm()

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
