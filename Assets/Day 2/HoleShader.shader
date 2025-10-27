Shader "Custom/CutoutExampleDay2"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _CutoutLocation("Cutout Location", Vector) = (0,0,0,0)
        _CutoutRadius ("Cutout Radius", Float) = 1
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
            Cull off
            // Inside here is entirely HLSL Code
            HLSLPROGRAM

            #pragma vertex vert 
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            // Preprocessor directions to include additional libraries. These basically copy and paste code from the files here
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Day 2/JasonNoise.hlsl"

            float4 _BaseColor;
            float4 _CutoutLocation;
            float _CutoutRadius;
            
            struct Attributes
            {
                // Position object space positionOS
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            // You might see something called appdata (now Attributes) in built in shaders
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); //transform the vertex's object space position to homogeneous clip space (screen)
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz); // transform the vertex's object space position to world space
                OUT.uv = IN.uv;
                return OUT; //return an instance of the Varyings struct
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 color = _BaseColor.rgb;
                float dist = distance(IN.worldPos.xyz, _CutoutLocation.xyz);
                float angle = atan2(IN.worldPos.z - _CutoutLocation.z, IN.worldPos.x - _CutoutLocation.x);
                float2 noiseCoordinate = float2( sin(angle + _Time.y) ,dist);
                float2 noiseCoordinate2 = float2( cos(angle - _Time.y) ,dist + 362);
                dist += fBM(noiseCoordinate) * .3 - fBM(noiseCoordinate2) * .3;
                
                if (dist < _CutoutRadius) clip(-1);
                
                float cutoutRing = _CutoutRadius + .25;
                float ringFade = smoothstep(_CutoutRadius, cutoutRing, dist);
                color = lerp(half3(3,1.5,.5),color, ringFade);
                return half4(color,1);
            }
            ENDHLSL
        }

        // Shadows require an additional pass, which writes data to a shadow map which the shader samples in the above pass
        // This is a copy-pase of the one from the documentation
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
}
 