// NOTE: Shader automatically converted from Godot Engine 4.0.beta8.mono's ORMMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D splatMap_0 : filter_linear_mipmap;
uniform sampler2D splatMap_1 : filter_linear_mipmap;

uniform sampler2DArray textures_albedo : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2DArray textures_ormh : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2DArray textures_normal : hint_normal, filter_linear_mipmap, repeat_enable;

uniform vec4 albedo : source_color;
uniform float normal_scale : hint_range(-16,16);
uniform float ao_light_affect;

uniform vec4 heightmap_scale;
uniform int heightmap_min_layers;
uniform int heightmap_max_layers;
uniform vec2 heightmap_flip;
uniform vec2 uv1_scale;
uniform vec2 uv1_offset;

//https://github.com/Zylann/godot_heightmap_plugin/blob/master/addons/zylann.hterrain/shaders/simple4.shader
// Blends weights according to the bump of detail textures,
// so for example it allows to have sand fill the gaps between pebbles
vec4 get_depth_blended_weights(vec4 splat, vec4 bumps) {
	float dh = 0.2;

	vec4 h = bumps + splat;

	// TODO Keep improving multilayer blending, there are still some edge cases...
	// Mitigation: nullify layers with near-zero splat
	h *= smoothstep(0, 0.05, splat);

	vec4 d = h + dh;
	d.r -= max(h.g, max(h.b, h.a));
	d.g -= max(h.r, max(h.b, h.a));
	d.b -= max(h.g, max(h.r, h.a));
	d.a -= max(h.g, max(h.b, h.r));

	return clamp(d, 0, 1);
}

vec4 textureBlend(vec4 vcol, vec2 uv, vec4 blendMask, sampler2DArray texs, float offset)
{
	float colK = (-vcol.r+1.) * (-vcol.g+1.) * (-vcol.b+1.);
	vec4 blend = vec4(colK, vcol.r, vcol.g, vcol.b);
	
	vec4 w = get_depth_blended_weights(blend, blendMask);
	float w_sum = (w.r + w.g + w.b + w.a);
	
	float off = offset * 4.;
	vec4 texK = texture(texs, vec3(uv, 0. + off));
	vec4 texR = texture(texs, vec3(uv, 1. + off));
	vec4 texG = texture(texs, vec3(uv, 2. + off));
	vec4 texB = texture(texs, vec3(uv, 3. + off));

	return vec4((
		w.x * texK +
		w.y * texR +
		w.z * texG +
		w.a * texB)/w_sum
		);
}

float valueBlend(vec4 vcol, vec4 blendMask, vec4 vals)
{
	float colK = (-vcol.r+1.) * (-vcol.g+1.) * (-vcol.b+1.);
	vec4 blend = vec4(colK, vcol.r, vcol.g, vcol.b);
	
	vec4 w = get_depth_blended_weights(blend, blendMask);
	float w_sum = (w.r + w.g + w.b + w.a);
	
	float texK = vals.x;
	float texR = vals.y;
	float texG = vals.z;
	float texB = vals.a;

	return float((
		w.x * texK +
		w.y * texR +
		w.z * texG +
		w.a * texB)/w_sum
		);
}

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	vec4 splat0 = texture(splatMap_0, UV2);
	vec4 splat1 = texture(splatMap_1, UV2);
	
	vec4 blendMask = vec4(
		texture(textures_ormh, vec3(UV, 0)).a,
		texture(textures_ormh, vec3(UV, 1)).a,
		texture(textures_ormh, vec3(UV, 2)).a,
		texture(textures_ormh, vec3(UV, 3)).a
		);

	vec4 blendMask1 = vec4(
		texture(textures_ormh, vec3(UV, 4)).a,
		texture(textures_ormh, vec3(UV, 5)).a,
		texture(textures_ormh, vec3(UV, 6)).a,
		texture(textures_ormh, vec3(UV, 7)).a
		);

	vec2 base_uv = UV;
	{
		vec3 view_dir = normalize(normalize(-VERTEX)*mat3(TANGENT*heightmap_flip.x,-BINORMAL*heightmap_flip.y,NORMAL));
		float depth = 1.0 - valueBlend(COLOR, blendMask, vec4(blendMask.x*heightmap_scale.x, blendMask.y*heightmap_scale.y, blendMask.z*heightmap_scale.z, blendMask.a*heightmap_scale.a));
		vec2 ofs = base_uv - view_dir.xy * depth * 0.01;
		base_uv=ofs;
	}
	/*{   // Added texture blending to built in parallax, it's low, possible to optimize?
	
		vec3 view_dir = normalize(normalize(-VERTEX)*mat3(TANGENT*heightmap_flip.x,-BINORMAL*heightmap_flip.y,NORMAL));
		float num_layers = mix(float(heightmap_max_layers),float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
		float layer_depth = 1.0 / num_layers;
		float current_layer_depth = 0.0;
		vec2 P = view_dir.xy * heightmap_scale.x * 0.01;
		vec2 delta = P / num_layers;
		vec2 ofs = base_uv;
		float depth = 1.0 - textureBlend(COLOR, ofs, blendMask, textures_ormh).a;
		float current_depth = 0.0;
		while(current_depth < depth) {
			ofs -= delta;
			depth = 1.0 - textureBlend(COLOR, ofs, blendMask, textures_ormh).a;
			current_depth += layer_depth;
		}
		vec2 prev_ofs = ofs + delta;
		float after_depth  = depth - current_depth;
		float before_depth = ( 1.0 -textureBlend(COLOR, prev_ofs, blendMask, textures_ormh).a  ) - current_depth + layer_depth;
		float weight = after_depth / (after_depth - before_depth);
		ofs = mix(ofs,prev_ofs,weight);
		base_uv=ofs;
	}*/
	
	ALBEDO = textureBlend(splat0, base_uv, blendMask, textures_albedo, 0).rgb;
	ALBEDO = mix(ALBEDO, textureBlend(splat1, base_uv, blendMask1, textures_albedo, 1).rgb, splat1.a);
	vec4 orm_tex = textureBlend(COLOR, base_uv, blendMask, textures_ormh, 0);
	orm_tex = mix(orm_tex, textureBlend(splat1, base_uv, blendMask1, textures_ormh, 1), splat1.a);
	ROUGHNESS = orm_tex.g;
	METALLIC = orm_tex.b;
	NORMAL_MAP = textureBlend(COLOR, base_uv, blendMask, textures_normal, 0).rgb;
	NORMAL_MAP = mix(NORMAL_MAP, textureBlend(splat1, base_uv, blendMask1, textures_normal, 1).rgb, splat1.a);
	NORMAL_MAP_DEPTH = normal_scale;
	AO = orm_tex.r;
	AO_LIGHT_AFFECT = ao_light_affect;
}
