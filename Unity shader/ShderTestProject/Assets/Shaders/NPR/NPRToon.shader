// NPR 툰 셰이더 (URP 14 / Unity 2022.3 기준)
// 구성: 램프 텍스처(Warm/Cool 블렌딩) + 그림자 수신 + 스페큘러 + 림 라이트 + 역면 확장 외곽선
// 패스별 코드는 같은 폴더의 .hlsl 파일에 있다. 공부할 때는 NPRToonPass.hlsl 부터 읽는다.
Shader "Tutorial/NPR/Toon"
{
    Properties
    {
        [Header(Main)]
        _Color ("기본 색상", Color) = (1,1,1,1)
        [NoScaleOffset] _WarmRamp ("따뜻한 램프", 2D) = "white" {}
        [NoScaleOffset] _CoolRamp ("차가운 램프", 2D) = "white" {}
        _ShadowStrength ("그림자 강도", Range(0,1)) = 1

        [Header(Outline)]
        _OutlineColor ("외곽선 색상", Color) = (0,0,0,1)
        _OutlineThickness ("외곽선 두께 (뷰 공간 단위)", Range(0, 0.1)) = 0.01
        _OutlineDistanceFade ("거리 페이드 (시작, 끝)", Vector) = (10, 50, 0, 0)

        [Header(Rim Light)]
        _RimColor ("림 색상", Color) = (1,1,1,1)
        _RimWidth ("림 시작 지점", Range(0, 1)) = 0.7
        _RimSharpness ("림 지수", Range(1, 5)) = 3

        [Header(Specular)]
        _SpecularColor ("스페큘러 색상", Color) = (1,1,1,1)
        _Glossiness ("광택", Range(0, 1)) = 0.5
        _SpecularThreshold ("하이라이트 컷 임계값", Range(0.5, 1)) = 0.9
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            Cull Back

            HLSLPROGRAM
            #pragma vertex ToonVert
            #pragma fragment ToonFrag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #include "NPRToonPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            // URP 는 LightMode 가 SRPDefaultUnlit 인 패스를 ForwardLit 다음에 추가로 그린다.
            Tags { "LightMode"="SRPDefaultUnlit" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex OutlineVert
            #pragma fragment OutlineFrag
            #include "NPROutlinePass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "NPRShadowCaster.hlsl"
            ENDHLSL
        }
    }
}
