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
            
            float3 repeat(float3 p, float3 c)
            {
                return fmod(p + 0.5 * c, c) - 0.5 * c;
            }
            
            float map(float3 p) // note how this is a float3 field
            {
                float3 rp = repeat(p, float3(4.,4.,4.)); // repeat every 4 units
                float sphere_0 = sphereSDF( rp , float3(0,1.,0.), 1.25 );
                float sphere_1 = sphereSDF( rp , float3(2.,0.,0.), 1.0 );
                float sphere_2 = sphereSDF( rp , float3(-2.,0.,0.), 1.0 );

                float minSphere = min(sphere_1, sphere_2);
                minSphere = min(minSphere, sphere_0);

                float plane_0 = p.y + 1.5; // y = -1.5 plane
                float planeDist = plane_0;

                return min(minSphere, planeDist);
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
                float travel = .01;
                float softnessFactor = 8.0; // softness
                const int MAX_SHADOW_STEPS = 128;

                for (int i = 0; i < MAX_SHADOW_STEPS; i++)
                {

                    if (travel >= maxDistance)
                    {
                        break; // reached light
                    }
                    
                    float3 currentPosition = shadowRayOrigin + travel * directionToLight;
                    float distanceToSurface = map(currentPosition);

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
                const int NUMBER_OF_STEPS = 512; // lower this to see sample artifacts
                const float MINIMUM_HIT_DISTANCE = .001;
                const float MAXIMUM_MARCH_DISTANCE = 1000.0;
                float3 lightPosition = float3(5. * sin(_Time.z),5.,-5); // lighting position, we define
                for (int i = 0; i < NUMBER_OF_STEPS; i++)
                {
                    float3 marchPosition = rayOrigin + rayTravel * rayDirection; // how far we are

                    // eval the distance field
                    float distanceToSurface = map(marchPosition);

                    // hit something
                    if (distanceToSurface < MINIMUM_HIT_DISTANCE)
                    {
                        float3 normalAtHit = calculateNormal(marchPosition); // calculate the normal for lighting
                        // simple shading based on normal
                        float3 lightDirection = normalize(lightPosition - marchPosition);
                        float lightDistance = length(lightPosition - marchPosition);

                        // begin to calculate a shadow based on origin point
                        float3 shadowRayOrigin = marchPosition + normalAtHit * MINIMUM_HIT_DISTANCE * 2.0; // moved forward so it doesn't automatically count
                        float shadow = softShadow(shadowRayOrigin, lightDirection, lightDistance); // x2 for safety but unnecessary

                        // Straightforward Normal dot light direction for diffuse color
                        float diffuse = max(dot(normalAtHit, lightDirection), 0.0);
                        float3 baseColor = float3(1.,0.,0.); // starting base color
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

                // Can return a background color... or black
                // simple gradient background
                float backgroundT = rayDirection.y /5.;
                float3 backgroundColor = lerp(float3(0.6, 0.8, 1.0), float3(1.0, 1.0, 1.0), backgroundT);
                return backgroundColor;;
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
