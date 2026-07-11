class_name CollisionLayers
extends RefCounted
## 콜리전 레이어 번호(1-based) 중앙 관리. project.godot의 [layer_names]와 짝을 이루는 단일 진실.
## Godot API(get/set_collision_layer_value)가 1-based 인덱스를 받으므로 그 번호를 상수로 둔다.
## (.tscn의 collision_layer/mask 정수는 코드에서 참조 불가 — 에디터에선 이름 붙은 체크박스로 설정한다.)

const AIRCRAFT := 1  # 비행기 히트박스 표식
const HAZARD := 2    # 부딪히면 게임오버 (장애물·마샬러)
const PARKING := 3   # 주차존
const SOLID := 4     # 물리적으로 막는 벽 (장애물)

## 1-based 레이어 번호를 레이캐스트/충돌 마스크용 비트값으로 변환.
static func bit(layer: int) -> int:
	return 1 << (layer - 1)
