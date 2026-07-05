extends Control
## 디버그 오버레이. 화면 우상단에 앱 버전 + 실시간 FPS를 표시한다.
## DebugLayer(layer 128, Always) 아래에 있어 일시정지 중에도 갱신된다.

const MARGIN := 12.0

var _version: String = "0.0.0"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var text := "v%s   %d FPS" % [_version, Engine.get_frames_per_second()]
	draw_string(ThemeDB.fallback_font, Vector2(0, 24.0), text,
		HORIZONTAL_ALIGNMENT_RIGHT, size.x - MARGIN, 16, Color(0.9, 0.9, 0.95, 0.85))
