class_name ParkingGrade
extends RefCounted
## 주차 품질 등급(B/A/S/SS) 규칙 — 순수 도메인. 판정자(GameManager)가 확정 순간의 사실
## (위치 오차·각도 오차)을 넣으면 등급을 돌려준다. HandSignal처럼 중립 어휘라 판정자·표시가 공유한다.
##
## 등급은 위치·각도 두 축을 함께 봐서, 둘 다 해당 상한 이내여야 그 등급을 받는다(더 나쁜 쪽이 등급을 정함).
## 값은 주차존 4.5 / 비행기 풋프린트 ~3.5 기준의 프로토타입 초기값 — 실측 후 사람이 튜닝할 대상.

enum Grade { B, A, S, SS }

# 각 등급의 상한(이하이면 그 등급 후보). B는 하한이 없어(확정 게이트만 통과) 여기 없음.
const _POS_LIMITS := { Grade.SS: 0.2, Grade.S: 0.8, Grade.A: 1.4 }    # 중심 오차(m)
const _ANGLE_LIMITS := { Grade.SS: 4.0, Grade.S: 9.0, Grade.A: 18.0 } # 축 어긋남(도)

## 위치·각도 오차 → 등급. 높은 등급부터 검사해 둘 다 만족하는 첫 등급을 준다.
static func evaluate(position_error: float, angle_error_degrees: float) -> Grade:
	for grade in [Grade.SS, Grade.S, Grade.A]:
		if position_error <= _POS_LIMITS[grade] and angle_error_degrees <= _ANGLE_LIMITS[grade]:
			return grade
	return Grade.B

## 표시용 한 글자("B"/"A"/"S"/"SS").
static func label(grade: Grade) -> String:
	return Grade.keys()[grade]
