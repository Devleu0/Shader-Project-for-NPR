Shader "Unlit/CustomUnlit" // 셰이더 에셋이 에디터의 Material 생성 메뉴에 나타나는 경로(카테고리/이름).
{
    // Properties 블록: 머티리얼 인스펙터에서 노출할 변수들
    Properties
    {
        // _MyColor 라는 내부 변수명을 사용. 인스펙터에선 "Display Color"로 표시되고 Color 타입을 가짐.
        // 형식과 기본값: (R, G, B, A)
        // 사용자가 머티리얼에서 색상을 바꿀 수 있도록 허용함.
        _MyColor ("Display Color", Color) = (1.0, 0.0, 0.0, 1.0) // 기본값: 불투명한 빨간색
    }

    // SubShader: 실제 렌더링을 수행하는 셰이더(하위 셰이더)
    // 여러 SubShader를 두어 다양한 하드웨어/렌더링 경로에 대응할 수 있음.
    SubShader
    {
        // 태그: 이 셰이더가 어떻게 분류되는지 엔진에 알려줌.
        // "RenderType"="Opaque"는 이 셰이더가 불투명 객체용임을 표시.
        // (예: 투명 처리 파이프라인/정렬 등에 영향을 미치거나, 리플레이스먼트 셰이더에서 사용됨)
        Tags { "RenderType"="Opaque" }

        // Pass: 하나의 렌더링 패스(여기선 단일 패스만 사용)
        Pass
        {
            // HLSLPROGRAM / ENDHLSL 블록 Unity가 내부적으로 플랫폼별 셰이더 코드로 변환함.
            HLSLPROGRAM

            // 어떤 함수가 vertex 셰이더와 fragment 셰이더인지 지정.
            #pragma vertex vert
            #pragma fragment frag

            // URP의 공용 셰이더 유틸리티를 포함.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Properties 블록에 선언한 변수와 동일한 이름으로 HLSL 변수를 선언.
            // Unity는 머티리얼의 프로퍼티 값을 이 변수에 "바인딩"해준다.
            half4 _MyColor; // 'half4'는 낮은 정밀도의 4-component 벡터(RGBA). 메모리/성능 절약용. (정밀도가 필요하면 'float4' 사용 권장)


            // vertex 입력(Attributes): 메시에 의해 전달되는 vertex 속성들
            // POSITION 시맨틱은 해당 요소가 vertex의 위치임을 나타냄 (오브젝트/모델 공간).
            struct Attributes
            {
                float4 positionOS : POSITION; // positionOS = Object Space 위치 (통상 float4(x,y,z,1))
            };

            // vertex 셰이더에서 fragment 셰이더로 전달할 데이터들을 정의.
            // 이 예제에서는 화면 위치(SV_POSITION)만 전달.
            struct vert2frag
            {
                float4 positionHCS : SV_POSITION; // SV_POSITION은 파이프라인이 기대하는 클립-공간 위치 시맨틱.
                // HCS는 여기서 'Homogeneous Clip Space' (클립 공간)를 의미하는 변수명.
            };


            // vertex 셰이더 
            // 입력: vertex 속성(오브젝트(로컬) 공간)
            // 출력: SV_POSITION에 들어갈 클립공간 위치
            vert2frag vert (Attributes IN)
            {
                vert2frag OUT;
                // 오브젝트 공간 -> 모델(월드) 공간 -> 뷰(카메라) 공간 -> 클립(프로젝션 적용) 공간
                // -> (화면 공간으로 내려가기 위해) 동차 분할(clip.xyz / clip.w) -> NDC -> 뷰포트 변환
                
                // SV_POSITION은 '클립 공간 좌표'를 기대하기 때문에 TransformObjectToHClip의 반환을 직접 넣으면 된다.
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                // 주석: TransformObjectToHClip에 IN.positionOS.xyz (float3)만 전달하는 이유는
                // 입력 위치의 w 컴포넌트(일반적으로 1.0)는 함수 내부에서 적절히 처리되기 때문임.
                // 만약 직접 매트릭스(UNITY_MATRIX_MVP 등)를 사용하면 float4(IN.positionOS.xyz, 1)로 변환해서 곱하면 됨.

                return OUT;
            }

            
            // fragment(픽셀) 셰이더
            // 입력: vertex 셰이더에서 전달된 데이터
            // 출력: 픽셀의 최종 색상 (SV_Target)
            half4 frag (vert2frag IN) : SV_Target
            {
                // 조명 계산 없이 머티리얼의 _MyColor 값을 그대로 되돌린다.
                // 반환되는 half4는 RGBA 값을 의미하며, 알파값이 1이면 불투명으로 처리된다.
                return _MyColor;
            }

            ENDHLSL
        }
    }

    // 여기에 Fallback이나 다른 SubShader를 추가할 수 있음. 이 예제는 최소 구조로 단순화되어 있음.
}
