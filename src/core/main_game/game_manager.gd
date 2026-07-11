extends Node
## 현재 레벨 플레이 담당(판정자 + 엔티티 스폰 + HUD 제어). start_level()이 불리면 레벨의 스폰
## 마커(그룹)에서 transform만 읽어 마샬러·비행기를 EntityRoot 아래에 인스턴싱하고 관계를 배선한다.
## 비행기의 사실(hazard 충돌/주차 진입)과 확정 입력을 구독해 승패를 판정하고, 결과는
## level_completed/level_failed 시그널로만 알린다 — 다음 진행(재시작/다음 레벨)은 모른다.

## 레벨 승패 판정 결과. Main이 캠페인으로 잇는다.
signal level_completed(grade: ParkingGrade.Grade)
signal level_failed
## 종료 화면에서 확인 입력(엔터/ESC) = 다음 진행 요청. 해석은 구독자의 몫.
signal advance_requested

## 확정 버튼 → 성공 처리(HUD) 사이 유예. 마샬러 엔진정지 포즈를 잠깐 보여주는 연출용 지연.
const SHUTDOWN_CONFIRM_DELAY := 1.0

## 충돌 → 게임오버 HUD 사이 히트스톱. 정지화면 + 충돌 이펙트로 무슨 일이 났는지 보여주는 연출용 지연.
const HIT_STOP_DELAY := 0.5

## 스폰할 엔티티 씬. 스폰 지점(마커)은 레벨 데이터, 어떤 엔티티를 놓을지는 여기서 정한다.
@export var marshaller_scene: PackedScene
@export var aircraft_scene: PackedScene

var _aircraft: Aircraft
var _signal_input: Node
var _player_controller: Node
var _entity_root: Node3D
var _game_over_hud: Control
var _success_hud: Control
var _hit_effect_hud: Control
var _spawned: Array[Node] = []

var _is_game_over := false
var _is_success := false

## 디버그 무적: 켜져 있으면 hazard 충돌을 게임오버로 해석하지 않는다. DebugCheats가 토글, 디버그 HUD가 표시.
var debug_invincible := false

## 확정 버튼을 누른 순간 채점한 주차 등급 스냅샷. 유예 뒤 위치가 흔들려도 눌렀을 때 값으로 판정한다.
var _final_grade: ParkingGrade.Grade = ParkingGrade.Grade.B

## 비행기가 주차존에 충분히 들어와 확정 버튼(스페이스)만 누르면 되는 상태. HUD가 읽어 표시를 바꾼다.
var is_awaiting_shutdown_confirm := false

## 확정 직후 ~ 성공 처리 전의 짧은 구간. 마샬러 스프라이트가 이 구간에만 엔진정지 포즈를 보여준다.
var is_confirming_shutdown := false

## 충돌 후 히트스톱 중(정지화면 + 이펙트, 게임오버 HUD 대기).
var _is_in_hit_stop := false

var _confirm_delay := Countdown.new()
var _hit_stop_delay := Countdown.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_entity_root = SceneQuery.require_single(GameGroups.ENTITY_ROOT) as Node3D
	_player_controller = SceneQuery.require_single(GameGroups.PLAYER_CONTROLLER)
	_game_over_hud = SceneQuery.require_single(GameGroups.GAME_OVER_HUD)
	_success_hud = SceneQuery.require_single(GameGroups.SUCCESS_HUD)
	_hit_effect_hud = SceneQuery.require_single(GameGroups.HIT_EFFECT_HUD)
	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	if _signal_input != null:
		_signal_input.shutdown_confirmed.connect(_on_shutdown_confirmed)

## 현재 레벨을 (재)시작한다: 이전 엔티티 정리 → 판정 상태 리셋 → 새 스폰 → 일시정지 해제.
## 레벨 씬(스폰 마커 포함)이 로드된 뒤에 호출되는 것이 전제.
func start_level() -> void:
	_despawn_entities()
	_is_game_over = false
	_is_success = false
	is_awaiting_shutdown_confirm = false
	is_confirming_shutdown = false
	_is_in_hit_stop = false
	_hit_stop_delay.stop()
	_final_grade = ParkingGrade.Grade.B
	if _game_over_hud != null:
		_game_over_hud.visible = false
	if _success_hud != null:
		_success_hud.visible = false
	if _hit_effect_hud != null:
		_hit_effect_hud.hide_impact()
	_spawn_entities()
	get_tree().paused = false

## 이전 판의 엔티티를 트리에서 즉시 떼어(그룹 조회·물리에서 바로 빠짐) 해제 예약한다.
func _despawn_entities() -> void:
	for entity in _spawned:
		if is_instance_valid(entity):
			entity.get_parent().remove_child(entity)
			entity.queue_free()
	_spawned.clear()
	_aircraft = null

## 스폰 마커 위치에 엔티티를 스폰하고 관계를 배선한다. 비행기·시야 비주얼이 _ready에서
## 마샬러를 참조할 수 있도록 마샬러를 반드시 먼저 스폰한다.
func _spawn_entities() -> void:
	var marshaller := _spawn_at(marshaller_scene, GameGroups.MARSHALLER_SPAWN) as Marshaller
	_aircraft = _spawn_at(aircraft_scene, GameGroups.AIRCRAFT_SPAWN) as Aircraft
	# 스폰한 주체가 관계를 배선한다: 지각 대상·바라볼 대상·possess.
	if _aircraft != null:
		_aircraft.set_perception_target(marshaller)
		_aircraft.hazard_hit.connect(_on_hazard_hit)
	if marshaller != null:
		marshaller.set_facing_target(_aircraft)
		if _player_controller != null:
			_player_controller.possess(marshaller)

## scene을 EntityRoot 아래에 인스턴싱하고, spawn_group 마커의 transform만 읽어 배치한다.
func _spawn_at(scene: PackedScene, spawn_group: StringName) -> Node3D:
	var spawn := SceneQuery.require_single(spawn_group) as Node3D
	if scene == null or spawn == null or _entity_root == null:
		return null
	var instance := scene.instantiate() as Node3D
	_entity_root.add_child(instance)
	instance.global_transform = spawn.global_transform
	_spawned.append(instance)
	return instance

func _process(delta: float) -> void:
	# 비행기가 주차존에 충분히 들어왔는지 매 프레임 확인 (HUD 확정 아이콘의 근거).
	if _aircraft != null and not (_is_game_over or _is_success):
		is_awaiting_shutdown_confirm = _aircraft.is_parked_enough()
	if is_confirming_shutdown and _confirm_delay.tick(delta):
		is_confirming_shutdown = false
		trigger_success()
	# 히트스톱이 끝나면 게임오버 확정 (정지화면 + 이펙트를 보여준 뒤 HUD).
	if _is_in_hit_stop and _hit_stop_delay.tick(delta):
		_is_in_hit_stop = false
		trigger_game_over()

## 확정 버튼(스페이스) 이벤트. 비행기가 주차존에 충분히 들어온 상태에서만 성공 유예를 시작한다.
## 누른 순간의 사실로 등급을 채점해 스냅샷한다(유예 중 관성으로 움직여도 확정 시점 값 유지).
func _on_shutdown_confirmed() -> void:
	if _aircraft != null and _aircraft.is_parked_enough():
		var metrics := _aircraft.parking_metrics()
		if not metrics.is_empty():
			_final_grade = ParkingGrade.evaluate(metrics["position_error"], metrics["angle_error"])
		begin_shutdown_confirm()

## 확정 버튼이 눌린 순간 호출. SHUTDOWN_CONFIRM_DELAY 후 trigger_success()를 실행한다.
func begin_shutdown_confirm() -> void:
	if _is_success or _is_game_over or is_confirming_shutdown:
		return
	is_confirming_shutdown = true
	_confirm_delay.start(SHUTDOWN_CONFIRM_DELAY)

## 주차 정확도 원자료(겹침·위치·각도). 겹치는 주차존이 없으면 빈 사전. 디버그 HUD가 읽는다.
## (뷰가 비행기를 직접 조회하지 않도록 판정자가 사실을 중계.)
func parking_metrics() -> Dictionary:
	if _aircraft == null:
		return {}
	return _aircraft.parking_metrics()

## 지금 확정하면 받을 등급(라이브 프리뷰). is_awaiting_shutdown_confirm일 때 유효, 등급 HUD가 읽는다.
func current_grade() -> ParkingGrade.Grade:
	var metrics := parking_metrics()
	if metrics.is_empty():
		return ParkingGrade.Grade.B
	return ParkingGrade.evaluate(metrics["position_error"], metrics["angle_error"])

## 충돌 순간: 즉시 게임오버 HUD 대신 히트스톱 — 씬을 정지시키고 충돌 지점에 이펙트를 띄운 뒤,
## HIT_STOP_DELAY 후 trigger_game_over()로 확정한다 (무슨 일이 났는지 보여주는 연출).
func _on_hazard_hit(world_position: Vector3) -> void:
	if debug_invincible or _is_game_over or _is_success or _is_in_hit_stop:
		return
	_is_in_hit_stop = true
	get_tree().paused = true
	if _hit_effect_hud != null:
		_hit_effect_hud.show_impact(world_position)
	_hit_stop_delay.start(HIT_STOP_DELAY)

func trigger_game_over() -> void:
	if debug_invincible:
		return
	if _is_game_over or _is_success:
		return
	_is_game_over = true
	if _game_over_hud != null:
		_game_over_hud.show_game_over()
	get_tree().paused = true
	level_failed.emit()

func trigger_success() -> void:
	if _is_success or _is_game_over:
		return
	_is_success = true
	if _success_hud != null:
		_success_hud.show_success(_final_grade)
	get_tree().paused = true
	level_completed.emit(_final_grade)

## 종료 화면에서 확인 입력 → 진행 요청만 방출. 일시정지는 start_level()이 풀 때까지 유지해
## 전환 프레임에 이전 엔티티가 움직이는 것을 막는다.
func _input(event: InputEvent) -> void:
	if not (_is_game_over or _is_success):
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		advance_requested.emit()
