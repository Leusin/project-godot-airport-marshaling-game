extends RefCounted
## 아주 가벼운 자체 단위 테스트 헬퍼. 외부 애드온(GUT 등) 없이 헤드리스로 실행한다.
## check* 로 단언하고, report()로 결과를 출력하며 실패 개수를 반환한다.

var total: int = 0
var failed: int = 0
var _current: String = ""

func start(section: String) -> void:
	_current = section

func check(cond: bool, msg: String) -> void:
	total += 1
	if cond:
		print("  [PASS] %s :: %s" % [_current, msg])
	else:
		failed += 1
		print("  [FAIL] %s :: %s" % [_current, msg])

func check_eq(actual: Variant, expected: Variant, msg: String) -> void:
	check(actual == expected, "%s (기대: %s, 실제: %s)" % [msg, str(expected), str(actual)])

func check_almost(actual: float, expected: float, msg: String, eps: float = 0.001) -> void:
	check(absf(actual - expected) <= eps, "%s (기대: ~%s, 실제: %s)" % [msg, str(expected), str(actual)])

func report() -> int:
	print("──────────────────────────────")
	print("테스트 결과: %d/%d 통과, %d 실패" % [total - failed, total, failed])
	return failed
