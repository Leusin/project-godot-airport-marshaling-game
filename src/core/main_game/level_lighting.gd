extends WorldEnvironment
## 씬 조명/환경을 코드로 구성. Environment enum을 .tscn의 raw int 대신
## 이름(Environment.BG_COLOR 등)으로 참조해 오타 여지를 없앤다.

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.58)
	env.ambient_light_energy = 0.6
	environment = env
