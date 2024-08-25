#include <metal_stdlib>
using namespace metal;

#define AA 2
#define NUM_BALLS 6
#define GLOW_INTENSITY 0.07
#define LIGHT_SPEED 0.3

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct MetaBall {
    float r;
    float2 pos;
    float3 col;
};

float4 BallSDF(MetaBall ball, float2 uv) {
    float dst = ball.r / length(uv - ball.pos);
    return float4(ball.col * dst, dst);
}

float3 renderMetaBall(float2 uv, float time) {
    MetaBall balls[NUM_BALLS];

    // Initialize metaballs with dynamic properties
    for (int i = 0; i < NUM_BALLS; i++) {
        float angle = time * (0.5 + 0.1 * float(i));
        balls[i].pos = 0.5 * float2(sin(angle + float(i) * 2.0), cos(angle + float(i) * 2.0));
        balls[i].r = 0.3 + 0.1 * sin(time * 2.0 + float(i) * 3.0);
        balls[i].col = 0.5 + 0.5 * float3(
            sin(time + float(i) * 0.5),
            cos(time + float(i) * 0.5),
            sin(time + float(i) * 0.5 + 3.14)
        );
    }

    // Calculate color and distance for each metaball
    float3 color = float3(0.0);
    float totalDistance = 0.0;

    for (int i = 0; i < NUM_BALLS; i++) {
        float4 ball = BallSDF(balls[i], uv);
        color += ball.rgb;
        totalDistance += ball.a;
    }

    float threshold = totalDistance > 4.0 ? 1.0 : 0.0;
    color = mix(float3(0.0), color, threshold);

    return color;
}

float3 addLightEffects(float3 color, float2 uv, float time) {
    // Dynamic light sources that move around the scene
    float2 lightPos1 = 0.3 * float2(sin(time * LIGHT_SPEED), cos(time * LIGHT_SPEED));
    float2 lightPos2 = 0.3 * float2(cos(time * LIGHT_SPEED * 1.3), sin(time * LIGHT_SPEED * 1.5));

    // Calculate light influence
    float dist1 = length(uv - lightPos1);
    float dist2 = length(uv - lightPos2);

    // Add a glow effect around the light sources
    float glow1 = GLOW_INTENSITY / dist1;
    float glow2 = GLOW_INTENSITY / dist2;

    // Combine the light and glow effects
    color += float3(1.0, 0.8, 0.6) * glow1;
    color += float3(0.6, 0.8, 1.0) * glow2;

    // Slight pulse effect on the light color
    float pulse = 0.5 + 0.5 * sin(time * 2.0);
    color *= pulse;

    return color;
}

vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1, -1),
        float2( 1, -1),
        float2(-1,  1),
        float2( 1,  1)
    };
    
    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = positions[vertexID];
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant float &time [[buffer(0)]],
                              constant float2 &resolution [[buffer(1)]]) {
    float2 uv = (in.uv * resolution) / resolution.y;

    // Create a smooth gradient background that changes over time
    float3 backgroundColor = float3(0.5 + 0.5 * sin(time * 0.5), 0.5 + 0.5 * cos(time * 0.5), 1.0);
    
    float3 col = float3(0.);

    // Anti-aliasing and metaball rendering
    #if AA
        float uvs = 1. / max(resolution.x, resolution.y);
       
        for (int i = -AA; i < AA; ++i) {
            for (int j = -AA; j < AA; ++j) {
                col += renderMetaBall(uv + float2(i, j) * (uvs / float(AA)), time) / (4.0 * float(AA) * float(AA));
            }
        }
    #else
        col = renderMetaBall(uv, time);
    #endif
    
    // Add dynamic light and glow effects
    col = addLightEffects(col, uv, time);
    
    // Blend the metaballs with the dynamic gradient background
    float alpha = max(col.r, max(col.g, col.b));
    alpha = smoothstep(0.0, 1.0, alpha * 1.5);
    col = mix(backgroundColor, col, alpha);
    
    return float4(col, 1.0);
}
