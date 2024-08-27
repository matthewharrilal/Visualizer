#include <metal_stdlib>
using namespace metal;

#define AA 2
#define NUM_BALLS 6 // Ensure this is defined

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct MetaBall {
    float r;
    float2 pos;
    float3 col;
};

// Function to create a color palette
float3 palette(float d) {
    return mix(float3(0.2, 0.7, 0.9), float3(1.0, 0.0, 1.0), d);
}

// Function to rotate a 2D vector
float2 rotate(float2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return p * float2x2(c, s, -s, c);
}

// Function to map 3D points to fractal space with embedded metaballs
float map(float3 p, float time, thread MetaBall *balls) {
    for (int i = 0; i < 8; ++i) {
        float t = time * 0.2;
        p.xz = rotate(p.xz, t);
        p.xy = rotate(p.xy, t * 1.89);
        p.xz = abs(p.xz);
        p.xz -= 0.5;
    }
    
    float d = dot(sign(p), p) / 5.0;
    for (int i = 0; i < NUM_BALLS; i++) {
        float3 ballPos = float3(balls[i].pos, 0.0);
        float ballDist = length(p - ballPos) - balls[i].r;
        d = min(d, ballDist);
    }
    return d;
}

// Function to perform ray marching with embedded metaballs
float4 rayMarchFractal(float3 ro, float3 rd, float time, thread MetaBall* balls) {
    float t = 0.0;
    float3 col = float3(0.0);
    float d;
    for (int i = 0; i < 64; i++) {
        float3 p = ro + rd * t;
        d = map(p, time, balls) * 0.5;
        if (d < 0.02) {
            break;
        }
        if (d > 100.0) {
            break;
        }
        col += palette(length(p) * 0.1) / (400.0 * d);
        t += d;
    }
    return float4(col, 1.0 / (d * 100.0));
}

// Vertex function for standard full-screen quad
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

// Fragment function that combines fractal and metaballs into a unified effect
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant float &time [[buffer(0)]],
                              constant float2 &resolution [[buffer(1)]],
                              constant float *audioData [[buffer(2)]]) {
    float2 uv = (in.uv * resolution) / resolution.y;
    
    // Create the metaballs to be used in the fractal
    MetaBall balls[NUM_BALLS];
    for (int i = 0; i < NUM_BALLS; i++) {
        float angle = time * (0.4 + 0.1 * float(i));
        balls[i].pos = 0.5 * float2(sin(angle + float(i) * 2.0), cos(angle + float(i) * 2.0));
        balls[i].r = 0.25 + audioData[i] * 0.5; // React to audio data
        balls[i].col = palette(i * 0.1);
    }

    // Create the fractal pyramid effect with integrated metaballs
    float3 ro = float3(0.0, 0.0, -50.0);
    ro.xz = rotate(ro.xz, time);
    float3 cf = normalize(-ro);
    float3 cs = normalize(cross(cf, float3(0.0, 1.0, 0.0)));
    float3 cu = normalize(cross(cf, cs));
    float3 uuv = ro + cf * 3.0 + uv.x * cs + uv.y * cu;
    float3 rd = normalize(uuv - ro);

    // Perform ray marching and combine effects
    float4 color = rayMarchFractal(ro, rd, time, balls);

    return color;
}
