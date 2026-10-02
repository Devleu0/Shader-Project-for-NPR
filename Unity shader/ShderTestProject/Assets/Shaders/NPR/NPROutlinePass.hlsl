// NPROutlinePass.hlsl : 역면 확장(Inverted Hull) 외곽선 패스
#ifndef NPR_OUTLINE_PASS_INCLUDED
#define NPR_OUTLINE_PASS_INCLUDED

#include "NPRInput.hlsl"

struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; };
struct Varyings   { float4 positionCS : SV_POSITION; };

Varyings OutlineVert(Attributes IN)
{
    Varyings OUT;
    float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

    // 카메라 거리에 따라 두께를 줄인다. (분모가 0 이 되지 않도록 보호)
    float dist = distance(positionWS, _WorldSpaceCameraPos);
    float range = max(_OutlineDistanceFade.y - _OutlineDistanceFade.x, 1e-4);
    float fade = 1.0 - saturate((dist - _OutlineDistanceFade.x) / range);
    float thickness = _OutlineThickness * fade;

    // 뷰 공간에서 법선 방향으로 밀어낸다.
    float3 positionVS = TransformWorldToView(positionWS);
    float3 normalVS   = normalize(TransformWorldToViewDir(normalWS));
    positionVS += normalVS * thickness;

    OUT.positionCS = mul(GetViewToHClipMatrix(), float4(positionVS, 1.0));
    return OUT;
}

half4 OutlineFrag(Varyings IN) : SV_Target { return _OutlineColor; }

#endif
