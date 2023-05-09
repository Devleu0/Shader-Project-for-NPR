Shader "HelloShaderLab"
{
    Properties {
        _Color ("Main Color", Color) = (1,.5,.5,1)
    }
    SubShader
    {
        Pass
        {
            Material
            {
                Diffuse [_Color]
            }
            Lighting On
        }
        Pass{
            CGPROGRAM
            
            ENDCG
        }
    }
}