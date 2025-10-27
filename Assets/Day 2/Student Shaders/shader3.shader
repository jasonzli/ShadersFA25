Shader "Custom/shader3"
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
        _Scale ("Scale", Float) = 10.
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

            // You might see something called v2f (now varyings) in built in shaders
            half4 frag(Varyings IN) : SV_Target //note that this *function* has a SV_Target semantic, meaning it is the final output color of the pixel
            {
                // Example HLSL shading example
                // Calculate distance from world position to target position
                float worldDist = distance(IN.worldPos, _Target.xyz);
                // this above code is not used in the final color at the moment.

                float d = distance(float2(.2, .5), IN.uv);
                float d2 = distance(float2(.8, .3), IN.uv);

                float scaleD = _Scale * d;
                float scaleD2 = _Scale * d2;

                float fractD = frac(scaleD);
                float fractD2 = frac(scaleD2);

                float move = cos(_Time.y * 9.) + .5;
                float sinD = sin(fractD * 3.14 + move/2.);
                float sinD2 = sin(fractD2 * 3.14 + move/2.);

                // float3 shape1 = float3(sinD);
                // float3 shape2 = float3(sinD2);
                float3 final = sinD + sinD2;

                return half4(final, 1.);
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
 