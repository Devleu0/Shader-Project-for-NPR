// Part 4 : 전체 화면 그레이스케일. GrayscaleFeature.cs 가 Blitter 로 호출한다. (URP 14 / Unity 2022.3)
// 일반 메시에 적용하는 셰이더가 아니다. Blit.hlsl 의 Vert 가 화면 전체 삼각형을 만든다.
Shader "Hidden/PostProcess/Grayscale"
{
    Properties
    {
        _Intensity ("Intensity", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }
        ZWrite Off ZTest Always Cull Off
        Pass
        {
            Name "Grayscale"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            half _Intensity;

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, input.texcoord);
                half gray = dot(color.rgb, half3(0.299, 0.587, 0.114));
                return half4(lerp(color.rgb, gray.xxx, _Intensity), color.a);
            }
            ENDHLSL
        }
    }
}
