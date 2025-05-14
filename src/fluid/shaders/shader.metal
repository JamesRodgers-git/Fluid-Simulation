#include <metal_stdlib>
using namespace metal;

struct VertexInput
{
    float2 position [[attribute(0)]];
};

struct VertexOutput
{
    float4 position [[position]];
};

//vertex VertexOut vertexShader (VertexInput IN [[stage_in]])
//{
//    VertexOutput OUT;
//    OUT.position = float4(IN.position, 0.0, 1.0);
//    return OUT;
//}

vertex float4 vertexShader (uint vid [[vertex_id]])
{
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    return float4(positions[vid], 0.0, 1.0);
}

fragment float4 fragmentShader () //VertexOutput IN
{
    return float4(0.0, 1.0, 0.0, 1.0);
}
