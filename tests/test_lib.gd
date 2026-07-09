class_name TestLib
extends RefCounted
## 경량 단위 테스트 헬퍼. 결과를 누적만 하고, 출력(콘솔/씬)은 러너가 담당한다.

var total: int = 0
var failed: int = 0
var results: Array = []  # [{ ok: bool, section: String, msg: String }]

var _current: String = ""

func start(section: String) -> void:
	_current = section

func check(cond: bool, msg: String) -> void:
	total += 1
	if not cond:
		failed += 1
	results.append({ "ok": cond, "section": _current, "msg": msg })

func check_eq(actual: Variant, expected: Variant, msg: String) -> void:
	check(actual == expected, "%s (기대: %s, 실제: %s)" % [msg, str(expected), str(actual)])

func check_almost(actual: float, expected: float, msg: String, eps: float = 0.001) -> void:
	check(absf(actual - expected) <= eps, "%s (기대: ~%s, 실제: %s)" % [msg, str(expected), str(actual)])

func summary() -> String:
	return "테스트 결과: %d/%d 통과, %d 실패" % [total - failed, total, failed]
