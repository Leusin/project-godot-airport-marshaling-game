진행 로그. 
작업할 때마다 위에서부터 최신 항목 추가 

작성 형식: 

```
- YYYY-MM-DD [유형] 한 일 요약
  - 세부 내용 (필요시)
```

유형:
- [결정] - 설계/구현/툴체인 의사결정. 안정화되면 README.md 설계 섹션으로 승급한다.
- [세션] - 진행한 작업 세션 요약.
- [에러] - 재발 가능한 함정. 증상 / 원인 / 해결 / 교훈 순으로 기록.

## Log

- 2026-06-28 [세션] 비행기 시야 원뿔 구현 완료 (AircraftVisionCone).
	- scripts/aircraft_vision_cone.gd: 정면(-Z) 기준 좌우 35도 + 반경(view_radius) 안에 점이 있는지 bool만 반환. 상태 없음.
	- Aircraft를 Y 180도 회전시켜 기본 정면이 Marshaller 스폰 방향(+Z)을 향하도록 함. NoseMarker(파란 작은 박스)로 정면 표시.
	- 디버그 전용 vision_cone_debug_visual.gd 추가: 부채꼴 메쉬를 절차적으로 생성해 마샬러가 원뿔 안/밖일 때 초록/빨강으로 표시. 실제 판정 로직과는 분리되어 있고 게임플레이에는 관여하지 않음.
	- 사용자 확인: 정상 동작.
	- 다음: 비행기 기본 이동 + 딜레이/관성.
- 2026-06-28 [에러] MeshInstance3D에 mesh 할당 전 set_surface_override_material 호출.
	- 증상: "Index p_surface = 0 is out of bounds (surface_override_materials.size() = 0)".
	- 원인: surface override는 mesh의 surface 개수를 기준으로 검증되는데, mesh를 아직 할당하기 전(surface 0개)에 머티리얼을 먼저 설정함.
	- 해결: mesh 할당 후에 set_surface_override_material 호출하도록 순서 변경.
	- 교훈: 절차적 메쉬를 만들 때는 mesh 대입 -> 머티리얼 오버라이드 순서를 지킬 것.
- 2026-06-28 [세션] 마샬러 직접 이동 구현 완료 (MarshallerController/MoveInput).
	- Ground(50x50)/MarshallerMesh(캡슐)/AircraftMesh(박스) 임시 비주얼 추가.
	- project.godot에 move_left/right/up/down 입력 액션 등록.
	- 화면 경계 클램프를 고정값이 아니라 TopDownCamera의 orthogonal size + 뷰포트 비율로 실시간 계산하도록 구현 (_update_bounds, viewport size_changed에 연결).
	- 사용자 확인: 화면 가장자리에서 정확히 멈추는 것 확인됨.
	- 다음: 비행기 70도 시야 원뿔 + 시야 안 판정.
- 2026-06-28 [에러] GDScript class_name과 const 별칭 이름 충돌.
	- 증상: "The constant MoveInput has the same name as a global class defined in move_input.gd" 경고 + 최초 실행 시 "Could not find type MoveInput in the current scope" 파서 에러.
	- 원인: move_input.gd에 class_name MoveInput 선언, marshaller_controller.gd에서 동시에 const MoveInput = preload(...)로 같은 이름 사용. 전역 클래스 캐시(.godot)가 즉시 갱신되지 않아 처음엔 타입을 못 찾고, 나중엔 이름 충돌 경고로 바뀜.
	- 해결: class_name 선언 제거하고 preload 기반 const(이름을 MoveInputScript로 변경)만 사용.
	- 교훈: MCP로 매번 새 헤드리스 godot 프로세스를 띄우는 구조라 전역 스크립트 클래스 캐시 갱신 타이밍이 불안정함. 작은 유틸 스크립트는 class_name 없이 preload로 참조하는 게 안전.
- 2026-06-28 [세션] godot-mcp 연동 확인 (get_godot_version/launch_editor 정상). 프로젝트 토대 작업 완료.
	- project.godot 생성 (worktree 루트, AirportMarshalingPrototype 폴더 밖). scenes/scripts/assets 폴더 생성.
	- scenes/Main.tscn 생성, root(Node3D) 아래 TopDownCamera(Orthogonal, y=15 내려보기)/Marshaller/Aircraft/GameManager 노드 뼈대 추가.
	- run_project로 정상 구동 확인.
	- 다음: 마샬러(플레이어) 직접 이동 구현.
- 2026-06-27 [세션] 다른 PC 프로토타입 미동기화 확인, 기억으로 README 복원, 관리문서 3종(README/DEVLOG/MEMORY) 도입.
	- 다음: 폴더구조/노드규칙 확정 + Godot 프로젝트 생성.
