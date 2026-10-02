# 저장소 검토 결과 (재현성 감사)

이 저장소의 상당수 자료는 AI 로 생성되어, 따라 해도 실행되지 않는 부분이 있었습니다. 검토 결과와 조치를 기록합니다.

## 1. 발견한 문제와 조치

### Unity 프로젝트 (`Unity shader/ShderTestProject`)
| # | 문제 | 조치 |
|---|---|---|
| 1 | `Packages/manifest.json` 이 없어 URP 패키지가 설치되지 않음 → 파이프라인 에셋이 깨져 셰이더가 분홍색으로 보일 가능성이 큼 | `Packages/manifest.json` 추가 (URP 14.0.9, Unity 2022.3 기준) |
| 2 | `.gitignore` 없음 (Library 등 커밋 위험) | Unity 용 `.gitignore` 추가 |
| 3 | NPR 셰이더가 **Built-in 전용**(`CGPROGRAM`, `ForwardBase`)이라 URP 프로젝트에서 동작 불가 | URP 용으로 재작성 (`Assets/Shaders/NPR/`). 옛 Built-in 버전은 `Unity shader/NPR/NPR_shader.shader` 에 그대로 보관(Assets 밖이라 컴파일되지 않음) |
| 4 | 램프 텍스처 파일이 저장소에 없음 (기본값 white → 툰 효과 없음) | `Assets/Textures/NPR/Ramp_*.png` 추가, 인라인 샘플러로 임포트 설정 의존 제거 |
| 5 | NPR 문서 4개가 Surface Shader / URP / Built-in 을 뒤섞어 서술, 단계별 코드가 서로 이어지지 않음 | 한 가지 구현(URP)으로 통일, 문서를 코드 읽는 순서 중심으로 재작성 |

### 코드 버그
| 파일 | 버그 | 조치 |
|---|---|---|
| NPR 외곽선 문서 | 외곽선 패스에 `LightMode=ShadowCaster` 지정 → 외곽선이 그려지지 않음 | `SRPDefaultUnlit` 사용, 문서에 경고 기재 |
| NPR 스페큘러 | `_Glossiness=0` 이면 `pow(x,0)=1` 로 전체가 하이라이트 | 지수 `max(1, …)` |
| NPR 외곽선 | 거리 페이드 분모가 0 이 될 수 있음 | `max(range, 1e-4)` |
| 다중 램프 문서 | `_RampBlend` 를 Properties 에 선언하고 `SetGlobalFloat` → 머티리얼 값이 가려 스크립트가 무효 | 전역용 `_NPR_RampBlend` 를 Properties 밖에 선언 |
| 다중 램프 문서 | Surface Shader 의 `LightingToon` 코드를 URP 에 그대로 사용 | URP `ToonFrag` 로 교체 |
| 램프 텍스처 문서 | `"RenderPipeline"="UniversalRenderPipeline"` (올바른 값은 `UniversalPipeline`) | 수정 |
| Part 3 | `Tags { "RenderPipeline"="...", "RenderType"=... }` — ShaderLab Tags 에 쉼표 불가 | 완성 파일에서 제거 |
| Part 2/3 | 코드 블록이 발췌라 `Attributes/Varyings`, include, 변수 선언 누락 (예: NormalMapped 의 `finalColor`, SimpleRim 의 `lambert`/`mainLight` 미정의) | 7개 셰이더를 완성 파일로 `Assets/Shaders/Lessons/` 에 추가하고 문서는 링크로 교체 |
| Part 4 포스트 | `Blit(source, source)` (읽기/쓰기 동일 텍스처), 메시용 `TransformObjectToHClip` 을 전체 화면에 사용 | 임시 RT + `Blitter` + `Blit.hlsl` 로 재작성 (URP 14 전용) |
| Part 4 컴퓨트 | 범위 밖 스레드 미처리, `_Bounds` 미설정, 일본어 주석이 섞인 미완성 렌더링 코드 | 완성된 컴퓨트 + 렌더 셰이더 + 컨트롤러 추가 |
| Part 2 설명 | "Light Direction 은 광원에서 표면을 향하는 벡터"라고 서술 — URP `mainLight.direction` 은 표면→광원 방향 | 정의 수정 |
| Part 3 설명 | URP 에서 지원되지 않는 `GrabPass` 를 굴절 구현 방법으로 안내, Shader Graph 의 구 용어 `Master Node` | `_CameraOpaqueTexture` 안내, Fragment 컨텍스트로 수정 |
| README | 깨진 링크 (DirectX 11 학습 경로, 괄호가 포함된 Part 1~3 링크, Win32 4번) | 수정 |

## 2. 검증 상태 (솔직한 기록)

| 영역 | 상태 |
|---|---|
| Unity 셰이더/스크립트 (신규 작성분) | URP 14 공식 셰이더 구조와 API 를 기준으로 작성. **작성 환경에 Unity 가 없어 에디터에서 컴파일하지 못함.** 먼저 열어서 콘솔 에러가 없는지 확인 필요 |
| DirectX 11 / HLSL(Basics, Advanced) 문서 | 링크 점검과 Part 1 코드 샘플 점검만 수행. 코드는 **발췌**이고 C++ 호스트(디바이스, 버퍼, 입력 레이아웃)가 없어 그대로 실행되지 않음 (예: Part 2 퐁 예제는 `WVP`, `World` 를 선언하지 않고 사용) |
| Win32 예제 | 미검토 (`resource.cpp` 등 파일 구성이 비표준) |
| 이론 설명 | Unity Part 2~4 와 NPR 은 검토, 그 외는 전수 검토하지 않음. 의심되면 Real-Time Rendering, Catlike Coding 등 1차 자료와 대조 |

## 3. 앞으로 할 일 (협업 제안)
- [ ] Unity 2022.3 에서 프로젝트를 열어 신규 셰이더 컴파일/동작 확인 후 이슈 보고
- [ ] DirectX 11 최소 호스트 프로젝트(`.sln` 또는 CMake)를 추가해 HLSL 파일을 `.hlsl` 로 분리
- [ ] `유니티 셰이더 ShaderLab 기초.md` 에 "CGPROGRAM 은 Built-in 전용" 주의 문구 추가, DirectX/HLSL 문서 상단에 "발췌 코드" 안내 추가
- [ ] 폴더명 오타 정리: `ShderTestProject` → `ShaderTestProject`, `Adbanced` → `Advanced` (링크 동시 수정 필요)
- [ ] 문서의 코드는 가능하면 *파일 링크*로 두고 중복 복사하지 않기 (유지보수)

## 4. 기여 규칙 (제안)
1. 문서에 코드를 넣을 때는 반드시 저장소의 실제 파일에서 가져오고 경로를 명시한다.
2. 새 셰이더는 공유 변수를 `.hlsl` include 로 분리하고 `Shaders/<주제>/` 아래에 둔다.
3. PR 에 "어떤 Unity/도구 버전에서 실행해 확인했는지"를 적는다.
