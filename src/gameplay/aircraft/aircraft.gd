extends Node3D
## 비행기의 정체성/설정과 명령 인터페이스를 관리한다.
## 실제 움직임(속도 관성·회전·전진)은 자식 AircraftControl 컴포넌트가 담당한다.
## 언제 어떤 신호를 보낼지(상태 전이)는 AircraftFSM이 판단하고, 신호↔명령 번역은
## 비행기의 구현 세부사항이라 여기서 처리한다 (외부는 신호만 넘긴다).

const CountdownScript = preload("res://src/core/utils/countdown.gd")
const SignalInputScript = preload("res://src/gameplay/marshaller/signal_input.gd")

enum Command { STOP, ADVANCE, TURN_LEFT, TURN_RIGHT }

@export var max_speed: float = 3.0
@export var acceleration: float = 2.0
@export var deceleration: float = 8.0
@export var turn_speed_degrees: float = 25.0
@export var command_delay: float = 0.6

@onready var _control: Node = $AircraftControl

var _active_command: Command = Command.STOP
var _pending_command: Command = Command.STOP
var _delay := CountdownScript.new()

## 딜레이가 지나 실제로 반영 중인 명령. 움직임 담당(AircraftControl)이 매 프레임 읽는다.
func active_command() -> Command:
	return _active_command

## 현재 속도. 실제 값은 움직임 컴포넌트가 들고 있고 여기선 위임만 한다 (FSM의 정지 판정용).
func get_speed() -> float:
	return _control.get_speed()

## 수신호를 받아 내부 명령으로 번역해 예약한다. 외부(FSM)는 신호만 넘기고,
## 신호가 어떤 물리 명령이 되는지는 비행기가 안다.
func issue_signal(sig: SignalInputScript.SignalType) -> void:
	_issue_command(_command_from_signal(sig))

func _command_from_signal(sig: SignalInputScript.SignalType) -> Command:
	match sig:
		SignalInputScript.SignalType.ADVANCE: return Command.ADVANCE
		SignalInputScript.SignalType.TURN_LEFT: return Command.TURN_LEFT
		SignalInputScript.SignalType.TURN_RIGHT: return Command.TURN_RIGHT
		_: return Command.STOP

func _issue_command(command: Command) -> void:
	if command == _pending_command:
		return
	_pending_command = command
	_delay.start(command_delay)

## 명령 딜레이(반응 지연) 해소만 담당한다. 부모는 자식보다 먼저 실행되므로,
## 여기서 갱신한 _active_command를 같은 프레임에 AircraftControl이 읽어 움직인다.
func _physics_process(delta: float) -> void:
	if _delay.tick(delta):
		_active_command = _pending_command
