Shader "Custom/LightBased"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Intensity ("Light Intensity", Range(0,5)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="UniversalForward" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
            };

            half4 _BaseColor;
            float _Intensity;

            Varyings vert (Attributes v) {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
                return o;
            }

            half4 frag (Varyings i) : SV_Target {
                float3 normal = normalize(i.worldNormal);
                float3 lightDir = normalize(GetMainLight().direction);
                float NdotL = saturate(dot(normal, lightDir));
                float3 litColor = _BaseColor.rgb * NdotL * _Intensity;
                return half4(litColor, 1.0);
            }
            ENDHLSL
        }
    }
}
