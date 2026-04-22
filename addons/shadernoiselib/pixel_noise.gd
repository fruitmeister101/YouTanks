@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodePixelNoise3D

func _get_name() -> String:
	return "PixelNoise3D"
	
func _get_category():
	return "NoiseLib"

func _get_description():
	return "3D scalable pixel noise"

func _init():
	set_input_port_default_value(0, Vector3.ZERO) # UVW
	set_input_port_default_value(1, Vector3.ZERO) # Offset
	set_input_port_default_value(2, Vector3.ONE * 10) # Scale

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_SCALAR

func _get_input_port_count():
	return 3

func _get_input_port_name(port):
	match port:
		0: return "uvw"
		1: return "offset"
		2: return "scale"

func _get_input_port_type(port):
	match port:
		0: return VisualShaderNode.PORT_TYPE_VECTOR_3D
		1: return VisualShaderNode.PORT_TYPE_VECTOR_3D
		2: return VisualShaderNode.PORT_TYPE_VECTOR_3D

func _get_output_port_count():
	return 1

func _get_output_port_name(port):
	match port:
		0: return "noise"

func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_SCALAR

func _get_global_code(mode):
	return """
	vec3 pixel_noise_hash_noise_range( vec3 p ) {
		p *= mat3(vec3(-4252.151, 3441.637, -1331.937), vec3(7569.135, -134.389, 5377.171754), vec3(-3301.746, 247.317, 2715.364));
		vec3 result = fract(fract(p)*6753.7245) -1.;
		return 2.0 * fract(vec3((result.x + result.y + result.z) / 3.) * vec3(15714.5427, 7541.5254, 54224.7245)) -1.;
	}
	
	float pixel_noise_sample(vec3 uvw, vec3 scale) {
		uvw = floor(uvw * scale);
		vec3 vals = pixel_noise_hash_noise_range(uvw);
		return mod(vals.x, 1.);
	}
	"""

func _get_code(input_vars, output_vars, mode, type):
	return "%s = pixel_noise_sample(%s + %s, %s);" % [output_vars[0], input_vars[0], input_vars[1], input_vars[2]]
