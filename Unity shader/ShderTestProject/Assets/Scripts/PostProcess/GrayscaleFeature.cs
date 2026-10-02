using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ShaderStudy.PostProcess
{
    /// <summary>
    /// URP 14(Unity 2022.3) 용 Renderer Feature. 카메라 컬러를 임시 RT 에 그레이스케일로 복사한 뒤 되돌려 쓴다.
    /// "같은 텍스처를 읽으면서 동시에 쓰는" 것은 불가능하므로 임시 RT 를 거친다.
    /// 주의: Unity 6(URP 17)의 RenderGraph 에서는 이 API 가 그대로 동작하지 않는다.
    /// </summary>
    public class GrayscaleFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class Settings
        {
            public Shader shader;
            [Range(0f, 1f)] public float intensity = 1f;
            public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
        }

        public Settings settings = new Settings();
        Material material;
        GrayscalePass pass;

        public override void Create()
        {
            if (settings.shader == null) return;
            material = CoreUtils.CreateEngineMaterial(settings.shader);
            pass = new GrayscalePass(material) { renderPassEvent = settings.renderPassEvent };
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (pass == null) return;
            if (renderingData.cameraData.cameraType != CameraType.Game) return;
            material.SetFloat("_Intensity", settings.intensity);
            renderer.EnqueuePass(pass);
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            // cameraColorTargetHandle 은 AddRenderPasses 시점에는 쓸 수 없고 여기서 접근해야 한다.
            pass?.Setup(renderer.cameraColorTargetHandle);
        }

        protected override void Dispose(bool disposing)
        {
            pass?.Dispose();
            CoreUtils.Destroy(material);
        }

        class GrayscalePass : ScriptableRenderPass
        {
            readonly Material material;
            RTHandle source;
            RTHandle temp;

            public GrayscalePass(Material material) { this.material = material; }
            public void Setup(RTHandle source) { this.source = source; }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                var desc = renderingData.cameraData.cameraTargetDescriptor;
                desc.depthBufferBits = 0;
                RenderingUtils.ReAllocateIfNeeded(ref temp, desc, name: "_GrayscaleTemp");
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                var cmd = CommandBufferPool.Get("Grayscale");
                Blitter.BlitCameraTexture(cmd, source, temp, material, 0); // source -> temp (셰이더 적용)
                Blitter.BlitCameraTexture(cmd, temp, source);              // temp -> source (복사)
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            public void Dispose() { temp?.Release(); }
        }
    }
}
