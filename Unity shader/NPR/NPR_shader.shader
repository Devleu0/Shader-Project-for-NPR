Shader "Tutorial/NPR_Cel_Shader"
{
   Properties
   {
       [Header(Main Settings)]
       _Color ("기본 색상", Color) = (1,1,1,1)
       _RampTex ("램프 텍스처", 2D) = "white" {}

       [Header(Outline)]
       _OutlineColor ("외곽선 색상", Color) = (0,0,0,1)
       _OutlineThickness ("외곽선 두께", Range(0, 0.1)) = 0.01
       _OutlineDistanceFade ("거리 비례 두께 (시작, 끝)", Vector) = (10, 50, 0, 0)

       [Header(Rim Light)]
       _RimColor ("림 라이트 색상", Color) = (1,1,1,1)
       _RimWidth ("림 라이트 범위", Range(0, 1)) = 0.7
       _RimSharpness ("림 라이트 경계", Range(1, 5)) = 3.0

       [Header(Specular)]
       _SpecularColor ("스페큘러 색상", Color) = (1,1,1,1)
       _Glossiness ("광택", Range(0, 1)) = 0.5
   }
   SubShader
   {
       Tags { "RenderType"="Opaque" "Queue"="Geometry"}
       LOD 100

       // 본체 그리기
       Pass
       {
           Tags { "LightMode"="ForwardBase" }
           Cull Back

           CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
           // 셰이더가 그림자를 받도록 설정
           #pragma multi_compile_fwdbase
           #include "UnityCG.cginc"
           #include "AutoLight.cginc" // 그림자 계산을 위해 포함

           
           fixed4 _Color;
           sampler2D _RampTex;
           fixed4 _RimColor;
           half _RimWidth;
           half _RimSharpness;
           fixed4 _SpecularColor;
           half _Glossiness;

           
           struct appdata
           {
               float4 vertex : POSITION;
               float3 normal : NORMAL;
               float2 uv : TEXCOORD0;
           };

           struct v2f
           {
               float4 pos : SV_POSITION;
               float3 worldNormal : TEXCOORD0;
               float3 worldPos : TEXCOORD1;
               // SHADOW_COORDS(2)는 그림자 계산에 필요한 좌표를 저장할 공간(TEXCOORD2)을 선언
               SHADOW_COORDS(2) 
           };

           v2f vert (appdata v)
           {
               v2f o;
               o.pos = UnityObjectToClipPos(v.vertex);
               o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
               o.worldNormal = UnityObjectToWorldNormal(v.normal);
               // TRANSFER_SHADOW(o)는 그림자 계산에 필요한 데이터를 v2f 구조체로 전달
               TRANSFER_SHADOW(o);
               return o;
           }

           fixed4 frag (v2f i) : SV_Target
           {
               // ---- 기본 준비 ----
               float3 normalDir = normalize(i.worldNormal);
               float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
               // Unity의 주 광원 방향 (_WorldSpaceLightPos0)
               float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

               // ---- 그림자 계산 ----
               // SHADOW_ATTENUATION(i) 매크로는 현재 픽셀이 그림자 안에 있는지 계산하여 0~1 값을 반환
               fixed shadow = SHADOW_ATTENUATION(i);

               // ---- 램프 텍스처 기반 명암 계산 ----
               half NdotL = dot(normalDir, lightDir);
               NdotL = NdotL * 0.5 + 0.5;
               half3 ramp = tex2D(_RampTex, float2(NdotL, 0.5)).rgb;
               // 그림자 값을 곱하여 명암에 그림자를 적용
               half3 albedo = _Color.rgb * ramp * shadow;

               // ---- 스페큘러 계산 ----
               half3 halfVector = normalize(lightDir + viewDir);
               float NdotH = pow(saturate(dot(normalDir, halfVector)), _Glossiness * 128);
               // 그림자가 비치는 곳에는 스페큘러가 생기지 않도록 shadow 값을 곱함
               float specular = step(0.9, NdotH) * shadow;
               half3 finalSpecular = _SpecularColor.rgb * specular;

               // ---- 림 라이트 계산 ----
               half dotViewNormal = dot(viewDir, normalDir);
               half rim = 1.0 - saturate(dotViewNormal);
               rim = pow(rim, _RimSharpness);
               rim = smoothstep(_RimWidth, 1.0, rim);
               half3 finalRim = _RimColor.rgb * rim;

               // ---- 최종 색상 조합 ----
               // (기본 명암 + 스페큘러)에 림 라이트를 더함
               fixed3 finalColor = albedo + finalSpecular + finalRim;
               
               return fixed4(finalColor, 1.0);
           }
           ENDCG
       }


       //외곽선 그리기
       Pass
       {
           Cull Front
           
           CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
           #include "UnityCG.cginc"

           float4 _OutlineColor;
           float _OutlineThickness;
           float4 _OutlineDistanceFade;

           struct appdata
           {
               float4 vertex : POSITION;
               float3 normal : NORMAL;
           };

           struct v2f
           {
               float4 pos : SV_POSITION;
           };

           v2f vert (appdata v)
           {
               v2f o;

               float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
               float distance = length(worldPos - _WorldSpaceCameraPos);
               float distanceFade = 1.0 - saturate((distance - _OutlineDistanceFade.x) / (_OutlineDistanceFade.y - _OutlineDistanceFade.x));
               float finalThickness = _OutlineThickness * distanceFade;

               float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
               float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
               viewPos.xyz += normalize(viewNormal) * finalThickness;
               
               o.pos = mul(UNITY_MATRIX_P, viewPos);
               return o;
           }

           fixed4 frag (v2f i) : SV_Target
           {
               return _OutlineColor;
           }
           ENDCG
       }
   }
   FallBack "Diffuse"
   CustomEditor "UnityEditor.ShaderGUI"
}