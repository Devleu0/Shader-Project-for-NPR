Shader "Unlit/LambertianLighting"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        // URP의 Lit 셰이더로 인식시키기 위한 태그
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" }

        Pass
        {
            // URP의 조명 패스임을 명시
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert            
            #pragma fragment frag          

            // URP 공용 셰이더 함수/상수 포함
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // 조명 관련 함수 포함 (GetMainLight 등)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                float4 positionOS   : POSITION; 
                float3 normalOS     : NORMAL;   // 오브젝트 공간에서의 정점 법선 벡터
            };
            
            struct vert2frag
            {
                float4 positionHCS  : SV_POSITION; 
                float3 normalWS     : TEXCOORD0;   // 월드 공간 법선 벡터
            };

            
            // 머티리얼 상수 버퍼
            
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor; // 기본 색상 (RGB + 알파)
            CBUFFER_END

            
            
            vert2frag vert (Attributes IN)
            {
                vert2frag OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            
                // 법선 벡터를 오브젝트 공간 → 월드 공간으로 변환
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
            
                return OUT;
            }

            
            half4 frag (vert2frag IN) : SV_Target
            {
                // 보간 과정에서 길이가 변할 수 있으므로 정규화
                float3 normalWS = normalize(IN.normalWS);
            
                // URP에서 메인 광원 정보 가져오기
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction; // 광원 방향 (단위벡터)
            
                // Lambert 확산 조명 계산
                // 내적(dot) = 법선과 광원 방향 사이의 cosθ
                // saturate: 값이 0 이하로 내려가지 않도록 clamping
                half lambert = saturate(dot(normalWS, lightDir));
            
                // 최종 색상 계산
                // finalColor = 기본색 * Lambert 반사 계수 * 광원 색상
                half3 finalColor = _BaseColor.rgb * lambert * mainLight.color;
            
                // 알파 채널은 1.0 (불투명)
                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
