using UnityEngine;

namespace ShaderStudy.Compute
{
    /// <summary>
    /// ParticleUpdate.compute 로 파티클을 갱신하고 ParticleRender 머티리얼로 그린다.
    /// 사용법: 빈 오브젝트에 붙이고 computeShader / renderMaterial 을 연결한다.
    /// </summary>
    public class ParticleController : MonoBehaviour
    {
        // C# 구조체와 HLSL 구조체의 메모리 배치가 같아야 한다: float3 + float3 = 24바이트
        struct Particle { public Vector3 position; public Vector3 velocity; }
        const int Stride = sizeof(float) * 6;
        const int ThreadsPerGroup = 64; // .compute 의 numthreads(64,1,1) 과 반드시 일치

        [SerializeField] ComputeShader computeShader;
        [SerializeField] Material renderMaterial;
        [SerializeField, Min(1)] int particleCount = 10000;
        [SerializeField] Vector3 bounds = new Vector3(5, 5, 5);

        ComputeBuffer buffer;
        int kernel;

        void Start()
        {
            var data = new Particle[particleCount];
            for (int i = 0; i < data.Length; i++)
            {
                data[i].position = Vector3.Scale(Random.insideUnitSphere, bounds);
                data[i].velocity = Random.onUnitSphere * Random.Range(0.5f, 2f);
            }
            buffer = new ComputeBuffer(particleCount, Stride);
            buffer.SetData(data);

            kernel = computeShader.FindKernel("CSMain");
            computeShader.SetBuffer(kernel, "_Particles", buffer);
            computeShader.SetInt("_Count", particleCount);
            computeShader.SetVector("_Bounds", bounds);
            renderMaterial.SetBuffer("_Particles", buffer);
        }

        void Update()
        {
            computeShader.SetFloat("_DeltaTime", Time.deltaTime);
            computeShader.Dispatch(kernel, Mathf.CeilToInt(particleCount / (float)ThreadsPerGroup), 1, 1);

            var drawBounds = new Bounds(transform.position, bounds * 2f);
            Graphics.DrawProcedural(renderMaterial, drawBounds, MeshTopology.Points, particleCount);
        }

        void OnDestroy()
        {
            buffer?.Release();
            buffer = null;
        }
    }
}
