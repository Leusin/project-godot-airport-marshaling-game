extends Node3D
## 마샬러의 정체성/설정을 관리하고 필요한 컴포넌트(입력/이동/스프라이트)를 붙이는 루트.
## 실제 이동은 자식 MarshallerControl이 담당한다 (Aircraft/AircraftControl과 동일 구조).

@export var speed: float = 5.0
