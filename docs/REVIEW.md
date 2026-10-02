# 저장소 검토 결과 (재현성 감사)

이 저장소의 상당수 자료는 AI 로 생성되어 따라 해도 막히는 부분이 있었습니다. 이 PR 은 **프로젝트를 실행 가능하게 만드는 것이 아니라, 문서만 보고 따라 할 수 있도록** 다음을 바로잡았습니다.

- 각 문서 맨 위에 **따라 하기 환경(도구 버전)과 순서**를 표시
- 코드가 문서 안에서 완결되도록(빠진 선언·include·구조체 보완) 정리, 발췌 조각은 발췌라고 명시하고 **호스트에서 할 일**을 적음
- 틀린 코드·설명 수정
- 검증하지 못한 부분을 숨기지 않고 표시

> **검증 상태 (공통)**: 작성 환경에 Windows/Visual Studio/Unity 가 없어 어떤 코드도 직접 컴파일·실행해 보지 못했습니다. 모든 수정은 공식 문서의 API/규약과 수학적 일관성을 기준으로 한 검토 결과입니다. 오류를 발견하면 이슈로 남겨 주세요.

## 1. Unity (`Unity shader/`)
| 문서 | 문제 | 조치 |
|---|---|---|
| `ShderTestProject` | `Packages/manifest.json` 이 없어 URP 패키지가 설치되지 않음 | `manifest.json` 추가 (URP 14.0.9, Unity 2022.3 기준) |
| NPR 4종 | Built-in 전용 코드(`CGPROGRAM`, Surface Shader)와 URP 가 뒤섞여 단계별로 이어지지 않음, 램프 텍스처 제작법 없음 | URP 단일 구현으로 재작성, `NPR/README.md` 에 전체 코드·따라 하기·램프 제작·문제 해결 수록 |
| NPR 외곽선 | 외곽선 패스에 `LightMode=ShadowCaster` → 그려지지 않음 | `SRPDefaultUnlit` 로 수정 |
| NPR 스페큘러 | `_Glossiness=0` 이면 `pow(x,0)=1` 로 전체가 하이라이트 | 지수 `max(1,…)` |
| NPR 다중 램프 | `_RampBlend` 를 Properties 에 선언하고 `SetGlobalFloat` → 머티리얼 값이 가려 스크립트 무효 | 전역용 변수를 Properties 밖에 선언 |
| NPR 램프 | `"RenderPipeline"="UniversalRenderPipeline"` (올바른 값 `UniversalPipeline`) | 수정 |
| Part 2~3 | 변수 선언·구조체·include 가 빠진 발췌 코드(NormalMapped 의 `finalColor`, SimpleRim 의 `lambert` 등), `Tags` 안의 쉼표 | 완성 셰이더를 본문에 수록 |
| Part 2 | "Light Direction 은 광원에서 표면으로" (URP `mainLight.direction` 은 표면→광원), 주석의 "+ 환경광" 오기 | 수정 |
| Part 3 | URP 에서 지원되지 않는 `GrabPass` 안내, 탄젠트 공간 설명 불완전, 구 용어 `Master Node` | 수정 |
| Part 4 | `Blit(source, source)`(읽기/쓰기 동일), 메시용 변환을 전체 화면에 사용, 컴퓨트의 범위 밖 스레드·`_Bounds` 미설정, 렌더링 코드 누락(일본어 주석 혼입) | 임시 RT + `Blitter`, 범위 검사, 렌더 셰이더 포함해 재작성 |
| ShaderLab 기초 / UnityVSAPI | `CGPROGRAM`·`fixed` 가 Built-in 전용이라는 설명 없음, 오래된 Shader Graph 용어 | 주의 문구 추가 |

## 2. HLSL/DirectX (`Shader Learning/`)
공통: 새 문서 [실습 환경과 공통 규약](../Shader%20Learning/0.%20실습%20환경과%20공통%20규약.md) 추가 (행렬 전치 규칙, 상수 버퍼 16바이트 정렬, 레지스터 슬롯, 좌표계, sRGB, `fxc` 로 문법 확인하는 법, 호스트 코드 구하는 곳).

| 문서 | 문제 | 조치 |
|---|---|---|
| Part 1 | 채팅 복사 흔적(`9월 19일 오후 9:18`) | 삭제 |
| Part 1 | 2주차 코드가 `WVP`/`World` 를 선언하지 않음, 3주차는 `...` 로 생략돼 합쳐진 코드가 없음, 행렬 전치 언급 없음, 법선 변환 한계 설명 없음 | 완성형 코드 + 합쳐진 참고 답안, 호스트 할 일 추가 |
| Part 2 | 반사율을 `MatSpecular.a` 로 쓰지만 같은 값(`w`)을 Shininess 로도 사용(충돌) | `MatExtra.x` 로 분리 |
| Part 2 | 그림자: NDC 를 UV 로 변환하지 않음(`xy/w` 를 그대로 샘플), `ShadowMapSize` 미정의, "4x4" 라 쓰고 3x3 루프, 범위 검사 없음, `TEXCOORD3` 이 TBN(`TEXCOORD2~4`)과 충돌 | 함수로 재작성(UV 변환, 범위 검사, 3x3 PCF, `SampleCmpLevelZero`), 호스트 할 일 추가 |
| Part 2 | 일본어 한자 혼입(`景色`) | 수정 |
| Part 3 | 전체 화면 VS 출력 구조체가 `VS_INPUT` 이라는 이름, 본문은 Quad 라고 하고 코드는 삼각형 | 이름·설명 정정 |
| Part 3 | GS: 빌보드 크기를 **클립 공간**에서 더함(원근 나눗셈 때문에 틀림), `PS_INPUT`/`output.Tex = ...` 미정의, `TriangleStrip` 타입(실제는 `TriangleStream`) | 월드 공간 + 카메라 right/up 방식 완성형으로 재작성 |
| Part 3 | CS: `DeltaTime` 미정의, 범위 검사 없음, 호스트 Dispatch 계산 없음 | 완성형 + 호스트 할 일 |
| Part 3 | 최적화 조언이 과장(`mad` 수동 사용, `half` 가 빠르다는 주장) | 정정 (컴파일러 자동 처리, DX11 데스크톱에서 `half`=`float`) |
| 5 PBR | 필요한 선언 없음, 선형/sRGB·감마 언급 없음, 결과가 어두운 이유 설명 없음 | 선언 추가, 색 공간/밝기 주의 추가 |
| 6 Deferred | `PS_INPUT`/`PointSampler`/`CameraPos` 미정의, G-Buffer 에 -1~1 값을 넣으면서 포맷 언급 없음 | 선언 추가, 렌더 타겟 포맷 주의 |
| 7 Tessellation | 패치 **중심** 기준 팩터 → 인접 패치 사이 균열(crack), `integer` 파티셔닝의 popping, 미정의 변수(`TerrainSize`, `WorldViewProj`, `MaxHeight`), 패치 꼭짓점 순서 불명 | 변 중점 기준 팩터, `fractional_odd`, 상수 버퍼 정의, 호스트 요구사항 명시 |

## 3. DirectX 11 (`Directx11/`)
| 문서 | 문제 | 조치 |
|---|---|---|
| 1단계 | "아래 전체 코드를 추가하고 실행"이라 했지만 **HLSL 만 있고 C++ 코드가 없음**, 존재하지 않는 "마지막 예제의 InitDevice()" 를 가리킴, 스왑체인/티어링 설명 부정확 | 창 생성~렌더 루프까지 포함한 **`main.cpp` 한 파일** 수록, 확인 사항 추가, 설명 정정 |
| 2단계 | 행렬 전치 없이 `mul(v, M)` 사용(결과가 뒤집힘), 법선 정규화·뒷면 하이라이트 처리 없음, 호스트 슬롯 불명 | 전치 업로드 코드, 셰이더 수정, 호스트 할 일 |
| 3단계 | `PS_INPUT` 미정의, 토폴로지·바인딩 안내 없음 | 구조체 추가, 호스트 요구사항 명시 |

## 4. Win32 (`Win32/`) — 이전 감사에서 빠졌던 부분
| 파일 | 문제 | 조치 |
|---|---|---|
| `HelloWorldWindow.cpp`, `SimplePaint.cpp` | 첫 줄에 `//` 없는 텍스트(`1. win api 예제`) → **컴파일 오류** | 삭제 |
| `SimpleNotepad.cpp` | `OFN_OVERWRITEPrompt` (정확한 매크로는 `OFN_OVERWRITEPROMPT`) → 컴파일 오류, `nMaxFile = sizeof(szFile)` (바이트 수를 문자 수 자리에 넣음), `pszText[dwFileSize]`(읽은 크기 사용해야 함) | 수정 |
| `Notepad/resource.cpp`, `FileSearcher/resource.cpp` | 내용은 리소스 스크립트인데 `.cpp` 확장자라 메뉴/대화상자가 빌드되지 않음 | `.rc` 로 이름 변경, 문서 안내 추가 |
| `FileSearcher.cpp` | `wsprintf` 로 `MAX_PATH` 버퍼에 쓰기(길이 검사 없음), "모달리스" 라는 잘못된 주석 | `swprintf_s`, 주석 정정 |
| 가이드/기초 문서 | 예제는 유니코드(`wWinMain`)인데 문서는 `WinMain` + 멀티바이트 설정을 권장, 예제 파일과 문서의 대응이 없음 | 예제별 파일·설정·성공 기준 표 추가 |

## 5. 아직 검토하지 못한 것
- 커리큘럼/로드맵 문서(`*커리큘럼.md`, `컴퓨터 그래픽스 학습 로드맵.md`, `고급 셰이더 기술 심화 학습 로드맵.md`)의 학습 경로·외부 링크 유효성
- Win32 2·3·4단계 문서의 이론 설명 전수 검토
- 이론 설명(수학/물리)은 코드와 직접 연결된 부분만 확인. 의심되면 Real-Time Rendering, learnopengl.com, Catlike Coding 과 대조

## 6. 앞으로 할 일
- [ ] Windows 에서 `main.cpp`·Win32 예제를 빌드해 확인하고 이슈로 보고
- [ ] Unity 2022.3 에서 NPR/Part 2~4 셰이더를 붙여 넣어 컴파일 확인
- [ ] 폴더명 오타 정리: `ShderTestProject` → `ShaderTestProject`, `Adbanced` → `Advanced` (링크 동시 수정 필요)

## 7. 문서 작성 규칙 (제안)
1. 코드 블록은 "완성형" 이거나 "발췌" 임을 표시한다. 발췌는 기준이 되는 완성형의 위치를 적는다.
2. 문서 맨 위에 환경(도구·버전)과 따라 하기 순서를 적는다.
3. PR 에는 어떤 환경에서 확인했는지(또는 확인하지 못했는지)를 적는다.
