class_name Aircraft
extends Node3D

# 속도
@export_group("Movement")
@export var max_speed: float = 3.0
@export var acceleration: float = 2.0
@export var deceleration: float = 8.0
@export var turn_speed_degrees: float = 25.0
@export var command_delay := 0.6

#시야
@export_group("Vision")
@export var view_radius: float = 8.0
@export var half_angle_degrees: float = 35.0

## hazard(장애물·마샬러) 충돌 순간 방출. "게임오버"인지의 해석은 GameManager의 몫.
signal hazard_hit

var _see_marshaller: bool

@onready var _fsm := AircraftFSM.new()
@onready var _movement:= AircraftMovement.new()
@onready var _collision := AircraftCollision.new($AircraftHitbox)
@onready var _vision: AircraftVision = $AircraftVision

## 지각 대상(수신호 소스): global_position + hand_signal 을 가진 무언가. GameManager가 주입한다.
## 엔티티가 스스로 peer를 찾지 않으며, 없으면 대기한다.
var _target: Node3D

var _pending_forward := 0.0
var _pending_turn := 0.0
var _forward := 0.0
var _turn := 0.0
var _delay := Countdown.new()

func _ready() -> void:
	_collision.hazard_hit.connect(hazard_hit.emit)
	_vision.setup(view_radius, half_angle_degrees)

## GameManager가 스폰 직후 지각 대상을 주입한다 (엔티티는 배선을 스스로 하지 않는다).
func set_perception_target(target: Node3D) -> void:
	_target = target

func _process(delta: float) -> void:
	if _target == null:
		return  # 볼 대상이 없으면 명령을 받지 않고 대기한다.
	var seen := _vision.contains(_target.global_position)
	if seen != _see_marshaller:
		_see_marshaller = seen
		_vision.set_seen(seen)
	
	_fsm.update(
		_see_marshaller,
		_received_signal(),
		_movement.get_speed(),
		delta)
	
	var next_forward := _fsm.forward()
	var next_turn := _fsm.turn()
	
	# 명령이 바뀌면 예약하고 딜레이 시작.
	if next_forward != _pending_forward or next_turn != _pending_turn:
		_pending_forward = next_forward
		_pending_turn = next_turn
		_delay.start(command_delay)

	# 딜레이가 끝나면 실제 명령 적용.
	if _delay.tick(delta):
		_forward = _pending_forward
		_turn = _pending_turn
	
func _physics_process(delta: float) -> void:
	_movement.update(
		self,
		_forward,
		_turn,
		max_speed,
		acceleration,
		deceleration,
		turn_speed_degrees,
		delta
	)

func is_fully_parked() -> bool:
	return _collision.is_fully_parked()

func _received_signal() -> HandSignal.SignalType:
	if not _see_marshaller:
		return HandSignal.SignalType.NONE
	return _target.hand_signal
