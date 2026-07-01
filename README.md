## 개요

비행기 주차를 위한 수신호 보내기 시뮬레이션 게임

### 기술 스택

Godot 4.7 / GDScript / 3D 탑다운 시뮬레이션 (카메라만 탑뷰, 노드는 3D)

### MVP

* 3D 공간, 탑다운 고정 카메라
* 마샬러 직접 이동
  * 맵 위 자유 이동, 화면 경계 클램프
* 비행기 70도 시야 원뿔 + 시야 안 판정
  * 비행기 정면 기준 좌우 35도, 원뿔 밖 신호는 무시
  * 비행기가 움직이면 시야도 함께 이동 -> 플레이어가 따라다니며 위치 조정
* 수신호 입력 (전진/정지/좌우회전), 시야 안에서만 인식, hold-to-move
  * 마샬러 이동(WASD)과 수신호(방향키)를 분리 — ↑전진, ←좌회전, →우회전, ↓정지, 모두 누르고 있는 동안만 유지
  * 무신호(NONE)와 정지(STOP)는 의미가 다름 — 실제 마샬링도 "신호 없음"과 "정지 명령"을 구분
    (지금은 둘 다 비행기를 멈추지만, AircraftFSM에서 무신호는 모호함/멈칫으로 다르게 처리할 예정)
* 비행기 FSM (딜레이+관성으로 신호 해석, 즉각 반응 금지)
  * IDLE -> INTERPRETING -> MOVING -> STOPPING
  * 모호한 신호는 멈칫 또는 오해 가능
* 충돌 -> 게임 오버
  * 비행기-장애물 충돌
  * 사람(마샬러)-비행기 충돌
* A->B 유도 성공/실패 판정

## 설계
### 폴더 구조 (초안)

```text
project.godot
scenes/         .tscn 씬 파일
scripts/        .gd 스크립트
scripts/common/ 여러 노드가 공유하는 재사용 가능한 스크립트 (예: screen_bounds.gd)
assets/         스프라이트, 사운드
```

### 주요 구성 (초안)
![](docs\20260627.png)

**마샬러**
- `MarshallerController` — 이동만 담당 (WASD, 화면 경계 클램프)
- `MoveInput` — 이동 입력 전담
- `SignalInput` — 수신호 입력 전담. 방향키 -> 신호 타입(전진/정지/좌우회전) 변환만, 판정은 안 함.
  모두 hold-to-move. 키를 떼면 NONE(무신호) — NONE과 STOP은 별개 값

**비행기**
- `Aircraft` — 위치/속도/회전, 딜레이+관성 이동 로직
- `AircraftVisionCone` — 정면 기준 70도 원뿔 판정, 마샬러가 원뿔 안에 있는지 bool만 반환
- `AircraftFSM` — IDLE/INTERPRETING/MOVING/STOPPING 전이. 신호 + 시야 판정을 함께 받아야 인식
- `AircraftSignalReceiver` — (임시, AircraftFSM으로 대체될 예정) 시야 판정 + SignalInput을 조합해 Aircraft에 명령 전달. 시야 밖/무신호면 정지

**UI**
- `SignalIndicatorHUD` — 마샬러가 현재 입력 중인 수신호를 화면에 아이콘으로 표시 (텍스처 없이 코드로 그림)

**공유/판정**
- `Obstacle` — 정적 콜라이더만 있는 장애물
- `GameManager` — 충돌 이벤트 수신 (비행기-장애물, 사람-비행기) -> 게임오버 / A->B 도착 판정

### 로드맵

- [x] 프로젝트 토대
  - [x] 폴더 구조 확정 (scenes/, scripts/, assets/)
  - [x] 노드 이름 규칙 확정 (설계 섹션 명명 그대로: Marshaller, Aircraft, GameManager 등)
  - [x] Godot 프로젝트 생성 (Main.tscn에 TopDownCamera/Marshaller/Aircraft/GameManager 뼈대)
- [x] 마샬러(플레이어) 직접 이동
  - [x] 맵 위 자유 이동 (WASD — 방향키는 수신호 입력으로 분리됨)
  - [x] 화면 경계 클램프 (탑다운 카메라 orthogonal size + 화면 비율 기준 실측 계산)
- [x] 비행기 70도 시야 원뿔 + 시야 안 판정
  - [x] AircraftVisionCone: 정면 기준 좌우 35도 + 반경 판정, bool만 반환
  - [x] 디버그 시각화로 확인 (부채꼴 초록/빨강)
- [x] 비행기 기본 이동 + 딜레이/관성
  - [x] Aircraft: 명령 수신 후 딜레이(command_delay) 후 반영, 가속/감속으로 점진적 속도 변화
  - [x] 화면 경계 클램프 (Marshaller와 동일한 ScreenBounds 유틸리티 공유)
  - [x] 임시 디버그 자동조종으로 확인 — 이후 실제 수신호 입력 시스템으로 대체됨
- [x] 수신호 입력 시스템 (전진/정지/좌우회전), 시야 안에서만 인식
  - [x] SignalInput: 방향키 hold-to-move (↑전진/←좌회전/→우회전/↓정지), 마샬러 이동(WASD)과 분리
  - [x] NONE(무신호)과 STOP(정지)을 별개 값으로 유지 (AircraftFSM에서 다르게 다룰 수 있도록)
  - [x] AircraftSignalReceiver(임시): 시야 판정 + SignalInput 조합 -> Aircraft 명령. 시야 밖/무신호/정지는 모두 정지
  - [x] SignalIndicatorHUD: 현재 신호를 화면 아이콘으로 표시
  - [x] 회전 속도 50→25°/s로 조정
- [x] 비행기 FSM (신호 해석/오해/멈칫)
  - [x] AircraftFSM: IDLE/MOVING/HESITATING/STOPPING 전이
  - [x] NONE(무신호): 이동 중 1초 멈칫 후 정지 (재지시 오면 MOVING 복귀)
  - [x] STOP(명확한 정지): 즉시 정지 시작, 멈칫 없음
  - [x] 시야 밖 = 무신호와 동일 처리
- [x] 충돌 -> 게임 오버 (비행기-장애물, 사람-비행기)
  - [x] AircraftHitbox: 비행기 충돌 감지 (Area3D)
  - [x] MarshallerHitbox: 마샬러 피격 영역 (collision_marshaller 그룹)
  - [x] Obstacle: 테스트용 장애물 배치 (collision_obstacle 그룹)
  - [x] GameManager: 게임 오버 처리, 재시작 (엔터/ESC)
  - [x] GameOverHUD: 전체화면 오버레이 표시
- [ ] A->B 유도 목표 및 성공/실패 판정

## 관리 문서

- README.md 개요
- DEVLOG.md 진행 로그
- MEMORY.md 회고
