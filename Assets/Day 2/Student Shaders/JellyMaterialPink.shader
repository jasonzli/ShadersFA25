Shader "Custom/JellyMaterialPink"
{
    Properties
    {
        [MainColor]_BaseColor("BaseColor", Color) = (1, 0.8, 0.6, 0.6)
        _EdgeColor("EdgeColor", Color) = (1, 1, 1, 1)

        _Smoothness("Smoothness", Range(0,1)) = 0.9
        _Metalic("Metalic", Range(0,1)) = 0.0
        _Transparency("Transparency", Range(0,1)) = 0.6

        _FresnelBorder("Fresnel Boder", Range(0.5, 10)) = 2.0
        _FresnelIntensity("Fresnel Intensity", Range(0, 2)) = 1.0
        _SpecularIntensity("Specular Intensity", Range(0, 2)) = 0.6
    }

    SubShader
    {
        Tags{"RenderType" = "Transparent"
             "Queue" = "Transparent"
             "RenderPipeline" = "UniversalPipeline"}

        ZWrite Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float3 positionWS : TEXCOORD0;
                float4 positionHCS: SV_POSITION;
                float3 normalWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _EdgeColor;
                float _FresnelBorder;
                float _FresnelIntensity;
                float _Metalic;
                float _Smoothness;
                float _SpecularIntensity;
                float _Transparency;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 Normal = normalize(IN.normalWS);
                float3 LightDirection = GetMainLight().direction;

                float viewDirection = normalize(_WorldSpaceCameraPos - IN.positionWS);

                float NdotL = saturate(dot(Normal, LightDirection));
                float spec = pow(NdotL, lerp(15.0, 128.0, _Smoothness)) * _SpecularIntensity;
                float fresnel = pow(1.0 - saturate(dot(Normal, viewDirection)), _FresnelBorder) * _FresnelIntensity;

                float3 baseColor = _BaseColor.rgb;
                float3 jellyColor = baseColor + _EdgeColor.rgb * fresnel + spec;

                return float4(jellyColor, _Transparency);
            }
            ENDHLSL
        }
    }
}