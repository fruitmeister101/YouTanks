@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeVoronoiNoise3D

# https://docs.godotengine.org/en/stable/tutorials/plugins/editor/visual_shader_plugins.html
# https://en.wikipedia.org/wiki/Worley_noise

func _get_name() -> String:
	return "VoronoiNoise3D"
	
func _get_category():
	return "NoiseLib"

func _get_description():
	return "3D voronoi/worley aka cellular noise"

func _init():
	set_input_port_default_value(0, Vector3.ZERO) # UVW
	set_input_port_default_value(1, Vector3.ZERO) # Offset
	set_input_port_default_value(2, Vector3.ONE * 10) # Scale
	set_input_port_default_value(3, 1.) # Distance scale
	set_input_port_default_value(4, 0) # Distance func
	set_input_port_default_value(5, 1.)
	set_input_port_default_value(6, false)

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_SCALAR
	
func _get_input_port_count():
	return 7

func _get_input_port_name(port):
	match port:
		0: return "uvw"
		1: return "offset"
		2: return "scale"
		3: return "distance scale"
		4: return "distance function"
		5: return "jitter"
		6: return "3d"

func _get_input_port_type(port):
	match port:
		0: return VisualShaderNode.PORT_TYPE_VECTOR_3D
		1: return VisualShaderNode.PORT_TYPE_VECTOR_3D
		2: return VisualShaderNode.PORT_TYPE_VECTOR_3D
		3: return VisualShaderNode.PORT_TYPE_SCALAR
		4: return VisualShaderNode.PORT_TYPE_SCALAR_INT
		5: return VisualShaderNode.PORT_TYPE_SCALAR
		6: return VisualShaderNode.PORT_TYPE_BOOLEAN

func _get_output_port_count():
	return 3

func _get_output_port_name(port):
	match port:
		0: return "cell value"
		1: return "distance"
		2: return "distance2"

func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_SCALAR

func _get_global_code(mode):
	return """
	vec3 voronoi_noise_hash_noise_range( vec3 p ) {
		p *= mat3(vec3(-4252.151, 3441.637, -1331.937), vec3(7569.135, -134.389, 5377.171754), vec3(-3301.746, 247.317, 2715.364));
		vec3 result = fract(fract(p)*6753.7245) -1.;
		return 2.0 * fract(vec3((result.x + result.y + result.z) / 3.) * vec3(15714.5427, 7541.5254, 54224.7245)) -1.;
	}
	
	// Returns (value, dist, dist2)
	vec3 voronoi_noise_sample( vec3 uvw, vec3 offset, vec3 scale, float distanceScale, int distanceFunc, float jitter, bool is3d ) {
vec3 scaleUV = uvw * scale + offset;
if(!is3d) {
	scaleUV = vec3(scaleUV.xy, 0.);
}
vec3 remainder = mod(scaleUV, 1.0);
vec3 roundUV = floor(scaleUV);

int expand = 2;
float minFound = 999.;
float found2 = 1.; // Second closest value found
float cellValue = 0.; // Celluar value, random for each position, but consistent.
for(int x = -expand; x < expand*2; x++) {
	for(int y = -expand; y < expand*2; y++) {
		for(int z = (!is3d ? 0 : -expand); z < (!is3d ? 1 : expand*2); z++) {
			vec3 offset = vec3(float(x), float(y), float(z));
			vec3 testUV = floor(scaleUV + offset);
			
			vec3 possibleCellValue = (voronoi_noise_hash_noise_range(vec3(testUV)) * jitter);
			vec3 distTarget = possibleCellValue + offset;
			if (!is3d) {
				distTarget = vec3(distTarget.xy, 0.);
			}
			float dist = 1.;
			vec3 diff = distTarget - remainder;
			switch(distanceFunc) {
				case 0: // Comparisons between squared and rooted are the same, it's cheaper to calculate with squared
				case 1:
					vec3 distV = vec3(pow(distTarget.x - remainder.x, 2.), pow(distTarget.y - remainder.y, 2.), pow(distTarget.z - remainder.z, 2.));
					dist = distV.x + distV.y + distV.z;
				break;
				case 2: dist = abs(remainder.x - distTarget.x) + abs(remainder.y - distTarget.y) + abs(remainder.z - distTarget.z); // Manhattan
				break;
				case 3:
					vec3 distV = vec3(pow(distTarget.x - remainder.x, 2.), pow(distTarget.y - remainder.y, 2.), pow(distTarget.z - remainder.z, 2.));
					float distSquared = distV.x + distV.y + distV.z;
					
					float distManhattanSquared = pow(abs(remainder.x - distTarget.x) + abs(remainder.y - distTarget.y) + abs(remainder.z - distTarget.z), 2.);
					dist = (distSquared + distManhattanSquared) / 2.; // Hybrid
				break;
			}
			dist *= distanceScale;
			// float dist = distance(remainder, distTarget);
			if(dist < minFound) {
				found2 = minFound;
				minFound = dist;
				cellValue = fract(possibleCellValue.x);
			}
			else if (dist < found2) {
				found2 = dist;
			}
		}
	}
}

if (distanceFunc == 0 || distanceFunc == 3) { // Euclidian or hybrid
	minFound = sqrt(minFound);
	found2 = sqrt(found2);
}

return vec3(cellValue, clamp(minFound, 0., 1.), clamp(found2, 0., 1.));
	}
	"""

func _get_code(input_vars, output_vars, mode, type):
	return """
		vec3 result = voronoi_noise_sample(%s, %s, %s, %s, %s, %s, %s);
		%s = result[0];
		%s = result[1];
		%s = result[2];
	""" % [input_vars[0], input_vars[1], input_vars[2], input_vars[3], input_vars[4], input_vars[5], input_vars[6],
			output_vars[0], output_vars[1], output_vars[2]]
	# return output_vars[0] + " = voronoi_noise_sample(%s, %s, %s, %s, %s);" % [input_vars[0], input_vars[1], input_vars[2], input_vars[3], input_vars[4]]
