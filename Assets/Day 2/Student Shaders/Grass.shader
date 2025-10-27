Shader "Custom/NewUnlitUniversalRenderPipelineShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _NoiseScale("Noise Scale", Float) = 10.0
        _NoiseStrength("Noise Strength", Float) = 0.1
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

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _NoiseScale;
                float _NoiseStrength;
            CBUFFER_END

            float2 random2(float2 st)
            {
                st = float2(
                    dot(st, float2(127.1, 311.7)),
                    dot(st, float2(269.5, 183.3))
                );
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float noise(float2 st)
            {
                float2 i = floor(st);
                float2 f = frac(st);

                float2 u = f * f * (3.0 - 2.0 * f);

                return lerp(
                    lerp(dot(random2(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                         dot(random2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
                    lerp(dot(random2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                         dot(random2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
            }

            float fbm(float2 st, int octaves)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;
                
                for (int i = 0; i < octaves; i++)
                {
                    value += amplitude * noise(st * frequency);
                    amplitude *= 0.5;
                    frequency *= 2.0;
                }
                
                return value;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 noiseUV = IN.uv * _NoiseScale;
                float noiseValue = fbm(noiseUV, 8);
                
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                color.rb = 0.;
                color.g = noiseValue * _NoiseStrength;
                
                return color;
            }
            ENDHLSL
        }
    }
}
