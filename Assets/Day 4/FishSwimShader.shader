Shader "Custom/FishSwimShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _SwingForce ("Speed", Float) = 1.0
        _SwingWidth ("Translation", Float)= 1.0
        _HeadOffset ("Offset", Float)=1.0
    }

    SubShader
    {
        Tags 
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward" 
        }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _CLUSTER_LIGHT_LOOP
            #pragma shader_feature _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma shader_feature _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma shader_feature _ADDITIONAL_LIGHT_SHADOWS
            #pragma shader_feature _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float2 mod : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 mod : TEXCOORD1;
                float3 worldPos:TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _SwingForce;
                float _SwingWidth;
                float _HeadOffset;
            CBUFFER_END
            float3 ApplyMovement(float3 posOS, float2 uv)
            {   
                
                float domain = uv.x*2 -1;
                float swing = sin(_Time.z * _SwingForce) * _SwingWidth * domain;
                
                if(domain < 0) swing = cos(_Time.z * _SwingForce) * _SwingWidth * domain / _HeadOffset;
                return float3(posOS.x, posOS.y + swing, posOS.z);
            
            
            }
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
           

                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                
                
                IN.positionOS.xyz = ApplyMovement(IN.positionOS,IN.uv);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                //OUT.mod = float2(domain,domain);
            
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {   
                InputData lightingData = (InputData)0;
                lightingData.positionWS = IN.worldPos;
                lightingData.normalWS =  normalize(cross(ddy(IN.worldPos),ddx(IN.worldPos)));
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

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

             half4 _BaseColor;
             float4 _BaseMap_ST;
             float _SwingForce;
             float _SwingWidth;
             float _HeadOffset;

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
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos:TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
            };

           
    
            float3 ApplyMovement(float3 posOS, float2 uv)
            {   
                float domain = uv.x*2 -1;
                float swing = sin(_Time.z * _SwingForce) * _SwingWidth * domain;
                
                if(domain < 0) swing = cos(_Time.z * _SwingForce) * _SwingWidth * domain / _HeadOffset;
                return float3(posOS.x, posOS.y + swing, posOS.z);
            }

            float4 GetShadowPosHClip(Attributes Input)
            {
                float3 posWS = TransformObjectToWorld(Input.positionOS.xyz);
                float4 positionCS = TransformObjectToHClip(posWS);
                positionCS = ApplyShadowClamping(positionCS);
                return positionCS;
                
            }
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                
                IN.positionOS.xyz = ApplyMovement(IN.positionOS,IN.uv);
                OUT.positionHCS = GetShadowPosHClip(IN);
            
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
