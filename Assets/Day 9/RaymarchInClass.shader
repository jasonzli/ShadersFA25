Shader "Custom/RaymarchInClass"
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

            // Smooth Union operation for SDFs https://iquilezles.org/articles/distfunctions/
            float opSmoothUnion( float d1, float d2, float k )
            {
                k *= 4.0;
                float h = max(k-abs(d1-d2),0.0);
                return min(d1, d2) - h*h*0.25/k;
            }
            
            float sphereSDF(float3 p, float3 center, float radius)
            {
                return length(p - center) - radius;
            }
                        
            float3 repeat(float3 p, float3 c)
            {
                float3 cell = floor(p / c + .5);
                return p - c * cell;
            }

            float scene(float3 p)
            {
                float3 cell = float3(6,6,12);
                float3 rp = repeat(p, cell);
                float sphere_0 = sphereSDF(rp, float3(2 * cos(_Time.z),0,0), 1.0);
                float sphere_1 = sphereSDF(rp, float3(-2,0,0), 1.0);
                float sphere_2 = sphereSDF(rp, float3(0,2,0), 1.0);
                float plane = p.y + 1.5;

                float sphereMin = opSmoothUnion(sphere_0, opSmoothUnion(sphere_1, sphere_2, .4),.5);
                float sceneDist = min(sphereMin, plane);
                return sceneDist;
            }

            float3 calculateNormal(float3 p)
            {
                const float3 epsilon = float3(.0001,0.,0.);
                float xGradient = scene(p + epsilon.xyy) - scene(p - epsilon.xyy);
                float yGradient = scene(p + epsilon.yxy) - scene(p - epsilon.yxy);
                float zGradient = scene(p + epsilon.yyx) - scene(p - epsilon.yyx);

                float3 normal = normalize(float3(xGradient, yGradient, zGradient));
                // check if normal has length of 0
                if (length(normal) == 0.0)
                {
                    return float3(0.,0.,0.);
                }
                return normalize(normal);
            }

            float3 raymarch(float3 rayOrigin, float3 rayDirection)
            {
                const int MAX_STEPS = 256;
                const float SURFACE_DIST = 0.01;
                const float MAX_DIST = 200.0;

                float rayDistance = 0.0;

                float3 lightPosition = float3(5 * sin(_Time.z),5 ,-5* cos(_Time.z));
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 currentPosition = rayOrigin + rayDirection * rayDistance;
                    // SDF for the scene
                    float distanceToScene = scene(currentPosition);
                    if (distanceToScene < SURFACE_DIST)
                    {
                        // we've hit
                        float3 normal = calculateNormal(currentPosition);
                        float3 lightDirection = normalize(lightPosition - currentPosition);
                        float diffuse = max(.05,dot(normal,lightDirection));
                        // we will raymarch again to see if we are in shadow
                        float3 albedo = float3(.8,.2,.3);
                        return albedo * diffuse;
                    }

                    if (rayDistance > MAX_DIST) break;
                    
                    rayDistance += distanceToScene;
                }
                
                return lerp(float3(0.6,0.8,1.0), float3(0.0,0.0,0.2), rayDirection.y/4.);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv * 2.0 - 1.0;
                float fov = 60.0;
                float3 cameraPos = float3(0,0,-5);
                float3 rayDirection = normalize(float3(uv * tan(radians(fov)), 1.0));
                float3 color = raymarch(cameraPos, rayDirection);
                return float4(color,1);
            }
            ENDHLSL
        }
    }
}
