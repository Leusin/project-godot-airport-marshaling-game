extends Node
## 레벨 캠페인 진행 관리. 레벨 씬 목록·현재 인덱스를 보유하고 LevelRoot 아래 현재 레벨을 교체하며,
## 클리어 등급을 기록한다(추후 저장 시스템 연결 지점). 게임 판정은 모름 — 판정 결과는 Main이
## GameManager 시그널을 이어줘 전달받고, 레벨 로드 완료는 level_loaded 시그널로만 알린다.

## 레벨 씬 교체가 끝났을 때 방출. Main이 GameManager.start_level로 잇는다.
signal level_loaded

## 완료 화면에서 확인 입력까지 끝나 캠페인이 완전히 종료됐을 때 방출. 다음 흐름(로비 복귀)은 Main이 정한다.
signal campaign_finished

## 캠페인 레벨 순서. 각 항목은 스폰 마커·주차존·장애물을 포함한 레벨 씬.
@export var levels: Array[PackedScene] = []

var _level_index := 0
var _last_completed := false

## 전 레벨 클리어 후 완료 화면이 떠 있는 상태. 완료 HUD가 읽어 표시한다.
var is_complete := false

## 레벨별 최고 클리어 등급 (미클리어는 null). 저장 시스템이 붙으면 이 배열을 직렬화한다.
var grades: Array = []

var _level_root: Node3D

func _ready() -> void:
	_level_root = SceneQuery.require_single(GameGroups.LEVEL_ROOT) as Node3D
	grades.resize(levels.size())

## 현재 레벨을 다시 로드한다.
func restart_level() -> void:
	_request_load(_level_index)

## 다음 레벨로 넘어간다. 마지막이면 처음으로 순환하며 새 사이클 — 등급 기록을 초기화한다.
func next_level() -> void:
	var next := (_level_index + 1) % levels.size()
	if next == 0:
		grades.fill(null)
	_request_load(next)

## 진행 HUD가 읽는 사실들.
func level_count() -> int:
	return levels.size()

func current_level() -> int:
	return _level_index

## 해당 레벨의 클리어 등급. 미클리어면 null.
func grade_of(index: int) -> Variant:
	return grades[index]

## 클리어 기록. 기존 기록보다 높은 등급만 갱신한다. (Main이 GameManager.level_completed를 잇는다)
func on_level_completed(grade: ParkingGrade.Grade) -> void:
	_last_completed = true
	if grades[_level_index] == null or grade > grades[_level_index]:
		grades[_level_index] = grade

func on_level_failed() -> void:
	_last_completed = false

## 종료 화면 확인 입력 뒤의 진행 결정: 클리어면 다음 레벨, 실패면 재시작.
## 마지막 레벨을 클리어했으면 완료 화면으로 전환하고, 완료 화면에서 한 번 더 확인하면 캠페인 종료.
func advance() -> void:
	if is_complete:
		campaign_finished.emit()
		return
	if _last_completed:
		if _level_index == levels.size() - 1:
			is_complete = true
			return
		next_level()
	else:
		restart_level()

## 씬 교체는 입력/시그널 콜백 중에 요청될 수 있으므로 프레임 끝으로 미룬다.
func _request_load(index: int) -> void:
	if levels.is_empty() or _level_root == null:
		return
	_level_index = index
	_load_level.call_deferred(index)

func _load_level(index: int) -> void:
	# 이전 레벨을 트리에서 즉시 떼어 스폰 마커가 그룹 조회에 걸리지 않게 한 뒤 해제 예약.
	for child in _level_root.get_children():
		_level_root.remove_child(child)
		child.queue_free()
	_level_root.add_child(levels[index].instantiate())
	level_loaded.emit()
