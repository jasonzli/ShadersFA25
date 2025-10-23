Shader "Custom/UnlitColorShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _CutoutLocation ("Cutout Location", Vector) = (0,0,0,0)
        _CutoutSize ("Cutout Size", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Day 2/JasonNoise.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _CutoutLocation;
                float _CutoutSize;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

                // get the distance
                float distanceToCutter = distance(IN.positionWS, _CutoutLocation.xyz);
                // Get the angle between the fragment and the cutout
                float angle = atan2(IN.positionWS.z - _CutoutLocation.z, IN.positionWS.x - _CutoutLocation.x);
                // use the noise now to modulate the distance
                distanceToCutter += fBM(float2( sin(angle + _Time.y), distanceToCutter + _Time.x))*.3 - fBM(float2(distanceToCutter + 345., cos(angle - _Time.x)))*.3;;
                if (distanceToCutter < _CutoutSize) clip(-1);

                float cutoutRing = _CutoutSize + .25;
                float ringFade = smoothstep(_CutoutSize, cutoutRing, distanceToCutter);
                color = lerp(half4(3,1.5,.5,1),color, ringFade);
                
                return color;
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
            #include "Assets/Day 2/JasonNoise.hlsl"

            float3 _LightPosition; // automatically filled by Unity.... sorry
            float3 _LightDirection0; // automatically filled by Unity.... sorry

            CBUFFER_START(UnityPerMaterial)
                float4 _CutoutLocation;
                float _CutoutSize;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
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
                OUT.uv = IN.uv;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                
                // get the distance
                float distanceToCutter = distance(IN.positionWS, _CutoutLocation.xyz);
                // Get the angle between the fragment and the cutout
                float angle = atan2(IN.positionWS.z - _CutoutLocation.z, IN.positionWS.x - _CutoutLocation.x);
                // use the noise now to modulate the distance
                distanceToCutter += fBM(float2( sin(angle + _Time.y), distanceToCutter + _Time.x))*.3 - fBM(float2(distanceToCutter + 345., cos(angle - _Time.x)))*.3;;
                if (distanceToCutter < _CutoutSize) clip(-1);
                
                return 0;
            }
            ENDHLSL
        }
    }
}
