// NPRInput.hlsl
// 모든 패스가 공유하는 머티리얼 변수 선언.
// SRP Batcher 호환 조건: 머티리얼 프로퍼티는 모든 패스에서 "동일한" UnityPerMaterial CBUFFER 안에 있어야 한다.
// 그래서 선언을 한 파일로 모으고 각 패스가 #include 한다. (프로퍼티 추가/삭제 시 이 파일 + Properties 블록만 수정)
#ifndef NPR_INPUT_INCLUDED
#define NPR_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_WarmRamp);
TEXTURE2D(_CoolRamp);
// 이름이 sampler_point_clamp 이면 텍스처 임포트 설정과 무관하게 Point + Clamp 로 샘플링된다 (Unity 인라인 샘플러 규칙).
SAMPLER(sampler_point_clamp);

CBUFFER_START(UnityPerMaterial)
    half4 _Color;
    half  _ShadowStrength;
    half4 _OutlineColor;
    half  _OutlineThickness;
    half4 _OutlineDistanceFade; // x: 얇아지기 시작하는 거리, y: 두께가 0이 되는 거리
    half4 _RimColor;
    half  _RimWidth;
    half  _RimSharpness;
    half4 _SpecularColor;
    half  _Glossiness;
    half  _SpecularThreshold;
CBUFFER_END

// 머티리얼 프로퍼티가 아니라 C# (NPRRampBlendController) 이 Shader.SetGlobalFloat 로 넣는 전역 값.
// Properties 블록에 선언하면 머티리얼 값이 전역 값을 가려 버리므로 일부러 Properties 에 쓰지 않는다.
float _NPR_RampBlend; // 0 = Warm 램프, 1 = Cool 램프

#endif
