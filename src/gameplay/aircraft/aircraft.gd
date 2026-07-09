class_name Aircraft
extends Node3D

# 속도
@export var max_speed: float = 3.0
@export var acceleration: float = 2.0
@export var deceleration: float = 8.0
@export var turn_speed_degrees: float = 25.0
@export var command_delay := 0.6

@onready var _fsm := AircraftFSM.new()
@onready var _movement:= AircraftMovement.new()
@onready var _vision_cone: Node = $VisionCone

var _marshaller: Node3D

var _pending_forward := 0.0
var _pending_turn := 0.0
var _forward := 0.0
var _turn := 0.0
var _delay := Countdown.new()

func _ready() -> void:
	# 마샬러는 계층 경로가 아니라 그룹으로 찾는다 (씬 트리 위치에 독립적).
	_marshaller = SceneQuery.require_single(GameGroups.MARSHALLER)

func _process(delta: float) -> void:
	_fsm.update(
		_sees_marshaller(),
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

func _sees_marshaller() -> bool:
	return _marshaller != null and _vision_cone.is_point_in_view(_marshaller.global_position)

## 비행기가 지금 마샬러로부터 "받은" 수신호. 시야 밖이면 못 받으므로 NONE.
func _received_signal() -> HandSignal.SignalType:
	if not _sees_marshaller():
		return HandSignal.SignalType.NONE
	return _marshaller.hand_signal
