#if (__VERSION__ > 120)
# define IN in
# define OUT out
#else
# define IN attribute
# define OUT varying
#endif // __VERSION
precision mediump float;
IN vec4 vPosition;
uniform float scale;
uniform float frame_aspect_ratio;

uniform mat4 unif_matrix;
uniform mat4 unif_matrix_1;
uniform sampler2D cam0_texture;
uniform sampler2D cam1_texture;
uniform float pixel_size;
uniform float cam_aspect_ratio;
//options start
uniform float sharpness_gain;
uniform float cam0_offset_yaw;
uniform float cam0_offset_x;
uniform float cam0_offset_y;
uniform float cam0_horizon_r;
uniform float cam0_aov;
//options end

const float M_PI = 3.1415926535;

OUT float r0;
OUT float r1;
OUT float u0;
OUT float v0;
OUT float u1;
OUT float v1;

void main(void) {
	vec4 position = vPosition;
	gl_Position = vec4(vPosition.x / vPosition.z * scale, vPosition.y / vPosition.z * scale * frame_aspect_ratio, 1.0, 1.0);

	{
		vec4 pos = unif_matrix * position;
		float pitch = asin(pos.y);
		float yaw = atan(pos.x, pos.z);

		r0 = (M_PI / 2.0 - pitch) / M_PI;
		float r2 = r0;
		r2 = sin(M_PI * 180.0 / cam0_aov * r2) / 2.0;
		float yaw2 = yaw + M_PI + cam0_offset_yaw;
		u0 = cam0_horizon_r / cam_aspect_ratio * r2 * cos(yaw2) + 0.5 + cam0_offset_x;
		v0 = cam0_horizon_r * r2 * sin(yaw2) + 0.5 + cam0_offset_y;
	}
	{
		vec4 pos = unif_matrix_1 * position;
		u1 = pos.x / -pos.y * 0.35 + 0.5;
		v1 = pos.z / -pos.y * 0.35 + 0.5;
	}
}
