Shader "Custom/HWShader01"
{
    Properties
    {
        // You can still comment in these
        // these must be one line declarations
        // [Attribute] _PropertyName("Display Name", Type) = DefaultValue
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _Target ("TargetPosition", Vector) = (0,0,0,0)
        _Intensity ("Intensity", Float) = 1
        _NoiseOffset("Noise Offset", Float) = 1
        _NoiseStrength("Noise Strength", Float) = 1
    }

    SubShader
    {
        // Tags identify the shader purpose and where and when it should run
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        // Run once per object
        Pass
        {
            // Inside here is entirely HLSL Code
            HLSLPROGRAM

            // pragma to define the vertex and fragment functions
            #pragma vertex vert 
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _Target;
                float _Intensity;
                float _NoiseOffset;
                float _NoiseStrength;
            CBUFFER_END
            
            // This comes from outside of the shader
            struct Attributes
            {
                // Position object space positionOS
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };
            
            // This is calculated in the shader
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            // You might see something called appdata (now Attributes) in built in shaders
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = mul(unity_ObjectToWorld, IN.positionOS).xyz;
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

         //https://thebookofshaders.com/11/ 
         // 2D Random
float random (float2 st) {
    return frac(sin(dot(st,
                         float2(12.9898,78.233)))
                 * 43758.5453123);
} 
            half4 frag(Varyings IN) : SV_Target
            { 
               
                float3 Normal = normalize(IN.worldNormal);
                Light mainLight = GetMainLight();
                float3 LightDirection = GetMainLight().direction;
 float noise = random(IN.worldPos.xz + float2(_NoiseOffset,_NoiseOffset));
                float NdotL = max(0, dot(Normal, LightDirection) ) + (noise - 0.5) * _NoiseStrength;
 
                half3 combinedLight = _BaseColor + mainLight.color.rgb * NdotL;
                return half4(combinedLight,1);
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
}
