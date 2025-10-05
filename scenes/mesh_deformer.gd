@tool
extends MeshInstance3D

@export var reload := false : 
	set(new_reload):
		reload = new_reload
		if new_reload:
			regenerate_mesh()
			reload = false

@export_range(1, 32) var subdivision := 1 :
	set(new_subdivisions):
		subdivision = new_subdivisions
		regenerate_mesh()  

var array_mesh: ArrayMesh
var original_vertices: PackedVector3Array
var original_normals: PackedVector3Array 

func _ready() -> void: 
	regenerate_mesh()

func regenerate_mesh() -> void:
	if !array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh
	
	array_mesh.clear_surfaces()
	var surface_array := create_sphere(subdivision)
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	original_vertices = surface_array[Mesh.ARRAY_VERTEX].duplicate()
	original_normals = surface_array[Mesh.ARRAY_NORMAL].duplicate()


func deform_on_impact ( impact_point: Vector3, impact_force:  float ) -> void:
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	print("Se empezo a deformar!")
	var current_surface_arrays = array_mesh.surface_get_arrays(0)
	var current_vertices = current_surface_arrays[Mesh.ARRAY_VERTEX].duplicate()
	var current_normals = current_surface_arrays[Mesh.ARRAY_NORMAL].duplicate()
	var current_uvs = current_surface_arrays[Mesh.ARRAY_TEX_UV] if current_surface_arrays[Mesh.ARRAY_TEX_UV] else PackedVector2Array()
	
	var deformation_radius = 0.9
	var max_deformation = 0.5 * impact_force

	for i in range(current_vertices.size()):
		var original_vertex_global_pos = to_global(original_vertices[i])
		var distance = original_vertex_global_pos.distance_to(impact_point)
		
		var deformed_vertex = current_vertices[i]
		var deformed_normal = current_normals[i] 

		if distance < deformation_radius:
			var deform_factor = (deformation_radius - distance) / deformation_radius
			var deform_amount = max_deformation * deform_factor
			
			var normal_direction = to_global(original_normals[i]).normalized()
			
			deformed_vertex -= to_local(normal_direction) * deform_amount
			
			# Opcional: Recalcular la normal para este vértice si la deformación es muy pronunciada
			# Esto es más complejo y puede ser costoso, pero mejora la iluminación si la forma cambia mucho.
			# Por ahora, dejaremos las normales sin modificar para simplificar,
			# a menos que sea un problema visible.

		st.set_normal(deformed_normal)
		if current_uvs.size() > i:
			st.set_uv(current_uvs[i])
		st.add_vertex(deformed_vertex)

	var indices = current_surface_arrays[Mesh.ARRAY_INDEX]
	for idx in indices:
		st.add_index(idx)

	array_mesh.clear_surfaces()
	st.commit(array_mesh)

func calculate_new_normals(verts):
	return PackedVector3Array()

func create_sphere(subdiv: int) -> Array:
	var surface_array := create_cube(subdiv)
	for i: int in surface_array[Mesh.ARRAY_VERTEX].size():
		var vertex: Vector3 = surface_array[Mesh.ARRAY_VERTEX][i]
		surface_array[Mesh.ARRAY_VERTEX][i]=vertex.normalized() / 2.0
		surface_array[Mesh.ARRAY_NORMAL][i]=vertex.normalized()
	return surface_array

func create_cube(subdiv: int) -> Array:
	var surface_array: Array = []
	surface_array.resize(mesh.ARRAY_MAX)
	
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	const directions: PackedVector3Array =[
		Vector3.UP,  Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK
	]
	
	for x: int in directions.size():
		var index := 4 * x * subdiv * subdiv
		var plane := create_plane(subdiv, index, directions[x], directions[x] / 2.0)
		positions.append_array(plane[Mesh.ARRAY_VERTEX])
		normals.append_array(plane[Mesh.ARRAY_NORMAL])
		indices.append_array(plane[Mesh.ARRAY_INDEX])
	
	surface_array[mesh.ARRAY_VERTEX]= positions
	surface_array[mesh.ARRAY_NORMAL]= normals
	surface_array[mesh.ARRAY_INDEX] = indices
	
	return surface_array

func create_plane(subdiv: int, index: int, direction : Vector3, center: Vector3) -> Array:
	var surface_array: Array = []
	surface_array.resize(mesh.ARRAY_MAX)
	
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	direction = direction.normalized()
	var binormal := Vector3(direction.z, direction.x, direction.y) / subdiv
	var tangent := binormal.rotated(direction, PI / 2.0)  
	var offset := -subdiv * (binormal + tangent) / 2.0 + center 

	for x: int in subdiv:
		for y: int in subdiv:
			var vertex_offset  := binormal * x + tangent * y + offset  
			var index_offset := 4 * (x * subdiv + y) + index
			
			positions.append_array([ 
				vertex_offset, 
				vertex_offset + tangent, 
				vertex_offset + tangent + binormal, 
				vertex_offset + binormal 
			])
			
			normals.append_array([ 
				direction, 
				direction, 
				direction, 
				direction
			])
			
			indices.append_array( [ 
				index_offset, index_offset + 1, index_offset + 2, 
				index_offset , index_offset + 2, index_offset + 3 
			])
	
	surface_array[mesh.ARRAY_VERTEX]= positions
	surface_array[mesh.ARRAY_NORMAL]= normals
	surface_array[mesh.ARRAY_INDEX] = indices
	
	return surface_array
