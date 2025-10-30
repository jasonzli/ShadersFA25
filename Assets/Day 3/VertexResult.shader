Shader "Custom/VertexAnimation"
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
            HLSLPROGRAM

            #pragma vertex vertex
            #pragma fragment fragment

            #pragma shader_feature _MAIN_LIGHT_SHADOWS
            #pragma shader_feature _MAIN_LIGHT_SHADOWS_CASCADE
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
                float heightOffset = sin(_Time.y * _FlapSpeed) * _WingHeight * distance; // distance will be 0 at center!
                float3 newPositionOS = float3(IN.positionOS.x, IN.positionOS.y + heightOffset, IN.positionOS.z);
                OUT.positionHCS = TransformObjectToHClip(newPositionOS);
                
                return OUT;
            }

            half4 fragment(Varyings IN) : SV_Target
            {
                
                return _BaseColor; 
            }

            
            ENDHLSL
        }
    }
}
