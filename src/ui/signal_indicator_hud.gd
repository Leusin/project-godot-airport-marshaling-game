extends Control
## 현재 수신호를 아이콘으로 표시하는 HUD. 판정에 관여하지 않고 SignalInput/GameManager 값을 시각화한다.
##   - 평소: 하단 중앙에 가능한 모든 신호를 나열, 현재 신호만 강조. 각 아이콘 위에 매핑된 키를 키캡으로 표시.
##   - 확정 대기 상태면: 목록 대신 확정(엔진 정지) 아이콘 하나 + 확정 키 키캡만 표시.
## 키 라벨은 InputMap에서 실제 바인딩을 읽어 만들므로 리바인딩해도 자동으로 따라간다.

const DIM_ALPHA := 0.35
const ROW_ICON_SIZE := 63.0
const ROW_GAP := 18.0
const ROW_BOTTOM_MARGIN := 24.0
const CONFIRM_ICON_SIZE := 99.0

# 키캡(키 라벨): 아이콘 우측 상단에 볼드로. 선택 시 아이콘과 함께 커진다(비선택은 축소).
const KEYCAP_HEIGHT := 20.0
const KEYCAP_FONT_SIZE := 14
const KEYCAP_PAD_X := 6.0        # 라벨 좌우 여백
const KEYCAP_MIN_WIDTH := 20.0
const KEYCAP_PROTRUDE := 10.0    # 아이콘 모서리 밖으로 삐져나오는 정도
const KEYCAP_EMBOLDEN := 0.6     # 볼드 강도(FontVariation)
const KEYCAP_INACTIVE_SCALE := 0.8  # 비선택 신호의 키캡 축소 배율
const KEYCAP_BG := Color(0.0, 0.0, 0.0, 1.0)
const KEYCAP_TEXT := Color(1.0, 1.0, 1.0, 1.0)

# 방향키는 이름 대신 화살표 글리프로 압축 표시
const ARROW_GLYPHS := { "Up": "↑", "Down": "↓", "Left": "←", "Right": "→" }

# 하단에 나열할 순서 (게임플레이에서 실제로 가능한 신호)
const ROW_SIGNALS: Array = [
	HandSignal.SignalType.NONE,
	HandSignal.SignalType.ADVANCE,
	HandSignal.SignalType.TURN_LEFT,
	HandSignal.SignalType.STOP,
	HandSignal.SignalType.TURN_RIGHT,
]
const ICON_PATHS := {
	HandSignal.SignalType.NONE: "res://assets/sprites/hud_icons/signal_none.png",
	HandSignal.SignalType.ADVANCE: "res://assets/sprites/hud_icons/signal_advance.png",
	HandSignal.SignalType.STOP: "res://assets/sprites/hud_icons/signal_stop.png",
	HandSignal.SignalType.TURN_LEFT: "res://assets/sprites/hud_icons/signal_turn_left.png",
	HandSignal.SignalType.TURN_RIGHT: "res://assets/sprites/hud_icons/signal_turn_right.png",
}
const CONFIRM_ICON_PATH := "res://assets/sprites/hud_icons/signal_shutdown.png"

# 신호 → InputMap 액션 (키 라벨 조회용). NONE은 매핑 키가 없어 제외.
const SIGNAL_ACTIONS := {
	HandSignal.SignalType.ADVANCE: SignalInput.ACTION_ADVANCE,
	HandSignal.SignalType.STOP: SignalInput.ACTION_STOP,
	HandSignal.SignalType.TURN_LEFT: SignalInput.ACTION_TURN_LEFT,
	HandSignal.SignalType.TURN_RIGHT: SignalInput.ACTION_TURN_RIGHT,
}

var _signal_input: Node
var _game_manager: Node
var _textures: Dictionary = {}
var _confirm_texture: Texture2D
var _key_labels: Dictionary = {}  # 신호 → 키 라벨 문자열 (InputMap에서 1회 계산)
var _shutdown_label := ""
var _keycap_font: Font  # fallback 폰트를 볼드(embolden)로 파생

func _ready() -> void:
	_signal_input = SceneQuery.require_single(GameGroups.SIGNAL_INPUT)
	_game_manager = SceneQuery.require_single(GameGroups.GAME_MANAGER)
	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = KEYCAP_EMBOLDEN
	_keycap_font = bold
	for sig in ICON_PATHS:
		_textures[sig] = load(ICON_PATHS[sig])
	_confirm_texture = load(CONFIRM_ICON_PATH)
	for sig in SIGNAL_ACTIONS:
		_key_labels[sig] = _key_label_for(SIGNAL_ACTIONS[sig])
	_shutdown_label = _key_label_for(SignalInput.ACTION_SHUTDOWN)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _signal_input == null:
		return

	if _game_manager != null and _game_manager.is_awaiting_shutdown_confirm:
		_draw_confirm_prompt()
		return

	var current: HandSignal.SignalType = _signal_input.get_signal()

	# 하단 중앙: 가능한 모든 신호를 가로로 나열, 현재 신호만 강조 (화면 정중앙은 시야를 가려 하단으로 배치)
	var total_width := ROW_SIGNALS.size() * ROW_ICON_SIZE + (ROW_SIGNALS.size() - 1) * ROW_GAP
	var start_x := size.x / 2.0 - total_width / 2.0
	var row_y := size.y - ROW_ICON_SIZE - ROW_BOTTOM_MARGIN
	for i in ROW_SIGNALS.size():
		var sig: HandSignal.SignalType = ROW_SIGNALS[i]
		var is_active := sig == current
		var base_rect := Rect2(start_x + i * (ROW_ICON_SIZE + ROW_GAP), row_y, ROW_ICON_SIZE, ROW_ICON_SIZE)
		var icon_rect := base_rect.grow(8.0) if is_active else base_rect
		_draw_texture(_textures.get(sig), icon_rect, 1.0 if is_active else DIM_ALPHA)
		# 매핑된 키를 (선택 시 커진) 아이콘의 우측 상단 모서리에 붙여 함께 스케일
		_draw_keycap(_key_labels.get(sig, ""), icon_rect, is_active)

## 비행기가 주차존에 충분히 들어와 확정 대기 상태일 때: 가능한 액션이 확정 하나뿐이므로
## 목록 대신 그 아이콘 + 확정 키 키캡만 하단 중앙에 크게 표시.
func _draw_confirm_prompt() -> void:
	var rect := Rect2(size.x / 2.0 - CONFIRM_ICON_SIZE / 2.0,
		size.y - CONFIRM_ICON_SIZE - ROW_BOTTOM_MARGIN, CONFIRM_ICON_SIZE, CONFIRM_ICON_SIZE)
	_draw_texture(_confirm_texture, rect, 1.0)
	_draw_keycap(_shutdown_label, rect, true)

func _draw_texture(tex: Texture2D, rect: Rect2, alpha: float) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, alpha))

## 아이콘 우측 상단에 키캡을 그린다(라벨이 비면 미표시). 비선택이면 축소해 아이콘과 함께 스케일.
func _draw_keycap(text: String, icon_rect: Rect2, active: bool) -> void:
	if text.is_empty():
		return
	var scale := 1.0 if active else KEYCAP_INACTIVE_SCALE
	var font_size := int(roundf(KEYCAP_FONT_SIZE * scale))
	var height := KEYCAP_HEIGHT * scale
	var text_w := _keycap_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var cap_w := maxf(KEYCAP_MIN_WIDTH * scale, text_w + KEYCAP_PAD_X * scale * 2.0)
	# 우상단 앵커: 아이콘 모서리에서 밖으로 KEYCAP_PROTRUDE 만큼.
	var anchor := Vector2(icon_rect.end.x + KEYCAP_PROTRUDE, icon_rect.position.y - KEYCAP_PROTRUDE)
	var cap_rect := Rect2(anchor.x - cap_w, anchor.y, cap_w, height)
	draw_rect(cap_rect, KEYCAP_BG)
	var ascent := _keycap_font.get_ascent(font_size)
	var descent := _keycap_font.get_descent(font_size)
	var baseline := cap_rect.position.y + (height - ascent - descent) * 0.5 + ascent
	draw_string(_keycap_font, Vector2(cap_rect.position.x, baseline), text,
		HORIZONTAL_ALIGNMENT_CENTER, cap_w, font_size, KEYCAP_TEXT)

## 액션에 바인딩된 첫 키의 표시 라벨. 방향키는 화살표 글리프로 압축.
## physical_keycode가 곧 Key enum이라 그대로 문자열화(디스플레이 서버 의존 회피 → 헤드리스 안전).
func _key_label_for(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := event as InputEventKey
			var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
			var label := OS.get_keycode_string(code)
			return ARROW_GLYPHS.get(label, label)
	return ""
