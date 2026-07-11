extends Node
## 게임 전체 상태 관리(판정자 + 엔티티 스폰). 레벨의 스폰 지점(그룹)에 마샬러·비행기를 인스턴싱하고,
## 비행기가 보고하는 사실(hazard 충돌 / 주차 완전 진입)과 확정 버튼 입력을 구독해 게임오버 / 유도 성공을 정한다.
## 엔티티는 게임 규칙을 모르고 사실만 노출 — 해석(판정)은 여기 한 곳에 모인다.

## 확정 버튼 → 성공 처리(HUD) 사이 유예. 마샬러 엔진정지 포즈를 잠깐 보여주는 연출용 지연.
const SHUTDOWN_CONFIRM_DELAY := 1.0

## 스폰할 엔티티 씬. 스폰 지점(마커)은 레벨마다 다르고, 어떤 엔티티를 놓을지는 여기서 정한다.
@export var marshaller_scene: PackedScene
@export var aircraft_scene: PackedScene

var _aircraft: Aircraft
var _signal_input: Node
var _game_over_hud: Control
var _success_hud: Control

var _is_game_over: bool = false
var _is_success: bool = false

## 확정 버튼을 누른 순간 채점한 주차 등급 스냅샷. 유예 뒤 위치가 흔들려도 눌렀을 때 값으로 표시한다.
var _final_grade: ParkingGrade.Grade = ParkingGrade.Grade.B

## 비행기가 주차존에 완전히 들어와 확정 버튼(스페이스)만 누르면 되는 상태. HUD가 읽어 표시를 바꾼다.
var is_awaiting_shutdown_confirm: bool = false

## 확정 직후 ~ 성공 처리 전의 짧은 구간. 마샬러 스프라이트가 이 구간에만 엔진정지 포즈를 보여준다.
var is_confirming_shutdown: bool = false

var _confirm_delay := Countdown.new()

## 확정 버튼이 눌린 순간 호출. SHUTDOWN_CONFIRM_DELAY 후 trigger_success()를 실행한다.
func begin_shutdown_confirm() -> void:
	if _is_success or _is_game_over or is_confirming_shutdown:
		return
	is_confirming_shutdown = true
	_confirm_delay.start(SHUTDOWN_CONFIRM_DELAY)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 엔티티를 먼저 스폰해야 아래 구독과 다른 노드의 그룹 조회(마샬러/비행기)가 성립한다.
	_spawn_entities()
	_game_over_hud = SceneQuery.require_single(GameGroups.GAME_OVER_HUD)
	_success_hud = SceneQuery.require_single(GameGroups.SUCCESS_HUD)
	# 판정자로서 비행기의 사실(충돌/주차)과 확정 입력을 구독한다.
	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	if _aircraft != null:
		_aircraft.hazard_hit.connect(trigger_game_over)
	if _signal_input != null:
		_signal_input.shutdown_confirmed.connect(_on_shutdown_confirmed)

## 레벨의 스폰 지점 마커(그룹)에 엔티티를 인스턴싱한다. 비행기·시야콘 비주얼이 _ready에서
## 마샬러를 그룹으로 찾으므로, 마샬러를 반드시 먼저 스폰한다.
func _spawn_entities() -> void:
	var marshaller := _spawn_at(marshaller_scene, GameGroups.MARSHALLER_SPAWN)
	_aircraft = _spawn_at(aircraft_scene, GameGroups.AIRCRAFT_SPAWN) as Aircraft
	# 스폰한 주체가 관계를 배선한다: 비행기의 지각 대상으로 마샬러를 주입.
	if _aircraft != null:
		_aircraft.set_perception_target(marshaller)

## scene을 spawn_group 마커의 자식으로 붙여 마커의 트랜스폼에 배치한다. 스폰한 인스턴스를 반환.
func _spawn_at(scene: PackedScene, spawn_group: StringName) -> Node3D:
	var spawn := SceneQuery.require_single(spawn_group) as Node3D
	if scene == null or spawn == null:
		return null
	var instance := scene.instantiate()
	spawn.add_child(instance)
	return instance

func _process(delta: float) -> void:
	# 비행기가 주차존에 완전히 들어왔는지 매 프레임 확인 (HUD 확정 아이콘의 근거).
	if _aircraft != null and not (_is_game_over or _is_success):
		is_awaiting_shutdown_confirm = _aircraft.is_parked_enough()
	if is_confirming_shutdown and _confirm_delay.tick(delta):
		is_confirming_shutdown = false
		trigger_success()

## 확정 버튼(스페이스) 이벤트. 비행기가 주차존에 충분히 들어온 상태에서만 성공 유예를 시작한다.
## 누른 순간의 사실로 등급을 채점해 스냅샷한다(유예 중 관성으로 움직여도 확정 시점 값 유지).
func _on_shutdown_confirmed() -> void:
	if _aircraft != null and _aircraft.is_parked_enough():
		var metrics := _aircraft.parking_metrics()
		if not metrics.is_empty():
			_final_grade = ParkingGrade.evaluate(metrics["position_error"], metrics["angle_error"])
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
		_success_hud.show_success(_final_grade)
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if not (_is_game_over or _is_success):
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
		get_tree().reload_current_scene()
