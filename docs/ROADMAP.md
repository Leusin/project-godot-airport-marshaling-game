# 로드맵

## 완료 (MVP)

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
  - [x] 시야 밖: 유도자를 놓친 것이므로 즉시 정지 (무신호 멈칫보다 엄격)
- [x] 충돌 -> 게임 오버 (비행기-장애물, 사람-비행기)
  - [x] AircraftCollision: 비행기가 XZ 거리로 근접 판정 (Area3D 시그널 대신)
  - [x] 마샬러/장애물을 그룹(marshaller/obstacle)으로 조회 → 접촉 시 게임 오버
  - [x] GameManager: 게임 오버 처리, 재시작 (엔터/ESC)
  - [x] GameOverHUD: 전체화면 오버레이 표시
- [x] A->B 유도 목표 및 성공/실패 판정
  - [x] ParkingSpot: 목표 주차 지점 (초록 박스, parking 그룹)
  - [x] 비행기가 ParkingSpot에 완전히 들어오면(포함 판정) → "확정 대기" 상태
  - [x] 확정 대기 중 마샬러가 확정 버튼(스페이스, signal_shutdown)을 누르면 → 유도 성공 확정
  - [x] 확정 대기 중에는 하단 신호 목록 대신 확정 아이콘 하나만 표시
  - [x] SuccessHUD: 초록 오버레이 + "유도 성공!" 텍스트
  - [x] 성공/실패 모두 엔터 / ESC 로 재시작

## 예정

- [ ] Accuracy(유도 정확도) 채점 시스템
