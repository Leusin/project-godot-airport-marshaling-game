extends Control
## 마샬러가 현재 입력 중인 수신호를 화면에 아이콘으로 표시하는 HUD.
## 판정에는 관여하지 않고 SignalInput의 현재 값을 그대로 시각화한다.

const SignalInputScript = preload("res://src/gameplay/marshaller/signal_input.gd")

# SignalInput은 계층 경로가 아니라 그룹으로 찾는다 (씬 트리 위치에 독립적).
var _signal_input: SignalInputScript

func _ready() -> void:
	_signal_input = get_tree().get_first_node_in_group("signal_input")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _signal_input == null:
		return

	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 4.0
	var hand_signal: SignalInputScript.SignalType = _signal_input.get_signal()

	match hand_signal:
		SignalInputScript.SignalType.ADVANCE:
			draw_circle(center, radius, Color(0.2, 0.8, 0.2, 0.85))
			_draw_arrow(center, radius * 0.6, 0.0)
		SignalInputScript.SignalType.STOP:
			draw_circle(center, radius, Color(0.9, 0.15, 0.15, 0.85))
			_draw_x(center, radius * 0.5)
		SignalInputScript.SignalType.TURN_LEFT:
			draw_circle(center, radius, Color(0.2, 0.5, 0.9, 0.85))
			_draw_arrow(center, radius * 0.6, -90.0)
		SignalInputScript.SignalType.TURN_RIGHT:
			draw_circle(center, radius, Color(0.2, 0.5, 0.9, 0.85))
			_draw_arrow(center, radius * 0.6, 90.0)
		_:
			draw_circle(center, radius, Color(0.4, 0.4, 0.4, 0.4))

## angle_degrees: 0 = 위쪽(전진), -90 = 왼쪽, 90 = 오른쪽
func _draw_arrow(center: Vector2, length: float, angle_degrees: float) -> void:
	var angle := deg_to_rad(angle_degrees - 90.0)
	var tip := center + Vector2(cos(angle), sin(angle)) * length
	var left := center + Vector2(cos(angle + 2.6), sin(angle + 2.6)) * length * 0.6
	var right := center + Vector2(cos(angle - 2.6), sin(angle - 2.6)) * length * 0.6
	draw_colored_polygon(PackedVector2Array([tip, left, right]), Color.WHITE)

func _draw_x(center: Vector2, half: float) -> void:
	draw_line(center + Vector2(-half, -half), center + Vector2(half, half), Color.WHITE, 4.0)
	draw_line(center + Vector2(-half, half), center + Vector2(half, -half), Color.WHITE, 4.0)
