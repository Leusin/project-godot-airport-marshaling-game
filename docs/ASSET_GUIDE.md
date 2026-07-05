# 마샬러 게임 에셋 제작 가이드

> Blender MCP → Godot 4.7 파이프라인

## 프로젝트 개요

| 항목 | 내용 |
|---|---|
| 엔진 | Godot 4.7 |
| 에셋 툴 | Blender + blender-mcp (Claude 연동) |
| 시점 | 탑뷰 ↔ 1인칭 전환 |
| 에셋 범위 | 여객기(탑뷰용), 마샬러(1인칭 주인공) |
| 스타일 | 로우폴리 (스타일 미정 — 첫 에셋 뽑고 확정) |
| 포맷 | `.glb` (Godot 권장) |

> ⚠️ Blender 제작(1~3단계)은 **blender-mcp가 연결된 Claude Desktop**에서 진행한다.
> 이 저장소에서 작업하는 Claude Code 환경에는 blender-mcp가 없다. Godot 임포트/씬 구성(4단계)만 여기서 한다.

---

## 1단계 — 블렌더 MCP 셋업

### 사전 설치
- [ ] Blender 3.0+
- [ ] Claude Desktop (claude.ai/download)
- [ ] `uv` 패키지 매니저

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
irm https://astral.sh/uv/install.ps1 | iex
```

### 블렌더 애드온 설치
1. github.com/ahujasid/blender-mcp 에서 `addon.py` 다운로드
2. Blender → Edit → Preferences → Add-ons → Install
3. `addon.py` 선택 → **MCP Blender Bridge** 활성화

### Claude Desktop 연결
`claude_desktop_config.json` 에 추가:

```json
{
  "mcpServers": {
    "blender": {
      "command": "uvx",
      "args": ["blender-mcp"]
    }
  }
}
```

> Windows uvx 경로 오류 시: `where uvx` 로 전체 경로 확인 후 `"command"` 에 직접 입력

### 연결 확인
1. Blender 실행 → 사이드패널 → MCP 서버 **Start**
2. Claude Desktop 실행
3. Claude에게 `"What objects are in the current Blender scene?"` 테스트

---

## 2단계 — 에셋 제작

### 2-1. 여객기 (탑뷰용)

**목표 스펙**
- 폴리카운트: 500~800 tri
- 용도: 탑뷰에서 이동하는 오브젝트
- 내부 불필요, 실루엣 + 도색만

**제작 순서**
1. 좁은 동체형 먼저 (A320 / B737급)
2. 결과물로 스타일 확정
3. 광동체형 추가 (B777 / A380급) — 필요 시

**블렌더 MCP 프롬프트 예시**
```
Create a low poly narrow body passenger aircraft for top-down view.
Clean silhouette, approximately 600 triangles, no interior geometry.
Add basic white fuselage material with grey wings.
```

### 2-2. 마샬러 (주인공)

| 파트 | 설명 | 우선순위 |
|---|---|---|
| 1인칭 손 + 패들 | 실제 플레이어가 보는 것 | 최우선 |
| 탑뷰 전신 | 작게 보임, 매우 단순하게 | 2순위 |

**1인칭 손+패들 프롬프트 예시**
```
Create low poly first person hands holding marshalling paddles.
Yellow circular paddles on short handles, simple geometry.
Suitable for first person view game asset, under 400 triangles total.
```

**탑뷰 전신 프롬프트 예시**
```
Create a low poly human character in marshaller uniform.
Simple blocky shape, holding paddles at sides.
Top-down view asset, under 300 triangles.
```

---

## 3단계 — 애니메이션 (마샬러 5종)

> 각 동작을 블렌더에서 **별도 Action**으로 저장해야 Godot에서 깔끔하게 불러와짐

| Action 이름 | 동작 설명 | 타입 | 난이도 |
|---|---|---|---|
| `forward` | 양팔 앞으로 원형 회전 | 루프 | 중 |
| `turn_left` | 오른팔 옆으로 스윙 | 단순 포즈 | 하 |
| `turn_right` | 왼팔 옆으로 스윙 | 단순 포즈 | 하 |
| `stop` | 양팔 X자 교차 | 단순 포즈 | 하 |
| `shutdown` | 한팔 목 긋기 동작 | 단순 포즈 | 하 |

**작업 순서**
1. `stop` → `turn_left` → `turn_right` → `shutdown` (단순 포즈 4개 먼저)
2. `forward` 루프 애니메이션 마지막에

> MCP로 키프레임 초안 → 블렌더에서 수동 다듬기 하이브리드 방식 권장

---

## 4단계 — Godot 4.7 Import

### glb Export (블렌더)
- File → Export → glTF 2.0 (.glb)
- 애니메이션 포함 체크
- 마샬러와 여객기 **별도 파일**로 export
- 저장 위치: `assets/models/`

### Godot 씬 구성
```
Main Scene
├── 여객기 (Aircraft): MeshInstance3D 를 glb 모델로 교체
├── 마샬러 (Marshaller)
│   ├── MeshInstance3D (또는 Skeleton3D)
│   └── AnimationPlayer
│       ├── forward / turn_left / turn_right / stop / shutdown
└── Camera 컨트롤러
    ├── TopViewCamera (Camera3D)
    └── FirstPersonCamera (Camera3D)
```

### 4.7 유용한 기능
- **nearest-neighbor 뷰포트 스케일링** — 로우폴리 선명하게 렌더
- **AreaLight3D** — 활주로/게이트 면광원 표현
- **Inspector 카테고리 복붙** — 노드 세팅 빠르게 복사

---

## 추후 작업 (백로그)
- [ ] 마샬러 걷기 애니메이션
- [ ] 여객기 광동체형 추가
- [ ] 로우폴리 스타일 확정 및 통일
- [ ] 공항 환경 에셋 (활주로, 게이트 등)

---

## 참고 링크
- blender-mcp: github.com/ahujasid/blender-mcp
- Godot 4.7 릴리즈 노트
- Godot glTF import 공식 문서
