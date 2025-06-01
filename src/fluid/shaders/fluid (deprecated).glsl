@block fs_shared
layout(binding=1) uniform fs_params {
    vec2 yolo;
};

layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler tex_smp;
@end

@vs vs
layout(binding=0) uniform vs_params {
    vec2 yolo;
};

in vec4 position;
in vec2 uv;

out vec4 color;

void main ()
{
    gl_Position = position;
    gl_Position.x = yolo.r;
    color = color0;
}
@end

@fs fs
@include_block fs_shared

in vec4 color;

out vec4 frag_color;

void main ()
{
    frag_color = color + yolo.r;
    frag_color = texture(sampler2D(tex, tex_smp), vec2(0.0, 0.0));
}
@end

@fs fs2
@include_block fs_shared

in vec4 color;

out vec4 frag_color;

void main ()
{
    frag_color = color + yolo.r;
    frag_color = texture(sampler2D(tex, tex_smp), vec2(0.0, 0.0));
}
@end

@program fluid vs fs
@program blit vs fs2