Shader "Custom/VertexAnimationLit"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _WingHeight("Wing Height", Float) = 1.0
        _FlapSpeed("Flap Speed", Float) = 1.0
    }
    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward"
        }
        
        Pass
        {
            Cull Off
            HLSLPROGRAM

            #pragma vertex vertex
            #pragma fragment fragment

            #pragma shader_feature _CLUSTER_LIGHT_LOOP
            #pragma shader_feature _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma shader_feature _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma shader_feature _ADDITIONAL_LIGHT_SHADOWS
            #pragma shader_feature _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float4 _BaseColor;
            float _WingHeight;
            float _FlapSpeed;
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // for rendering final fragment
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1; // maybe...?
                float3 worldNormal : TEXCOORD2; // also maybe...?
            };

            float3 ApplyWingFlap(float3 positionOS, float2 uv)
            {
                float distance = abs(.5-uv.x); // .5 and .5 at the edges
                distance *= 2; // now [1,1] at edges and 0 in middle

                // Move the vertex up and down based on distance from the center and time
                float heightOffset = sin(_Time.y * _FlapSpeed) * _WingHeight * distance; // distance will be 0 at center!
                return float3(positionOS.x, positionOS.y + heightOffset, positionOS.z);
                
            }
            Varyings vertex(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                //OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv; // using the UV coordinate now...
                
                // Move the vertex up and down based on distance from the center and time
                IN.positionOS.xyz = ApplyWingFlap(IN.positionOS.xyz, IN.uv);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                
                return OUT;
            }

            half4 fragment(Varyings IN) : SV_Target
            {
                InputData lightingData = (InputData)0;
                lightingData.positionWS = IN.worldPos;
                lightingData.normalWS = normalize(IN.worldNormal);
                lightingData.viewDirectionWS = GetWorldSpaceViewDir(lightingData.positionWS);
                lightingData.shadowCoord = TransformWorldToShadowCoord(lightingData.positionWS);

                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = _BaseColor;
                surfaceData.alpha = 1.0;
                surfaceData.smoothness = .5;
                surfaceData.specular = .5;

                return UniversalFragmentBlinnPhong(lightingData, surfaceData);
            }

            
            ENDHLSL
        }
        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }
            HLSLPROGRAM

            #pragma vertex vertex
            #pragma fragment fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float4 _BaseColor;
            float _WingHeight;
            float _FlapSpeed;

            float3 _LightDirection0;
            float3 _LightPosition;
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // for rendering final fragment
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1; // maybe...?
                float3 worldNormal : TEXCOORD2; // also maybe...?
            };

            float4 GetShadowPositionHClip(Attributes Input)
            {
                float3 positionWS = TransformObjectToWorld(Input.positionOS.xyz);
                float4 positionCS = TransformWorldToHClip(positionWS);
                positionCS = ApplyShadowClamping(positionCS);
                return positionCS;
            }

            float3 ApplyWingFlap(float3 positionOS, float2 uv)
            {
                float distance = abs(.5-uv.x); // .5 and .5 at the edges
                distance *= 2; // now [1,1] at edges and 0 in middle

                // Move the vertex up and down based on distance from the center and time
                float heightOffset = sin(_Time.y * _FlapSpeed) * _WingHeight * distance; // distance will be 0 at center!
                return float3(positionOS.x, positionOS.y + heightOffset, positionOS.z);
                
            }
            
            Varyings vertex(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                //OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv; // using the UV coordinate now...

                
                float distance = abs(.5-IN.uv.x); // .5 and .5 at the edges
                distance *= 2; // now [1,1] at edges and 0 in middle

                // Move the vertex up and down based on distance from the center and time
                IN.positionOS.xyz = ApplyWingFlap(IN.positionOS.xyz, IN.uv);
                OUT.positionHCS = GetShadowPositionHClip(IN);
                
                return OUT;
            }


            half4 fragment(Varyings IN) : SV_Target
            {
                return 0;
            }

            
            ENDHLSL
        }
    
    }
}
