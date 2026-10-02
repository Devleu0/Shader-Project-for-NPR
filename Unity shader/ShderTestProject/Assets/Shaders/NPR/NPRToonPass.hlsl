// NPRToonPass.hlsl : 본체 패스 (툰 램프 + 스페큘러 + 림 라이트 + 그림자 수신)
#ifndef NPR_TOON_PASS_INCLUDED
#define NPR_TOON_PASS_INCLUDED

#include "NPRInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS   : NORMAL;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 normalWS   : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
};

Varyings ToonVert(Attributes IN)
{
    Varyings OUT;
    OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    OUT.positionCS = TransformWorldToHClip(OUT.positionWS);
    OUT.normalWS   = TransformObjectToWorldNormal(IN.normalOS);
    return OUT;
}

half4 ToonFrag(Varyings IN) : SV_Target
{
    float3 normalWS = normalize(IN.normalWS);
    float3 viewDir  = GetWorldSpaceNormalizeViewDir(IN.positionWS);

    // 그림자 좌표 -> 메인 라이트 (shadowAttenuation 에 그림자 결과가 들어 있다)
    float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
    Light mainLight = GetMainLight(shadowCoord);
    float3 lightDir = mainLight.direction;
    half shadow = lerp(1.0h, mainLight.shadowAttenuation, _ShadowStrength);

    // 1) 램프 텍스처 : NdotL(-1~1) -> 0~1 -> 램프의 가로(U) 좌표
    half NdotL = dot(normalWS, lightDir) * 0.5h + 0.5h;
    half2 rampUV = half2(NdotL, 0.5h);
    half3 warm = SAMPLE_TEXTURE2D(_WarmRamp, sampler_point_clamp, rampUV).rgb;
    half3 cool = SAMPLE_TEXTURE2D(_CoolRamp, sampler_point_clamp, rampUV).rgb;
    half3 ramp = lerp(warm, cool, saturate(_NPR_RampBlend));
    // 그림자 안에서는 램프의 가장 어두운 칸을 쓴다 (단순 곱셈보다 만화 느낌이 유지된다)
    half3 darkest = lerp(SAMPLE_TEXTURE2D(_WarmRamp, sampler_point_clamp, half2(0, 0.5)).rgb,
                         SAMPLE_TEXTURE2D(_CoolRamp, sampler_point_clamp, half2(0, 0.5)).rgb,
                         saturate(_NPR_RampBlend));
    ramp = lerp(darkest, ramp, shadow);
    half3 color = _Color.rgb * ramp * mainLight.color;

    // 2) 스페큘러 : Blinn-Phong 을 step 으로 잘라 딱딱한 하이라이트로 만든다
    float3 halfDir = normalize(lightDir + viewDir);
    half exponent = max(1.0h, _Glossiness * 128.0h); // 0 이면 pow(x,0)=1 이 되어 전체가 빛나는 버그 방지
    half spec = pow(saturate(dot(normalWS, halfDir)), exponent);
    spec = step(_SpecularThreshold, spec) * shadow;
    color += _SpecularColor.rgb * spec;

    // 3) 림 라이트
    half rim = 1.0h - saturate(dot(viewDir, normalWS));
    rim = pow(rim, _RimSharpness);
    rim = smoothstep(_RimWidth, 1.0h, rim);
    color += _RimColor.rgb * rim;

    return half4(color, 1.0h);
}

#endif
