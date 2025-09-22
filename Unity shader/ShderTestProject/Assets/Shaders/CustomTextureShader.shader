Shader "Unlit/CustomTextureShader"
{
    Properties
    {
        // _MainTex: 텍스처 변수를 선언
        // "Albedo (RGB)"는 인스펙터에서 보이는 라벨
        // 2D: 텍스처 타입
        // "white" {}: 기본값으로 흰색 텍스처 사용
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert     
            #pragma fragment frag   

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            
            struct Attributes
            {
                float4 positionOS : POSITION; 
                float2 uv : TEXCOORD0;        // 메시의 첫 번째 UV 세트
            };

            
            struct vert2frag
            {
                float4 positionHCS : SV_POSITION; 
                float2 uv : TEXCOORD0;            // 텍스처 UV 좌표
            };

            
            // 텍스처 관련 변수
            TEXTURE2D(_MainTex);              // _MainTex 텍스처 객체 선언
            SAMPLER(sampler_MainTex);         // 샘플러 상태 (필터링/랩핑 등)
            float4 _MainTex_ST;               // Unity가 자동 제공하는 float4 값
                                              // xy = Tiling, zw = Offset

                            
            vert2frag vert (Attributes IN)
            {
                vert2frag OUT;

                // 오브젝트 공간 위치를 클립 공간 위치로 변환
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                // UV 좌표에 Tiling/Offset 적용
                // TRANSFORM_TEX 매크로 = (uv * _MainTex_ST.xy + _MainTex_ST.zw)
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                return OUT;
            }

            
            half4 frag (vert2frag IN) : SV_Target
            {
                // UV 좌표를 이용해 _MainTex 텍스처에서 색상 샘플링
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // 최종 색상 출력 (SV_Target)
                return color;
            }

            ENDHLSL
        }
    }
}
