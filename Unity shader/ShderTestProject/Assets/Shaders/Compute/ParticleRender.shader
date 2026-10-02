// Part 4 : StructuredBuffer 의 위치를 읽어 점으로 그린다. (Graphics.DrawProcedural + MeshTopology.Points)
// DX11/DX12 에서 점은 1픽셀이다. 크기를 키우려면 쿼드로 확장하는 방식(지오메트리/인스턴싱)이 필요하다.
Shader "Lessons/ParticleRender"
{
    Properties { _Color ("Color", Color) = (1, 0.8, 0.2, 1) }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        Pass
        {
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Particle { float3 position; float3 velocity; };
            StructuredBuffer<Particle> _Particles;
            half4 _Color;

            struct Varyings { float4 positionHCS : SV_POSITION; };

            Varyings vert(uint vertexID : SV_VertexID)
            {
                Varyings OUT;
                OUT.positionHCS = TransformWorldToHClip(_Particles[vertexID].position);
                return OUT;
            }
            half4 frag(Varyings IN) : SV_Target { return _Color; }
            ENDHLSL
        }
    }
}
