#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant float &time [[buffer(1)]]) {
    VertexOut out;
    
    // Transform the position to create a swirling pattern
    float radius = length(in.position.xy);
    float angle = atan2(in.position.y, in.position.x) + time * 0.5;
    
    float2 newPos;
    newPos.x = radius * cos(angle);
    newPos.y = radius * sin(angle);
    
    out.position = float4(newPos, 0.0, 1.0);
    
    // Create a smooth gradient color based on time and position
    out.color = float4(0.5 + 0.5 * sin(in.position.x * 10.0 + time),
                       0.5 + 0.5 * sin(in.position.y * 10.0 + time),
                       0.5 + 0.5 * sin((in.position.x + in.position.y) * 5.0 + time), 1.0);
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color; // Output the color to the fragment
}
