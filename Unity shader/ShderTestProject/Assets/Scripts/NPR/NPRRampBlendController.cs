using UnityEngine;

namespace ShaderStudy.NPR
{
    /// <summary>
    /// 메인 라이트 색이 따뜻하면 Warm 램프, 차가우면 Cool 램프를 쓰도록
    /// 전역 셰이더 값 _NPR_RampBlend (0=Warm, 1=Cool) 를 갱신한다.
    /// 셰이더 쪽 선언: NPRInput.hlsl 의 "float _NPR_RampBlend;"
    /// </summary>
    [ExecuteAlways]
    public class NPRRampBlendController : MonoBehaviour
    {
        static readonly int RampBlendId = Shader.PropertyToID("_NPR_RampBlend");

        [SerializeField] Light mainLight;
        [SerializeField, Min(0.01f)] float smoothTime = 0.5f;
        [SerializeField, Range(0f, 1f)] float currentBlend;

        float velocity;

        void Update()
        {
            if (mainLight == null) return;

            // r 이 b 보다 크면 따뜻한 빛(→0), 작으면 차가운 빛(→1)
            Color c = mainLight.color;
            float target = c.r >= c.b ? 0f : 1f;

            currentBlend = Application.isPlaying
                ? Mathf.SmoothDamp(currentBlend, target, ref velocity, smoothTime)
                : target; // 에디터(비재생)에서는 즉시 반영
            Shader.SetGlobalFloat(RampBlendId, currentBlend);
        }

        void OnDisable() => Shader.SetGlobalFloat(RampBlendId, 0f);
    }
}
