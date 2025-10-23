Shader "Custom/ForwardPlus_CustomLighting"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _BaseMap("Base Map", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "LightMode"="UniversalForward" "RenderType"="Opaque" }

        Pass
        {
            Name "ForwardPlusLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Enable main shadows, cascades, additional lights, additional shadows
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            // For Forward+ support
            #pragma multi_compile _ _LIGHTLOOP_ON  // must match URP’s internal keyword for forward+ light loops  


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseColor;
            float4 _BaseMap_ST;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 worldPos    : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float2 uv          : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs posInputs = GetVertexPositionInputs(IN.positionOS);
                OUT.positionHCS = posInputs.positionCS;
                OUT.worldPos = posInputs.positionWS;
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.shadowCoord = GetShadowCoord(posInputs);

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.worldNormal);
                float3 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).rgb * _BaseColor.rgb;

                // --- Main light (directional) ---
                Light mainLight = GetMainLight();
                float3 Lmain = normalize(mainLight.direction);
                float NdotL_main = saturate(dot(normal, Lmain));

                half shadowMain = MainLightRealtimeShadow(IN.shadowCoord);
                float3 lightContribution = mainLight.color.rgb * NdotL_main * shadowMain;

                // --- Additional lights loop (Forward+ path) ---
                int addCount = GetAdditionalLightsCount();
                for (int i = 0; i < addCount; ++i)
                {
                    Light add = GetAdditionalLight(i, IN.worldPos);
                    float3 Li = normalize(add.direction);
                    float NdotLi = saturate(dot(normal, Li));
                    half shadowAdd = AdditionalLightRealtimeShadow(i, IN.worldPos, Li);

                    // Distance attenuation
                    float atten = add.distanceAttenuation;
                    lightContribution += add.color.rgb * NdotLi * atten * shadowAdd;
                }

                float3 finalColor = baseColor * lightContribution;

                return half4(finalColor, 1.0);
            }

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }

    FallBack Off
}
