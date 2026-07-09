class_name Marshaller
extends Node3D

signal move_intent_changed(direction: Vector3)
signal hand_signal_changed(sig: HandSignal.SignalType)

@export var speed: float = 5.0

## 정규화된 XZ 이동 방향(0이면 정지). 소유자(Controller)가 밀어넣는다.
var move_intent: Vector3 = Vector3.ZERO

## 현재 수신 중인 수신호. 소유자(Controller)가 밀어넣고, 스프라이트가 읽어 시각화한다.
var hand_signal: HandSignal.SignalType = HandSignal.SignalType.NONE

var _movement := MarshallerMovement.new()

## 이동 의도를 갱신한다. 바뀐 경우에만 move_intent_changed를 방출해 이동 컴포넌트를 깨운다.
func set_move_intent(direction: Vector3) -> void:
	if direction == move_intent:
		return
	move_intent = direction
	move_intent_changed.emit(move_intent)

## 수신호를 갱신한다. 바뀐 경우에만 hand_signal_changed를 방출한다.
func set_hand_signal(sig: HandSignal.SignalType) -> void:
	if sig == hand_signal:
		return
	hand_signal = sig
	hand_signal_changed.emit(hand_signal)

func _process(delta: float) -> void:
	_movement.update(self, move_intent, speed, delta)
