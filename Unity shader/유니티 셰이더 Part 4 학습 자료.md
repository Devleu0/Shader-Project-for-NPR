## 유니티 셰이더 Part 4 학습 자료
이 문서는 '유니티 셰이더 16주 완성 커리큘럼'의 마지막 Part 4 내용을 보충하는 학습 자료입니다. 포스트 프로세싱, 컴퓨트 셰이더, 최적화 등 고급 주제를 마스터하고, 최종 프로젝트를 통해 실전 역량을 완성하는 것을 목표로 합니다.

## 13주차: 포스트 프로세싱 (Post-processing)
핵심 개념 상세
`포스트 프로세싱이란?`
전체 씬이 렌더링된 후, 최종 화면 이미지를 대상으로 한 번 더 셰이더를 적용하여 화면 전체에 특수 효과를 주는 기법입니다. 블룸(Bloom), 색 보정(Color Grading), 비네트(Vignette) 등이 대표적인 예입니다.

`URP에서의 구현`: Renderer Feature와 Blit
URP에서는 Renderer Feature라는 스크립터블(Scriptable) 클래스를 통해 렌더링 파이프라인에 커스텀 렌더링 패스를 쉽게 추가할 수 있습니다.

`ScriptableRendererFeature`: 렌더링 패스를 관리하는 C# 스크립트. URP 에셋의 Renderer에 추가하여 사용합니다.

`ScriptableRenderPass`: 실제 렌더링 작업을 정의하는 C# 스크립트.

`Blit`: 한 텍스처의 내용을 다른 텍스처로 복사하는 작업입니다. 포스트 프로세싱에서는 '원본 화면 텍스처'를 '커스텀 셰이더를 적용한 임시 텍스처'로, 다시 '최종 화면'으로 복사하는 과정을 거칩니다.

과제 가이드
화면 전체를 흑백으로 만드는 간단한 그레이스케일(Grayscale) 포스트 프로세싱 효과를 만들어봅니다.

1. 그레이스케일 셰이더 (PostGrayscale.shader)
```c
Shader "MyShaders/Post/Grayscale"
{
    Properties
    {
        _Intensity ("Intensity", Range(0.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex); // URP의 Blit이 화면 텍스처를 이 변수로 넘겨줌
            SAMPLER(sampler_MainTex);
            half _Intensity;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                half grayscale = dot(color.rgb, half3(0.299, 0.587, 0.114));
                half3 finalColor = lerp(color.rgb, grayscale.xxx, _Intensity);
                return half4(finalColor, color.a);
            }
            ENDHLSL
        }
    }
}
```

2. C# 스크립트 (GrayscaleFeature.cs)
이 스크립트를 생성하여 URP Renderer 에셋에 추가해야 합니다.
```c#
// GrayscaleFeature.cs
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GrayscaleFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public Material material = null;
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    public Settings settings = new Settings();
    private GrayscalePass grayscalePass;

    public override void Create()
    {
        grayscalePass = new GrayscalePass(settings.material, settings.renderPassEvent);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(grayscalePass);
    }

    class GrayscalePass : ScriptableRenderPass
    {
        private Material material;

        public GrayscalePass(Material mat, RenderPassEvent passEvent)
        {
            this.material = mat;
            this.renderPassEvent = passEvent;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (material == null) return;
            CommandBuffer cmd = CommandBufferPool.Get("GrayscalePass");
            var source = renderingData.cameraData.renderer.cameraColorTarget;
            Blit(cmd, source, source, material);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
```

## 14주차: 컴퓨트 셰이더 (Compute Shader)
핵심 개념 상세
`컴퓨트 셰이더란?`
GPU를 그래픽 렌더링뿐만 아니라 일반적인 대규모 병렬 연산(GPGPU: General-Purpose computing on GPU)에 사용하기 위해 만들어진 특수한 셰이더입니다. 수만 개의 파티클 시뮬레이션, 물리 연산, 이미지 처리 등 CPU가 처리하기 버거운 작업을 GPU의 힘으로 빠르게 처리할 수 있습니다.

핵심 구조

`커널 (Kernel)`: 컴퓨트 셰이더 내에서 실행될 수 있는 함수 단위. #pragma kernel CSMain과 같이 정의합니다.

`스레드 (Thread)`: 연산을 수행하는 가장 작은 단위.

`스레드 그룹 (Thread Group)`: 스레드들의 묶음. 컴퓨트 셰이더를 실행(Dispatch)할 때는 이 그룹 단위로 실행할 개수를 지정합니다.

`numthreads(x, y, z)`: 하나의 스레드 그룹에 몇 개의 스레드를 포함할지 지정합니다.

`버퍼 (Buffer)`: C# 스크립트와 컴퓨트 셰이더가 데이터를 주고받기 위한 메모리 공간. RWStructuredBuffer는 읽고 쓰기가 모두 가능한 버퍼입니다.

과제 가이드
수많은 파티클의 위치를 컴퓨트 셰이더로 동시에 업데이트하는 예제입니다.

1. 컴퓨트 셰이더 (ParticleUpdate.compute)
```c
#pragma kernel CSMain

struct Particle
{
    float3 position;
    float3 velocity;
};

RWStructuredBuffer<Particle> _Particles;
float _DeltaTime;
float3 _Bounds;

[numthreads(64,1,1)]
void CSMain (uint3 id : SV_DispatchThreadID)
{
    Particle p = _Particles[id.x];

    p.position += p.velocity * _DeltaTime;
    
    // 간단한 경계 처리
    if (abs(p.position.x) > _Bounds.x) p.velocity.x *= -1;
    if (abs(p.position.y) > _Bounds.y) p.velocity.y *= -1;
    if (abs(p.position.z) > _Bounds.z) p.velocity.z *= -1;

    _Particles[id.x] = p;
}
```

2. C# 디스패처 스크립트 (ParticleController.cs)
```c#
using UnityEngine;

public class ParticleController : MonoBehaviour
{
    public ComputeShader computeShader;
    public int particleCount = 10000;
    
    private ComputeBuffer particleBuffer;
    // ... (파티클 렌더링을 위한 Material, Mesh 등 필요)

    void Start()
    {
        particleBuffer = new ComputeBuffer(particleCount, sizeof(float) * 6);
        // ... (파티클 초기 데이터 설정)
        
        computeShader.SetBuffer(0, "_Particles", particleBuffer);
    }

    void Update()
    {
        computeShader.SetFloat("_DeltaTime", Time.deltaTime);
        int threadGroups = Mathf.CeilToInt(particleCount / 64f);
        computeShader.Dispatch(0, threadGroups, 1, 1);
        
        // ... (Graphics.DrawMeshInstancedなどでパーティクルを描画)
    }

    void OnDestroy()
    {
        if (particleBuffer != null) particleBuffer.Release();
    }
}
```

## 15주차: 셰이더 최적화

`연산 최적화`

`데이터 타입:` GPU 부하가 낮은 half(16비트 실수)를 우선적으로 사용하고, 높은 정밀도가 필요할 때만 float(32비트 실수)를 사용합니다.

`수학 함수:` pow, exp, log 같은 복잡한 함수는 연산 비용이 높습니다. 가능한 한 곱셈이나 lerp 등으로 대체하는 것이 좋습니다.

`브랜칭 (Branching)`: if 문은 스레드 그룹 내의 스레드들을 분기시켜 성능 저하를 유발할 수 있습니다. step, lerp, saturate 같은 내장 함수를 활용하여 if 문을 대체하는 것이 좋습니다.

`메모리 최적화`

`텍스처 샘플링:` 텍스처를 읽어오는 작업은 비용이 높습니다. 여러 번 샘플링해야 한다면, 한 번 읽어온 값을 변수에 저장하여 재사용하는 것이 좋습니다.

`Varyings`: 정점 셰이더에서 프래그먼트 셰이더로 전달하는 데이터(Varyings 구조체)가 많을수록 레지스터 사용량이 늘어납니다. 꼭 필요한 데이터만 전달해야 합니다.

`Frame Debugger` 활용
유니티의 Frame Debugger (Window > Analysis > Frame Debugger)는 렌더링 과정을 드로우 콜 단위로 분해해서 보여주는 강력한 툴입니다. 이를 통해 어떤 셰이더가 병목을 일으키는지, 불필요한 렌더링 패스가 있는지 등을 분석할 수 있습니다.

## 16주차: 최종 프로젝트 및 리뷰
프로젝트 제안: 인터랙티브 포스 필드 (Force Field) 효과
그동안 배운 기술들을 종합하여 플레이어가 충돌했을 때 물결이 퍼져나가는 포스 필드 효과를 만들어 봅니다.

기본 형태 (8주차): 정점 셰이더를 이용해 구(Sphere) 형태를 만듭니다.

외곽선 강조 (10주차): 프레넬/림 라이팅을 적용하여 은은한 테두리 효과를 추가합니다.

표면 패턴 (11주차): 노이즈 텍스처를 스크롤하여 표면에 에너지가 흐르는 듯한 느낌을 줍니다.

충돌 인터랙션 (14주차 응용):

C# 스크립트에서 충돌 지점의 월드 좌표를 셰이더에 전달합니다.

정점 셰이더에서 각 정점과 충돌 지점까지의 거리를 계산합니다.

거리를 기반으로 sin 함수와 시간(_Time)을 조합하여 퍼져나가는 물결 모양의 변위(Displacement)를 계산하고 정점 위치에 더합니다.

사라지는 효과 (11주차): clip()을 이용한 디졸브 효과를 추가하여 포스 필드가 켜지거나 꺼지는 효과를 구현할 수 있습니다.

학습 로드맵
기능 분해: 만들고 싶은 효과를 작은 기능 단위(프레넬, 정점 변위, 디졸브 등)로 나눕니다.

단계별 구현: 각 기능을 독립적으로 구현하고 테스트합니다.

통합 및 개선: 구현된 기능들을 하나의 셰이더로 합치고, 인스펙터에서 각종 파라미터를 조절하여 원하는 느낌을 만듭니다.

최적화 및 리뷰: Frame Debugger를 통해 성능을 확인하고, 불필요한 연산을 줄이는 등 최적화 작업을 진행합니다.