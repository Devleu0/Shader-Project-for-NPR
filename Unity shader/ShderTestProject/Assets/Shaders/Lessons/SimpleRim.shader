// Part 3 : 프레넬 림 라이트
Shader "Lessons/SimpleRim"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _RimColor ("Rim Color", Color) = (0,1,1,1)
        _RimPower ("Rim Power", Range(0.1, 10)) = 3
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
                half4 _RimColor;
                half  _RimPower;
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
                float3 V = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                Light light = GetMainLight();
                half lambert = saturate(dot(N, light.direction));
                half rim = pow(1.0 - saturate(dot(N, V)), _RimPower);
                half3 color = _BaseColor.rgb * lambert * light.color + _RimColor.rgb * rim;
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
