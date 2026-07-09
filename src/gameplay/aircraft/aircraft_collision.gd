extends Area3D
## 비행기 충돌/도착 감지. Godot Area3D 겹침으로 판정한다
## 모든 콜리전 도형을 Y로 길게(tall) 만들어 세로는 항상 겹치므로, 실질적으로 XZ 평면 판정 =
## 기존 탑다운 방식과 동일하고 도형의 Y 정렬 튜닝이 필요 없다.
## - hazard 레이어(장애물·마샬러) 진입 → 게임오버 (area_entered)
## - parking 레이어: 겹치는 동안 비행기 AABB가 주차존 AABB에 완전히 포함되면(AABB.encloses) 확정 대기
## shutdown_confirmed(스페이스) 이벤트는 확정 대기 상태에서만 성공 유예를 시작한다.

## 콜리전 레이어 번호 (1=aircraft, 2=hazard, 3=parking).
const LAYER_HAZARD := 2
const LAYER_PARKING := 3

var _game_manager: Node
var _signal_input: Node
var _parking_areas: Array[Area3D] = []  # 현재 겹치는 주차 Area3D들
var _is_parked := false

func _ready() -> void:
	_game_manager = SceneQuery.require_single(GameGroups.GAME_MANAGER)
	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	# 엔진정지 확정은 폴링이 아니라 이벤트로 받는다 (물리프레임 just_pressed 유실/중복 방지).
	if _signal_input != null:
		_signal_input.shutdown_confirmed.connect(_on_shutdown_confirmed)
	# GameManager가 없으면 판정 통지할 곳이 없으므로 물리 처리를 끈다 (경고는 require_single이 출력).
	set_physics_process(_game_manager != null)

func _on_area_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(LAYER_HAZARD):
		if _game_manager != null:
			_game_manager.trigger_game_over()
	elif area.get_collision_layer_value(LAYER_PARKING) and area not in _parking_areas:
		_parking_areas.append(area)

func _on_area_exited(area: Area3D) -> void:
	_parking_areas.erase(area)

func _physics_process(_delta: float) -> void:
	var self_aabb := _world_aabb(self)
	var parked := false
	for area in _parking_areas:
		if _world_aabb(area).encloses(self_aabb):
			parked = true
			break
	_is_parked = parked
	_game_manager.set_awaiting_shutdown_confirm(parked)

## 확정 버튼 이벤트. 비행기가 주차존에 완전히 들어온 상태에서만 성공 유예를 시작한다.
func _on_shutdown_confirmed() -> void:
	if _is_parked:
		_game_manager.begin_shutdown_confirm()

## Area3D 첫 CollisionShape3D(BoxShape3D)의 월드 AABB. 회전은 감싸는 AABB로 반영된다.
## (비행기 self / 주차존만 넘어오며 둘 다 BoxShape3D — hazard는 여기 안 옴)
func _world_aabb(area: Area3D) -> AABB:
	var cs := area.get_node("CollisionShape3D") as CollisionShape3D
	var box := cs.shape as BoxShape3D
	return cs.global_transform * AABB(-box.size * 0.5, box.size)
