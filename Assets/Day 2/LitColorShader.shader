Shader "Custom/JasonShaderTwo"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass // CUSTOM LIT
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM

            #define _SPECULAR_COLOR
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _CLUSTER_LIGHT_LOOP
            #pragma shader_feature _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma shader_feature_fragment _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma shader_feature_fragment _ADDITIONAL_LIGHT_SHADOWS
            #pragma shader_feature_fragment _SHADOWS_SOFT

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
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Unity's new lighting approach uses a lot of different struct passes
                // You have to create an InputData and a Surface Data
                
                InputData lighting = (InputData)0;
                lighting.positionWS = IN.positionWS;
                lighting.normalWS = normalize(IN.normalWS);
                lighting.viewDirectionWS = GetWorldSpaceViewDir(lighting.positionWS);
                lighting.shadowCoord = TransformWorldToShadowCoord(lighting.positionWS);
                
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = _BaseColor;
                surfaceData.alpha = 1.0;
                surfaceData.smoothness = .9;
                surfaceData.specular = .9;
                
                return UniversalFragmentBlinnPhong(lighting, surfaceData);
            }
            ENDHLSL
        }
        Pass //SHADOWS... manually
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ColorMask 0
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightPosition; // automatically filled by Unity.... sorry
            float3 _LightDirection0; // automatically filled by Unity.... sorry
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                #if _CASTING_PUNCTUAL_LIGHT_SHADOW // Needed for point light support
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                float3 lightDirectionWS = _LightDirection0;
                #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
                positionCS = ApplyShadowClamping(positionCS);
                return positionCS;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = GetShadowPositionHClip(IN);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
