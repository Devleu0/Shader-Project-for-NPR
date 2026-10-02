// Part 2 : Lambert + Blinn-Phong 스페큘러 (URP)
Shader "Lessons/BlinnPhong"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(0.1, 100)) = 20
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; };
            struct Varyings   { float4 positionHCS : SV_POSITION; float3 normalWS : TEXCOORD0; float3 positionWS : TEXCOORD1; };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half  _Shininess;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 N = normalize(IN.normalWS);
                Light light = GetMainLight();
                float3 L = light.direction;
                float3 V = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                float3 H = normalize(L + V);

                half diffuse  = saturate(dot(N, L));
                half specular = pow(saturate(dot(N, H)), _Shininess) * step(0.0, diffuse);
                half3 color = (_BaseColor.rgb * diffuse + specular) * light.color;
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
