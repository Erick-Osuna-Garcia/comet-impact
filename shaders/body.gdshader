shader_type spatial;

// --- Emisión de luz ---
uniform float emit : hint_range(0, 16) = 0.0;

// --- Colores y biomas ---
uniform vec4 color_1 : source_color = vec4(0.0, 0.2, 0.7, 1.0);   // océanos
uniform float color_1_treshold : hint_range(0, 1) = 0.45;
uniform float color_1_roughness : hint_range(0, 1) = 0.1;
uniform bool color_1_emit = false;

uniform vec4 color_2 : source_color = vec4(0.95, 0.9, 0.6, 1.0);  // playas
uniform float color_2_treshold : hint_range(0, 1) = 0.5;

uniform vec4 color_3 : source_color = vec4(0.1, 0.5, 0.2, 1.0);   // bosques
uniform float color_3_treshold : hint_range(0, 1) = 0.65;

uniform vec4 color_4 : source_color = vec4(0.4, 0.3, 0.2, 1.0);   // montañas
uniform float color_4_treshold : hint_range(0, 1) = 0.8;

uniform vec4 color_5 : source_color = vec4(1.0, 1.0, 1.0, 1.0);   // nieve/polos
uniform float color_5_treshold : hint_range(0, 1) = 1.0;

// --- Configuración del ruido ---
uniform bool noise_gaseous = false; // Tierra sólida → false
uniform float noise_gaseous_speed : hint_range(0, 0.1) = 0.0025;
uniform float noise_scale : hint_range(1, 10) = 2.0; // más detalle
uniform sampler2D noise : hint_default_black;

// Posición del impacto
uniform vec3 impact_position = vec3(0.0, 0.0, 0.0);
uniform float impact_radius : hint_range(0.0, 5.0) = 24.5;
uniform float impact_strength : hint_range(0.0, 1.0) = 1.0;

varying vec3 triplanar_power_normal;
varying vec3 triplanar_pos;
varying vec3 world_pos;

const float triplanar_sharpness = 0.5;

// --- Funciones auxiliares ---
vec2 rotate_position(vec2 position) {
	if (noise_gaseous) {
		position = mod(position + TIME * 2.5 * noise_gaseous_speed / 10.0, 0.0);
	}
	return position;
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, rotate_position(p_triplanar_pos.xy)) * p_weights.z;
	samp += texture(p_sampler, rotate_position(p_triplanar_pos.xz)) * p_weights.y;
	samp += texture(p_sampler, rotate_position(p_triplanar_pos.zy * vec2(-1.0, 1.0))) * p_weights.x;
	return samp;
}

// --- Vertex ---
void vertex() {
	triplanar_power_normal = pow(abs(NORMAL), vec3(triplanar_sharpness));
	triplanar_power_normal /= dot(triplanar_power_normal, vec3(1.0));
	triplanar_pos = VERTEX * vec3(noise_scale, noise_scale, noise_scale);
	triplanar_pos *= vec3(1.0, -1.0, 1.0);

	// Posición mundial
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// 🔥 Deformación del terreno por impacto
	float dist = distance(world_pos, impact_position);
	if (dist < impact_radius) {
		float falloff = 1.0 - (dist / impact_radius);
		VERTEX -= NORMAL * falloff * impact_strength * 0.3;
	}
}

// --- Fragment ---
void fragment() {
	vec3 triplanar_pos_clone = triplanar_pos;
	if (noise_gaseous) {
		triplanar_pos_clone = vec3(triplanar_pos.x * sin(0.1), triplanar_pos.y, triplanar_pos.z * sin(0.1));
	}

	vec4 color = triplanar_texture(noise, triplanar_power_normal, triplanar_pos_clone);
	float roughness = 0.0;

	float d = max(max(color.r, color.g), color.b);

	// Color quemado en el cráter
	float dist = distance(world_pos, impact_position);
	if (dist < impact_radius) {
		color = mix(color, vec4(0.2, 0.2, 0.2, 1.0), impact_strength);
	}

	if (d < color_1_treshold) {
		color = color_1;
		roughness = color_1_roughness;
		if (color_1_emit) {
			EMISSION = color_1.rgb;
		}
	}
	else if (d < color_2_treshold) {
		color = color_2;
	}
	else if (d < color_3_treshold) {
		color = color_3;
	}
	else if (d < color_4_treshold) {
		color = color_4;
	}
	else if (d < color_5_treshold) {
		color = color_5;
	}

	if (bool(emit)) {
		EMISSION = color.rgb * emit;
	}

	ALBEDO = color.rgb;
	ROUGHNESS = roughness;
}
