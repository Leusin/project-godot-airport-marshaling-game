extends Node
## 마샬러의 수신호를 받아 Aircraft 명령으로 전달한다 (hold-to-move).
## 임시 브릿지: 지금은 시야 밖/무신호(NONE)/정지(STOP)를 모두 정지로 처리하지만,
## NONE과 STOP은 의미가 다르다 (무신호=모호함, STOP=명확한 정지 명령).
## 이 구분을 실제로 다르게 다루는 건 AircraftFSM의 몫이다 (모호한 신호는 멈칫/오해 가능해야 함).

const SignalInputScript = preload("res://scripts/signal_input.gd")
const AircraftScript = preload("res://scripts/aircraft.gd")

@onready var aircraft: Node3D = get_parent()
@onready var vision_cone: Node = get_parent().get_node("VisionCone")
@onready var marshaller: Node3D = get_parent().get_parent().get_node("Marshaller")
@onready var signal_input: SignalInputScript = marshaller.get_node("SignalInput")

func _process(_delta: float) -> void:
	if not vision_cone.is_point_in_view(marshaller.global_position):
		aircraft.issue_command(AircraftScript.Command.STOP)
		return

	var hand_signal: SignalInputScript.SignalType = signal_input.get_signal()
	match hand_signal:
		SignalInputScript.SignalType.ADVANCE:
			aircraft.issue_command(AircraftScript.Command.ADVANCE)
		SignalInputScript.SignalType.TURN_LEFT:
			aircraft.issue_command(AircraftScript.Command.TURN_LEFT)
		SignalInputScript.SignalType.TURN_RIGHT:
			aircraft.issue_command(AircraftScript.Command.TURN_RIGHT)
		SignalInputScript.SignalType.STOP, SignalInputScript.SignalType.NONE:
			aircraft.issue_command(AircraftScript.Command.STOP)
