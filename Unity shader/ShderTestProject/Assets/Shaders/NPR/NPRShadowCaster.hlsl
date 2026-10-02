// NPRShadowCaster.hlsl : 그림자 맵에 이 오브젝트를 그리는 패스 (URP Lit 의 ShadowCasterPass 와 같은 구조)
#ifndef NPR_SHADOW_CASTER_INCLUDED
#define NPR_SHADOW_CASTER_INCLUDED

#include "NPRInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;
float3 _LightPosition;

struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; };
struct Varyings   { float4 positionCS : SV_POSITION; };

Varyings ShadowVert(Attributes IN)
{
    Varyings OUT;
    float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 lightDirWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirWS = _LightDirection;
#endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirWS));
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif
    OUT.positionCS = positionCS;
    return OUT;
}

half4 ShadowFrag(Varyings IN) : SV_Target { return 0; }

#endif
