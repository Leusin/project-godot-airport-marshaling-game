@tool
extends EditorScript

## 프로젝트 기본 설정 일괄 적용. 씬에 붙이지 않고 에디터에서 File > Run(Ctrl+Shift+X)으로 실행.
## 새 환경에서 처음 한 번만 실행하면 project.godot에 반영된다.

# ── 애플리케이션 / 윈도우 ────────────────────────────────────────────
const PROJECT_SETTINGS: Dictionary = {
	"application/config/name": "Airport Marshaling Prototype",
	"application/config/version": "0.1.0",

	# 3D 게임은 canvas stretch 불필요 → disabled
	"display/window/size/viewport_width": 1280,
	"display/window/size/viewport_height": 720,
	"display/window/stretch/mode": "disabled",

	# 실제 창 크기 (에디터 실행 시 기본값)
	"display/window/size/window_width_override": 1280,
	"display/window/size/window_height_override": 720,
	"display/window/size/resizable": true,
}

# ── 3D 물리 레이어 ───────────────────────────────────────────────────
const PHYSICS_3D_LAYERS: Dictionary = {
	1: "Aircraft",
	2: "Marshaller",
	3: "Obstacle",
	4: "ParkingArea",
}

# ── 3D 렌더 레이어 ───────────────────────────────────────────────────
const RENDER_3D_LAYERS: Dictionary = {
	1: "World",
	2: "Aircraft",
	3: "Marshaller",
}


func _run() -> void:
	_apply_project_settings()
	_apply_layer_names()

	var error: Error = ProjectSettings.save()
	if error == OK:
		print("[apply_project_settings] 완료 — project.godot 저장됨.")
	else:
		push_error("[apply_project_settings] 저장 실패. Error: " + str(error))


func _apply_project_settings() -> void:
	for path: String in PROJECT_SETTINGS:
		ProjectSettings.set_setting(path, PROJECT_SETTINGS[path])
		print("  set  %s = %s" % [path, str(PROJECT_SETTINGS[path])])


func _apply_layer_names() -> void:
	for n: int in PHYSICS_3D_LAYERS:
		ProjectSettings.set_setting(
			"layer_names/3d_physics/layer_%d" % n,
			PHYSICS_3D_LAYERS[n]
		)
		print("  set  layer_names/3d_physics/layer_%d = %s" % [n, PHYSICS_3D_LAYERS[n]])

	for n: int in RENDER_3D_LAYERS:
		ProjectSettings.set_setting(
			"layer_names/3d_render/layer_%d" % n,
			RENDER_3D_LAYERS[n]
		)
		print("  set  layer_names/3d_render/layer_%d = %s" % [n, RENDER_3D_LAYERS[n]])
