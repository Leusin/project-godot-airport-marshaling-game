## 프로젝트 목표

원하는 경험
- 조종이 아니라 유도하는 긴장감

익히고 싶은 것
- AI를 활용한 개발 워크플로우

가설
- AI는 보일러플레이트와 FSM은 잘한다.
- 조작감 튜닝은 사람이 해야 한다.
## 아이디어

> **꼭 진행해야 하는 건 아님**

### A 필수

- [x] 주차 정확도 등급 (B/A/S/SS): 완전포함 → 겹침비율(0.7) 게이트로 완화 + 확정 순간 위치·각도 오차로 채점. `AircraftCollision.parking_metrics()` + `ParkingGrade.evaluate()` + `SuccessHUD` 표시. 임계값은 실측 튜닝 대기

### B 폴리시

- [x] 시야 차폐(line-of-sight): `AircraftVision.can_see`가 반경→각도→시야선 순 판정. 비행기→대상 레이캐스트가 solid(장애물)에 걸리면 시야 밖. solid만 마스킹해 마샬러(hazard)·비행기 자신은 자동 제외(별도 exclude 불필요)
- [x] 마샬러 앞/뒤 방향: 비행기 바라봄 가정 → 비행기가 위면 등·아래면 정면. 좌/우 수신호 손잡이 교정 목적이라 `flip_h` 미러링만으로 해결(뒷모습 아트 불필요). Pawn `is_showing_back()` 사실 노출 + `set_facing_target` 주입, 뷰가 읽어 flip
- [ ] 충돌 UI 효과: 비행기↔마샬러(또는 장애물) 충돌 시 화면 피드백(플래시/비네트/셰이크 등). `AircraftCollision.hazard_hit` → GameManager 게임오버 경로에 연출 훅. EffectRoot/TransitionLayer 활용

### C 다음 버전

- [ ] 1인칭 시점 (마샬러 시야로 전환)
  - 주의: 1인칭은 "직접 조종하는 느낌"을 줄 위험 있음. 마샬러 이동을 일부러 둔하게(가속/감속 느리게) 만들어 통제감을 줄여야 함
- [ ] 레벨별 시점 전환: 초반 레벨 = 3인칭 학습용(시야 원뿔 보임), 후반 레벨 = 같은 맵 1인칭 실전(원뿔 안 보임). 난이도 올리려면 같은 맵에 변형 포인트(시간제한/장애물 추가) 필요

### D 게임 외

- [ ] 디버그 프리캠: 런타임 자유 시점 관찰 (Godot엔 Play 중 Scene 뷰 없음 → 인게임 토글 카메라, WASD+마우스, Visible Collision Shapes 병행). 레벨디자인 도우면 선행 가치
- [ ] 발표용 관찰 기록 정리 (AI 워크플로우 발표 트랙 — 게임 경험과 목적 다름)

## 회고

### Keep
### Problem
### Try
### Unexpected
