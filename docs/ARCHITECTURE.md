# 아키텍처

**공항 유도(marshalling) 게임.** 플레이어는 지상 유도사(마샬러)가 되어 수신호로 비행기를 주차 지점까지 안내한다. 비행기는 마샬러를 "보고" 신호에 따라 스스로 움직이며, 장애물이나 사람과 부딪히면 게임오버.

코드 읽는 순서는 [CODE_GUIDE.md](CODE_GUIDE.md) 참고.

## 한눈에 보는 구조

핵심은 **"조종자 → Pawn"** 흐름 두 개뿐이다 (언리얼의 Controller/Pawn 모델).
**Pawn**은 명령받은 상태만 들고 있는 몸통이고, **조종자**가 그 Pawn을 움직인다.

```text
마샬러 — 플레이어가 조종
  키 입력 → MovementInput / SignalInput → PlayerController → Marshaller (Pawn)
										   possess·라우팅      ├ move_intent → 이동
															   └ hand_signal → 스프라이트

비행기 — AI가 조종
  Marshaller.hand_signal ──(비행기가 시야로 관찰)──→ Aircraft (Pawn)
								   AircraftFSM(brain)이 판단 → forward/turn
								   → command_delay(반응 지연) → 비행기 이동
```

조종자는 마샬러=`PlayerController`(플레이어 입력), 비행기=`AircraftFSM`(자동 판단). 입력 무지·헬퍼 소유·AI 교체 등 설계 규칙은 [CONVENTIONS.md](CONVENTIONS.md) #6 참고.

## 폴더 구조

```text
src/
  core/
	main_game/   메인 씬 + 게임 진행 (Main.tscn, main_game.gd, game_manager.gd, campaign_manager.gd)
	utils/       공용 스크립트 (scene_query, countdown)
  gameplay/
	hand_signal.gd   수신호 도메인 (종류 enum + 판별)
	input/           입력 (이동키·수신호 → 값, 엔티티 비의존)
	marshaller/      마샬러 씬(.tscn)·Pawn·이동·스프라이트·컨트롤러
	aircraft/        비행기 씬(.tscn)·FSM·이동·시야·충돌
	obstacle/        장애물 씬(.tscn)
	parking/         주차존 씬(.tscn)·등급 규칙(parking_grade.gd)
	levels/          레벨 씬들 (지면·장애물·주차존·스폰 마커 = 레벨 데이터)
  ui/          HUD (수신호 표시·게임오버·성공)
  debug/       디버그 도구 (시야 시각화·FPS HUD)
tests/         단위 테스트 (경량 자체 하네스)
```

## 씬 트리

![씬 구조 다이어그램](attachment/scene_diagram.svg)

```text
MainGame (main_game.gd)          Process Mode = Always. 캠페인↔게임 매니저를 시그널로 배선
├─ Systems                       상위 시스템
│  ├─ GameManager                현재 레벨 플레이: 스폰·승패 판정·HUD 제어
│  ├─ Input                      MovementInput · SignalInput
│  ├─ PlayerController           마샬러 possess
│  └─ CampaignManager            레벨 목록·인덱스·교체·등급 기록
├─ World                         Process Mode = Pausable
│  ├─ TopDownCamera
│  ├─ LevelRoot                  캠페인이 현재 레벨 씬(levels/*.tscn)을 교체 로드하는 슬롯
│  └─ EntityRoot                 GameManager가 마샬러·비행기를 스폰하는 슬롯
└─ HudLayer / PauseLayer / TransitionLayer / DebugLayer
```

- **레벨 씬**(levels/*.tscn) = 지면·장애물·주차존·스폰 마커(그룹 `marshaller_spawn`/`aircraft_spawn`). 스폰 마커는 위치 데이터일 뿐이고, `GameManager`가 마커의 transform만 읽어 엔티티를 **EntityRoot 아래에** 인스턴싱한다(마커 자식 X — 레벨을 교체해도 엔티티 수명은 GameManager가 관리).
- **매니저 배선은 Main 한 곳**: `CampaignManager.level_loaded → GameManager.start_level`, `GameManager.level_completed/level_failed/advance_requested → CampaignManager.on_level_completed/on_level_failed/advance`. 두 매니저는 서로를 직접 참조하지 않는다.
- 이동·FSM 등 헬퍼는 소유 엔티티가 코드로 들고 있다: `Marshaller`→`MarshallerMovement`, `Aircraft`→`AircraftFSM`·`AircraftMovement`.
- 충돌은 두 축이 **한 노드에 겹쳐** 있다. **hazard**(부딪히면 게임오버)는 물리 바디로 — 장애물=`StaticBody3D`, 마샬러=`CharacterBody3D`가 hazard 레이어를 달고 `AircraftHitbox`(Area3D)가 `body_entered`로 감지. **물리 블로킹**은 같은 바디의 solid 레이어로 — 마샬러가 장애물에 막힌다. **주차존**만 `Area3D`.

## 컴포넌트

**입력** — `Systems/Input` 아래, 엔티티 비의존, 이벤트 기반(hold식: 키 떼면 NONE)

| 컴포넌트 | 역할 |
|---|---|
| `MovementInput` | 이동키 → XZ 방향, 바뀌면 시그널 |
| `SignalInput` | 수신호키 → 신호, 바뀌면 시그널 (+ 엔진정지 확정은 단발) |
| `HandSignal` | 수신호 종류 enum과 판별을 담은 도메인. 입력·Pawn·표시·FSM이 공유 |

**마샬러**

| 컴포넌트 | 역할 |
|---|---|
| `PlayerController` | 마샬러를 possess, 입력을 Pawn으로 라우팅 (AI 교체 지점) |
| `Marshaller` (Pawn) | `speed` + 상태(`move_intent`·`hand_signal`) 보유, 입력 무지 |
| `MarshallerMovement` | 이동 계산 헬퍼 (`RefCounted`) |
| `MarshallerSprite` | 부모의 현재 수신호를 아이콘으로 표시 |

**비행기**

| 컴포넌트 | 역할 |
|---|---|
| `Aircraft` (Pawn) | GameManager가 주입한 지각 대상(마샬러)을 시야로 관찰해 신호를 "받아" FSM·이동 헬퍼 구동. 자기 사실(`hazard_hit`·`is_parked_enough()`)만 노출하고 게임 규칙은 모름 (대상 없으면 대기) |
| `AircraftFSM` | brain. 받은 신호로 IDLE/MOVING/HESITATING/STOPPING 전이 → `forward`/`turn` |
| `AircraftMovement` | 속도 관성·회전·전진 계산 헬퍼 (`RefCounted`) |
| `AircraftVision` | 시야 판정 `can_see`(반경→각도→시야선 차폐 순, solid 레이캐스트로 장애물 뒤는 못 봄) + shader로 시야 부채꼴 시각화 (`MeshInstance3D`) |
| `AircraftCollision` | 히트박스(Area3D) 겹침 판정 헬퍼 (`RefCounted`). 복합 히트박스(동체+날개) 월드 AABB를 합쳐 hazard 진입/완전 주차 여부만 Aircraft에 알림 |
| `AircraftHitbox` | 스크립트 없는 Area3D. Aircraft가 소유한 `AircraftCollision`이 이 노드를 구독 |

**판정·공용**

| 컴포넌트 | 역할 |
|---|---|
| `MainGame` | **조립 지점.** 캠페인↔게임 매니저를 시그널로 배선하고 첫 레벨을 로드 |
| `CampaignManager` | **캠페인 흐름.** 레벨 목록·인덱스 보유, LevelRoot 아래 레벨 교체(`restart_level`/`next_level`), 클리어 등급 기록. 판정은 모름 |
| `GameManager` | **현재 레벨 플레이.** 스폰 마커 transform을 읽어 EntityRoot에 엔티티 인스턴싱·배선, 비행기 사실(충돌·주차) + 확정 입력을 구독해 승패 판정·HUD 제어. 결과는 `level_completed(grade)`/`level_failed` 시그널로만 알림 |
| `Obstacle`·`ParkingSpot` | Obstacle = `StaticBody3D` 한 노드(hazard+solid: 감지되며 마샬러를 막음), ParkingSpot = parking `Area3D` |
| `SceneQuery`·`Countdown` | 그룹 단일 조회 / 프레임 타이머 |

## 동작 규칙 (헷갈리기 쉬운 부분)

- **NONE(무신호) ≠ STOP(정지 명령).** 키를 떼면 NONE.
- **비행기 반응**: 무신호는 잠깐 멈칫(계속 가다) 후 정지, STOP·시야 밖은 즉시 정지. 모든 명령은 `command_delay`만큼 지연돼 반영된다.
- **충돌.** hazard(장애물·마샬러)는 물리 바디에 hazard 레이어를 달아 `AircraftHitbox`가 `body_entered`로 감지하고, 물리 블로킹은 같은 바디의 solid 레이어(bit4). 주차존만 `Area3D`. 주차 성공은 비행기 풋프린트(XZ)가 주차존과 **겹침비율 0.7 이상**일 때 확정 버튼을 눌러야 하고, 확정 순간의 위치·각도 오차로 등급(B/A/S/SS)을 채점한다(`ParkingGrade`).

## 더 볼 것

- 설계 원칙·코딩 컨벤션 → [CONVENTIONS.md](CONVENTIONS.md)
- 테스트 하네스와 실행 방법 → [TESTING.md](TESTING.md)
