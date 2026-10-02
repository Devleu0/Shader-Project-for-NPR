# NPR(툰) 셰이더 실습

URP 기반 툰 셰이더를 단계별로 만들어 보는 실습입니다. **모든 코드는 `../ShderTestProject` 에 완성본이 있고, 문서는 그 코드의 읽는 순서와 원리를 설명합니다.**

## 환경

| 항목 | 값 |
|---|---|
| Unity | 2022.3.14f1 이상 2022.3 LTS (`ProjectSettings/ProjectVersion.txt`) |
| 렌더 파이프라인 | URP 14.0.x (`Packages/manifest.json` 에 명시) |
| 열기 | Unity Hub → Add → `Unity shader/ShderTestProject` 폴더 |

> Built-in 파이프라인용 옛 버전은 [`NPR_shader.shader`](./NPR_shader.shader) 로 보관만 합니다. (`Assets` 밖에 있어 Unity 가 컴파일하지 않습니다.) URP 프로젝트에서는 **분홍색**으로 보이므로 쓰지 마세요.

## 파일 구조 (모듈)

```
Assets/
├─ Shaders/NPR/
│   ├─ NPRToon.shader         # 프로퍼티 + 패스 3개 (조립만 한다)
│   ├─ NPRInput.hlsl          # 머티리얼 변수 선언 (모든 패스 공유)
│   ├─ NPRToonPass.hlsl       # 본체: 램프 + 스페큘러 + 림 + 그림자 수신
│   ├─ NPROutlinePass.hlsl    # 역면 확장 외곽선
│   └─ NPRShadowCaster.hlsl   # 그림자 맵 기록
├─ Textures/NPR/              # Ramp_Toon3 / Ramp_Warm / Ramp_Cool (256x16)
└─ Scripts/NPR/NPRRampBlendController.cs
```

기능을 추가할 때는 `.hlsl` 한 곳만 고치고, 변수를 추가하면 `NPRInput.hlsl` 과 `NPRToon.shader` 의 Properties 두 곳을 같이 고칩니다.

## 학습 순서

1. [램프 텍스처](./램프%20텍스처.md) — 툰 명암
2. [역면 확장 기법](./역면%20확장%20기법.md) — 외곽선
3. [림 라이트와 스페큘러](./림%20라이트와%20스페큘러.md) — 디테일
4. [다중 램프 혼합 시스템](./다중%20램프%20혼합%20시스템.md) — 환경별 램프 블렌딩

## 처음 실행하기 (체크리스트)

1. 프로젝트를 열고 패키지 임포트가 끝날 때까지 기다립니다 (URP 가 내려받아집니다).
2. Project 창에서 `Assets/Shaders/NPR/NPRToon.shader` 우클릭 → Create → Material.
3. 머티리얼의 **Warm Ramp / Cool Ramp** 슬롯에 `Ramp_Warm` / `Ramp_Cool` (또는 둘 다 `Ramp_Toon3`) 을 넣습니다.
4. 씬에 Sphere 를 만들고 머티리얼을 적용합니다. 계단 모양 명암 + 검은 외곽선이 보이면 성공입니다.
5. 콘솔(Console)에 셰이더 컴파일 에러가 없는지 확인합니다.

## 자주 막히는 곳

| 증상 | 원인 / 해결 |
|---|---|
| 분홍색 | URP 가 설정되지 않음. Edit → Project Settings → Graphics 에 URP 에셋이 있는지 확인 |
| 외곽선이 안 보임 | 두께(`_OutlineThickness`)가 0 이 아닌지, 외곽선 패스의 `LightMode` 가 `SRPDefaultUnlit` 인지 확인 |
| 그림자를 안 받음 | Directional Light 의 Shadow Type 이 No Shadows 이거나 URP 에셋의 Main Light Cast Shadows 가 꺼짐 |
| 큐브 모서리에서 외곽선이 갈라짐 | 하드 에지 메시는 법선이 면마다 달라 생기는 현상. 스무스 법선 메시(구, 캐릭터)로 확인 |

> **검증 상태**: 이 셰이더는 URP 14 공식 Lit 셰이더의 구조(그림자 매크로, ShadowCaster 바이어스 등)를 따라 작성했지만, 작성 환경에 Unity 가 없어 에디터에서 직접 컴파일해 보지는 못했습니다. 에러가 나면 콘솔 메시지와 함께 이슈로 남겨 주세요.
