# 테스트

외부 애드온 없이 도는 경량 자체 하네스. `tests/tests.tscn` 을 실행하면 모든 테스트를 돌리고
통과/실패를 출력한 뒤 실패 개수를 종료 코드로 반환한다 (CI 연동 가능).

```powershell
# Windows: 헬퍼 스크립트 권장 (GUI 빌드는 콘솔에 로그가 안 붙어 리다이렉트가 필요함)
./run_tests.ps1
```

```bash
# 그 외 / 직접 실행 (콘솔 빌드거나 stdout이 보이는 환경)
godot --headless --path . res://tests/tests.tscn
```

> Windows Godot 에디터 실행 파일은 GUI 프로그램이라 대화형 콘솔에 직접 실행하면 `print` 로그가 보이지 않는다.
> `run_tests.ps1` 은 `Start-Process -RedirectStandardOutput` 으로 stdout을 받아 다시 출력한다.

- `screen_bounds` — 카메라 가시 영역 계산 (순수 함수)
- `countdown` — 프레임 폴링 카운트다운 (딜레이/멈칫 타이머 공용 구현)
- `collision_2d` — OBB/원 겹침·완전포함 판정 (SAT, 순수 함수)
- `aircraft_vision_cone` — 시야 원뿔 각도/반경 판정 (상태 없는 기하)
- `signal_input` — 이벤트 기반 수신호 상태/시그널 (Input.action_press + 합성 이벤트로 구동)
- `aircraft_fsm` — 신호 해석 상태 전이 (페이크 비행기/시야/수신호로 구동)
