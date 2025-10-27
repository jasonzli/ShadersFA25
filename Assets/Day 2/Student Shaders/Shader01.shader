Shader "Custom/Shader01"
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
        _Scale("Scale", Float) = 10
        _Speed("Speed", Float) = 1
    }

    SubShader
    {
        // Tags identify the shader purpose and where and when it should run, these are required for URP
        Tags {
            "RenderType" = "Opaque" // Shader sequencing (sort of)
            "RenderPipeline" = "UniversalPipeline" //shader is targeted for URP
            "LightMode" = "UniversalForward"
        }

        // Run once per object
        Pass
        {
            // Inside here is entirely HLSL Code
            HLSLPROGRAM

            // Preprocessor directives to define the vertex and fragment functions
            #pragma vertex vert 
            #pragma fragment frag

            // Multi compile directives to enbable lighting and shadow functions within URP
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            // Preprocessor directions to include additional libraries. These basically copy and paste code from the files here
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Properties used for the shader. Notice that they match the ones in the Properties block above
            // They *must* be declared here again to be used in the shader code
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            half4 _BaseColor;
            float4 _BaseMap_ST;
            float4 _Target;
            float _Intensity;
            float _Scale;
            float _Speed;
            
            // This comes from outside of the shader
            // The allcaps term after the : is called a SEMANTIC, which tells the GPU what variables to put into the shader
            struct Attributes
            {
                // Position object space positionOS
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            // This is calculated in the shader's vertex function and passed to the fragment function
            // The term varyings is used because they vary per pixel and also change between the vertex and fragment stages
            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // This is a unique semantic for the final vertex position in Homogeneous Clip Space
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            // You might see something called appdata (now Attributes) in built in shaders
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); //transform the vertex's object space position to homogeneous clip space (screen)
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz); // transform the vertex's object space position to world space
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS); // transform the vertex's object space normal to world space

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap); // transform the uv based on tiling and offset values
                return OUT; //return an instance of the Varyings struct
            }

            float2 randomGradient(float2 p, float time)
            {
                p += 0.01;
                float x = dot(p, float2(123.4, 234.5));
                float y = dot(p, float2(234.5, 345.6));
                float2 g = float2(x, y);
                g = sin(g) * 43758.5453;
                g = sin(g + time);
                return g;
            }

            // You might see something called v2f (now varyings) in built in shaders
            half4 frag(Varyings IN) : SV_Target //note that this *function* has a SV_Target semantic, meaning it is the final output color of the pixel
            {

                float2 st = IN.uv * _Scale;
                float2 stID = floor(st);
                float2 stUV = frac(st);

                float2 bl = stID;
                float2 br = stID + float2(1, 0);
                float2 tl = stID + float2(0, 1);
                float2 tr = stID + float2(1, 1);

                // gradients
                float2 blg = randomGradient(bl, _Time.y * _Speed);
                float2 brg = randomGradient(br, _Time.y * _Speed);
                float2 tlg = randomGradient(tl, _Time.y * _Speed);
                float2 trg = randomGradient(tr, _Time.y * _Speed);

                // distance vectors
                float2 blDist = stUV - float2(0, 0);
                float2 brDist = stUV - float2(1, 0);
                float2 tlDist = stUV - float2(0, 1);
                float2 trDist = stUV - float2(1, 1);

                // dot products
                float bldot = dot(blg, blDist);
                float brdot = dot(brg, brDist);
                float tldot = dot(tlg, tlDist);
                float trdot = dot(trg, trDist);

                // smooth interpolation
                stUV = smoothstep(0.0, 1.0, stUV);
                float b = lerp(bldot, brdot, stUV.x);
                float t = lerp(tldot, trdot, stUV.x);
                float perlin = lerp(b, t, stUV.y);

                // billow noise effect
                float billow = abs(perlin);

                float distance = 1.-length(IN.worldPos - _Target.xyz);
                half4 col = _BaseColor * (distance+ _Intensity); 
             
                float3 LightDirection = GetMainLight().direction;
                float3 Normal = normalize(IN.worldNormal);
                float NdotL = saturate(dot(Normal, LightDirection)); 

                float3 brightColor = _BaseColor.rgb * sin(_Time/1000) * 2;
                float3 darkColor = float3(IN.worldPos.x, IN.worldPos.y, IN.worldPos.z);
                float3 finalColor = lerp(darkColor, brightColor, NdotL);

                float mlShadowAttenuation = MainLightRealtimeShadow(TransformWorldToShadowCoord(IN.worldPos)); 
                float3 litColor = GetMainLight().color.rgb * NdotL * mlShadowAttenuation * billow -.1 * finalColor;

                return half4(litColor.rgb * sin(_Time * sin(billow/50)),1);
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
