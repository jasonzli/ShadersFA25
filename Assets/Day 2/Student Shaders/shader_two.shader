Shader "Custom/shader_two"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap("Base Map", 2D) = "white" {}
        _TimeScale("Time Scale", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

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
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float _TimeScale;
            CBUFFER_END

            // --- GLSL hash21 equivalent ---
            float hash21(float2 v)
            {
                return frac(22352.3 * sin(v.x * 992.234 + v.y * 232.35));
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
                float2 resolution = _ScreenParams.xy;  // replacement for u_resolution
                float u_time = _Time.y * _TimeScale;   // Unity’s built-in _Time.y (in seconds)

                // Convert UVs to match GLSL space
                float2 st = IN.uv;
                st = st * 3.0;

                float2 cell = floor(st);
                float2 uv = frac(st);

                // Pixelate
                uv = floor(uv * 32.0) / 32.0;

                // Random values (simplified since GLSL version had invalid float(cell*11.) syntax)
                float random1 = hash21(cell * 11.0);
                float random2 = hash21(cell * 12.0);

                // Colors
                float3 col = float3(random1 / 10.0 + sin(u_time), 0.3, 0.7);
                float3 colB = float3(0.8, 0.0, frac(u_time / 10.0) + 0.2);

                // Circle 1
                float2 spaced = uv * 2.0 - 1.0;
                float r = length(spaced) - 0.5;
                float r2 = abs(r);
                float r3 = smoothstep(-0.01, 0.1, r2);
                float3 circleMask = col * (1.0 - r3);

                // Circle 2
                spaced.x = spaced.x * 2.5 + sin(u_time / 5.0);
                spaced.y = spaced.y * 2.5 + cos(u_time / 5.0);
                float rb = length(spaced) - 0.2;
                float rb2 = abs(rb);
                float rb3 = smoothstep(-0.0008, 0.08, rb2);
                float3 circleBMask = colB * (1.0 - rb3);

                float3 finalColor = circleMask + circleBMask;
                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
