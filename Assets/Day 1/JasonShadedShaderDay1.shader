Shader "Custom/JasonShadedShaderDay1"
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
            #pragma shader_feature _FORWARD_PLUS

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
            
            // This comes from outside of the shader
            // The allcaps term after the : is called a SEMANTIC, which tells the GPU what variables to put into the shader
            struct Attributes
            {
                // Position object space positionOS
                float4 positionOS : POSITION; // these semantics come from convention, and are passed from the object data
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

                           // displacement function (matches original logic)
                float3 CalcOffset(float3 p)
                {
                    float3 direction = float3(0,0,0) - p;
                    float3 normalizeDirection = normalize(direction);
                    float3 offsetIntensity = normalizeDirection * 0.2 * sin(10.0 * abs(p.y));
                    return offsetIntensity * _SinTime.z;
                }
            // You might see something called appdata (now Attributes) in built in shaders
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 position = IN.positionOS.xyz;
                OUT.positionHCS = TransformObjectToHClip(position); //transform the vertex's object space position to homogeneous clip space (screen)
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz); // transform the vertex's object space position to world space
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS); // transform the vertex's object space normal to world space

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap); // transform the uv based on tiling and offset values
                return OUT; //return an instance of the Varyings struct
            }

            // You might see something called v2f (now varyings) in built in shaders
            half4 frag(Varyings IN) : SV_Target //note that this *function* has a SV_Target semantic, meaning it is the final output color of the pixel
            {
                // Example HLSL shading example
                // Calculate distance from world position to target position
                float distance = 1.-length(IN.worldPos - _Target.xyz);
                half4 col = _BaseColor * (distance+ _Intensity); // modulate base color by distance and intensity
                // this above code is not used in the final color at the moment.

                //This is basic Lambertian diffuse shading https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/diffuse-lambertian-shading.html
                float3 LightDirection = GetMainLight().direction;
                float3 Normal = normalize(IN.worldNormal);
                float NdotL = saturate(dot(Normal, LightDirection)); // Dot product is a Vector projection clamped between 0 and 1
                float mlShadowAttenuation = MainLightRealtimeShadow(TransformWorldToShadowCoord(IN.worldPos)); // get the shadow attenuation from the Unity function using a shadow map
                float3 litColor = GetMainLight().color.rgb * NdotL * mlShadowAttenuation; // multiplies the light according to Lambertian diffuse model

                // Output the final color
                // You will notice some artifacts on a circle with default lighting settings. These are "shadow acne" that require fixing in bias settings
                return half4(litColor.rgb,1);
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
 