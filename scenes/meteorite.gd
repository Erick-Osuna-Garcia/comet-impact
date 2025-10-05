extends RigidBody3D

@export var planet: Node3D
@export var base_size: float = 5.0
@export var irregularity_strength: float = 1.5
@export var detail_level: int = 32
@export var auto_regenerate: bool = true
@export var regeneration_interval: float = 3.0

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var procedural_mesh: ArrayMesh
var regeneration_timer: float = 0.0

func _ready():
	# Crear nodos necesarios si no existen
	setup_nodes()
	
	# Generar el primer meteorito procedural
	generate_procedural_meteorite()
	
	# Configurar material básico
	setup_material()

func _physics_process(delta):
	# Manejar atracción hacia el planeta
	if planet:
		var dir = (planet.global_position - global_position).normalized()
		apply_central_force(dir * 50.0)
	
	# Regenerar forma si está habilitado
	if auto_regenerate:
		regeneration_timer += delta
		if regeneration_timer >= regeneration_interval:
			regeneration_timer = 0.0
			generate_procedural_meteorite()

func setup_nodes():
	# Buscar o crear MeshInstance3D
	mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
	
	# Buscar o crear CollisionShape3D
	collision_shape = get_node_or_null("CollisionShape3D")
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)

func generate_procedural_meteorite():
	# Generar geometría procedural
	var arrays = generate_meteorite_geometry()
	
	# Crear el mesh
	procedural_mesh = ArrayMesh.new()
	procedural_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Aplicar el mesh
	mesh_instance.mesh = procedural_mesh
	
	# Crear colisión aproximada
	create_collision_shape()

func generate_meteorite_geometry() -> Dictionary:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Generar vertices basados en una esfera con perturbaciones
	var vertex_count = 0
	var phi_segments = detail_level
	var theta_segments = detail_level
	
	for i in range(phi_segments + 1):
		var phi = PI * i / phi_segments
		for j in range(theta_segments + 1):
			var theta = 2.0 * PI * j / theta_segments
			
			# Posición base en esfera
			var x = sin(phi) * cos(theta)
			var y = cos(phi)
			var z = sin(phi) * sin(theta)
			
			# Aplicar perturbaciones irregulares
			var noise_scale = 0.3
			var noise_x = sin(theta * 3.0 + phi * 2.0) * noise_scale
			var noise_y = cos(theta * 2.5 + phi * 1.5) * noise_scale
			var noise_z = sin(theta * 1.8 + phi * 3.2) * noise_scale
			
			# Aplicar variaciones de tamaño
			var size_variation = 1.0 + sin(theta * 4.0) * 0.2 + cos(phi * 3.0) * 0.15
			
			# Crear vertices finales
			var final_x = (x + noise_x) * base_size * size_variation * irregularity_strength
			var final_y = (y + noise_y) * base_size * size_variation * irregularity_strength
			var final_z = (z + noise_z) * base_size * size_variation * irregularity_strength
			
			vertices.append(Vector3(final_x, final_y, final_z))
			
			# Calcular normal (aproximada)
			var normal = Vector3(final_x, final_y, final_z).normalized()
			normals.append(normal)
			
			# UVs simples
			uvs.append(Vector2(float(j) / theta_segments, float(i) / phi_segments))
			
			# Crear índices para triángulos
			if i < phi_segments and j < theta_segments:
				var current = i * (theta_segments + 1) + j
				var next = current + theta_segments + 1
				
				# Triángulo 1
				indices.append(current)
				indices.append(next)
				indices.append(current + 1)
				
				# Triángulo 2
				indices.append(current + 1)
				indices.append(next)
				indices.append(next + 1)
	
	return {
		"vertices": vertices,
		"normals": normals,
		"uv": uvs,
		"indices": indices
	}

func create_collision_shape():
	# Crear una colisión aproximada usando el mesh generado
	if procedural_mesh:
		var trimesh_shape = procedural_mesh.create_trimesh_shape()
		collision_shape.shape = trimesh_shape

func setup_material():
	# Crear un material básico para el meteorito
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.25, 0.2)  # Color marrón oscuro
	material.roughness = 0.8
	material.metallic = 0.1
	
	if mesh_instance:
		mesh_instance.material_override = material

# Función pública para regenerar manualmente
func regenerate_shape():
	generate_procedural_meteorite()

# Función para ajustar parámetros en tiempo real
func set_irregularity_strength(strength: float):
	irregularity_strength = strength
	generate_procedural_meteorite()

func set_base_size(size: float):
	base_size = size
	generate_procedural_meteorite()

func set_detail_level(level: int):
	detail_level = max(8, min(64, level))  # Limitar entre 8 y 64
	generate_procedural_meteorite()
