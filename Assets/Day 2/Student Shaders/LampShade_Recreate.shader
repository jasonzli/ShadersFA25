Shader "Custom/LampShade_Recreate"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BackColor("Background Color", Color ) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
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
                half4 _BackColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }
            float mix(float a, float b, float c){
            
                return a * (1 - c) + b * c;
            }
            float hash21(float2 uv){
                return frac(2034.2 * sin(uv.x * 22.22234+ uv.y * 24.567)) ;
            }
            float noise21(float2 uv){
  
                float2 scaleUV = floor(uv);
                float2 unitUV = frac(uv);
  
                float2 noiseUV = scaleUV;
  
                float value1 = hash21(noiseUV);
                float value2 = hash21(noiseUV + float2(1,0));
                float value3 = hash21(noiseUV + float2(0,1));
                float value4 = hash21(noiseUV + float2(1,1));
  
                unitUV = smoothstep(float2(0,0),float2(1, 1),unitUV);
  
                float bresult = mix(value1,value2,unitUV.x);
                float tresult = mix(value3,value4,unitUV.x);
  
                return mix(bresult,tresult,unitUV.y);
            }

            half4 frag(Varyings IN) : SV_Target
            {   
                float2 frc_UV = frac(IN.uv * 10);
                float2 fl_UV = floor(IN.uv / .1);   

                float noise = noise21(fl_UV);
                float j = smoothstep(.1 * noise, .05, abs(frc_UV.x - .5));
                float i = smoothstep(.05, .1 *noise, abs(frc_UV.y - .5));
                float3 o = float3(0,0,0);
                if(noise > 0.5){
                    o = float3(10 * j,10 * j,10 * j);
                }else{
                    o = float3(10 * i, 10 * i,10 * i);
                }
                float3 col = (o / 10) * _BaseColor;
                float3 back = (1 - o/10) * _BackColor;
                float3 comb = col + back;
                half4 color = half4(comb.x, comb.y,comb.z, 1);
                //color = half4(noise, noise, noise, 1);
                return color;
            }
            ENDHLSL
        }
    }
}
