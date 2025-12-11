Shader "Custom/Raymarch"
{
    Properties
    {
  
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


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float sphereSDF(float3 p, float3 center, float radius)
            {
                return length(p - center) - radius;
            }

            
            float map(float3 p) // note how this is a float3 field
            {
                float sphere_0 = sphereSDF( p , float3(0,1.,0.), 1.25 );
                float sphere_1 = sphereSDF( p , float3(2.,0.,0.), 1.0 );
                float sphere_2 = sphereSDF( p , float3(-2.,0.,0.), 1.0 );

                float minSphere = min(sphere_1, sphere_2);
                minSphere = min(minSphere, sphere_0);
                
                return minSphere;
            }
            
            float3 calculateNormal(float3 p)
            {
                const float3 epsilon = float3(.0001,0.,0.);
                float xGradient = map(p + epsilon.xyy) - map(p - epsilon.xyy);
                float yGradient = map(p + epsilon.yxy) - map(p - epsilon.yxy);
                float zGradient = map(p + epsilon.yyx) - map(p - epsilon.yyx);

                float3 normal = normalize(float3(xGradient, yGradient, zGradient));
                // check if normal has length of 0
                if (length(normal) == 0.0)
                {
                    return float3(0.,0.,0.);
                }
                return normalize(normal);
            }

            float softShadow(float3 shadowRayOrigin, float3 directionToLight, float maxDistance)
            {
                float shadow = 1.0;
                float travel = .0001;
                float softnessFactor = 8.0; // softness
                const int MAX_SHADOW_STEPS = 64;

                for (int i = 0; i < MAX_SHADOW_STEPS; i++)
                {

                    if (travel >= maxDistance)
                    {
                        break; // reached light
                    }
                    
                    float3 currentPosition = shadowRayOrigin + travel * directionToLight;
                    float distanceToSurface = map(currentPosition);
                    if (distanceToSurface < 0.0001) //this needs to be smaller than the minimum hit distance
                    {
                        return 0.0; // in shadow
                    }
                    // this is a shadow accumulation formula
                    shadow = min(shadow, softnessFactor * distanceToSurface / max(0.001, travel));
                    travel += distanceToSurface;
                    if (shadow < .001) return 0.0;
                }
                return saturate(shadow);
            }
            
            float3 raymarch(float3 rayOrigin, float3 rayDirection)
            {
                float rayTravel = 0.0;
                const int NUMBER_OF_STEPS = 128;
                const float MINIMUM_HIT_DISTANCE = .0001;
                const float MAXIMUM_MARCH_DISTANCE = 1000.0;
                for (int i = 0; i < NUMBER_OF_STEPS; i++)
                {
                    float3 marchPosition = rayOrigin + rayTravel * rayDirection; // how far we are

                    // eval the distance field
                    float distanceToSurface = map(marchPosition);

                    if (distanceToSurface < MINIMUM_HIT_DISTANCE)
                    {
                        // hit something
                        float3 normalAtHit = calculateNormal(marchPosition);
                        // simple shading based on normal
                        float3 lightPosition = float3(5. * sin(_Time.z),5.,-5);
                        float3 lightDirection = normalize(lightPosition - marchPosition);
                        float lightDistance = length(lightPosition - marchPosition);
                        float3 shadowRayOrigin = marchPosition + normalAtHit * MINIMUM_HIT_DISTANCE * 2.0;
                        float shadow = softShadow(shadowRayOrigin, lightDirection, lightDistance*2.0);
                        float diffuse = max(dot(normalAtHit, lightDirection), 0.0);
                        float3 baseColor = float3(1.,0.,0.);
                        float3 color = baseColor * diffuse * shadow + baseColor * 0.1; // lit color + ambient
                        return color;
                    }

                    if (distanceToSurface > MAXIMUM_MARCH_DISTANCE)
                    {
                        // went too far without hitting
                        break;
                    }

                    rayTravel += distanceToSurface;
                }
                return float3(0.,0.,0.);
            }
            
            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv * 2.0 - 1.0;
                float fov = 60.0;
                float3 cameraPosition = float3(0,0,-5);
                float3 rayDirection = normalize(float3(uv * tan(radians(fov)), 1.0)); // there are multiple versions of this ray direction calculation
                float3 color = raymarch(cameraPosition,rayDirection);
                
                return float4(color,1.);
            }
            ENDHLSL
        }
    }
}
