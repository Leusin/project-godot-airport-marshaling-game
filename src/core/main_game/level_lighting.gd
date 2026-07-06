extends WorldEnvironment
## 씬에 조명/환경이 전혀 없어 전체가 어둡던 문제 해결.
## Environment의 enum 값은 .tscn에 raw int로 적지 않고 여기서 이름으로 참조해
## (Environment.BG_COLOR 등) 오타/오류 여지를 없앤다.

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.58)
	env.ambient_light_energy = 0.6
	environment = env
