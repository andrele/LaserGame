#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
uniform vec2 texOffset;

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
	vec4 color = texture2D(texture, texOffset);
	int i, j;
	vec4 sum = vec4(0);
	for (i = -2; i<=2; i++) {
		for (j = -2; j <= 2; j++) {
			vec2 offset = vec2(i, j) * 0.005;
			sum += texture2D(texture, texOffset + offset);			
		}
	}

	gl_FragColor = vertColor;
}