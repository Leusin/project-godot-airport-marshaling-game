class_name Aircraft
extends Node3D
## 비행기 Pawn. 정체성/설정과 명령 인터페이스를 관리하고, 자기 시야로 마샬러를 관찰해
## "받은 수신호"를 제공한다. 실제 움직임(속도 관성·회전·전진)은 자식 AircraftMovement가 담당한다.
## 언제 어떤 신호를 보낼지(상태 전이)는 AircraftFSM이 판단하고, 신호↔명령 번역은
## 비행기의 구현 세부사항이라 여기서 처리한다 (FSM은 받은 신호만 읽고 명령만 넘긴다).

enum Command { STOP, ADVANCE, TURN_LEFT, TURN_RIGHT }

@export var max_speed: float = 3.0
@export var acceleration: float = 2.0
@export var deceleration: float = 8.0
@export var turn_speed_degrees: float = 25.0
@export var command_delay: float = 0.6

@onready var _movement: Node = $AircraftMovement
@onready var _vision_cone: Node = $VisionCone

var _marshaller: Node3D

var _active_command: Command = Command.STOP
var _pending_command: Command = Command.STOP
var _delay := Countdown.new()

func _ready() -> void:
	# 마샬러는 계층 경로가 아니라 그룹으로 찾는다 (씬 트리 위치에 독립적).
	_marshaller = SceneQuery.require_single(GameGroups.MARSHALLER)

## 마샬러가 현재 시야 원뿔 안에 있는지. 시야 밖은 무신호(NONE)보다 엄격히 다뤄지므로 별도 노출.
func sees_marshaller() -> bool:
	return _marshaller != null and _vision_cone.is_point_in_view(_marshaller.global_position)

## 비행기가 지금 마샬러로부터 "받은" 수신호. 시야 밖이면 못 받으므로 NONE.
## FSM은 SignalInput을 직접 보지 않고 이 값을 읽어 상태를 갱신한다.
func received_signal() -> HandSignal.SignalType:
	if not sees_marshaller():
		return HandSignal.SignalType.NONE
	return _marshaller.hand_signal

## 딜레이가 지나 실제로 반영 중인 명령. 움직임 담당(AircraftMovement)이 매 프레임 읽는다.
func active_command() -> Command:
	return _active_command

## 현재 속도. 실제 값은 움직임 컴포넌트가 들고 있고 여기선 위임만 한다 (FSM의 정지 판정용).
func get_speed() -> float:
	return _movement.get_speed()

## 수신호를 받아 내부 명령으로 번역해 예약한다. 외부(FSM)는 신호만 넘기고,
## 신호가 어떤 물리 명령이 되는지는 비행기가 안다.
func issue_signal(sig: HandSignal.SignalType) -> void:
	_issue_command(_command_from_signal(sig))

func _command_from_signal(sig: HandSignal.SignalType) -> Command:
	match sig:
		HandSignal.SignalType.ADVANCE: return Command.ADVANCE
		HandSignal.SignalType.TURN_LEFT: return Command.TURN_LEFT
		HandSignal.SignalType.TURN_RIGHT: return Command.TURN_RIGHT
		_: return Command.STOP

func _issue_command(command: Command) -> void:
	if command == _pending_command:
		return
	_pending_command = command
	_delay.start(command_delay)

## 명령 딜레이(반응 지연) 해소만 담당한다. 부모는 자식보다 먼저 실행되므로,
## 여기서 갱신한 _active_command를 같은 프레임에 AircraftMovement가 읽어 움직인다.
func _physics_process(delta: float) -> void:
	if _delay.tick(delta):
		_active_command = _pending_command
