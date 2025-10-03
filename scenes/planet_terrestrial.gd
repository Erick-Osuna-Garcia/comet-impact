# PlanetTerrestrial.gd
extends MeshInstance3D

var shader_material : ShaderMaterial

func _ready():
	# Accede al material del planeta
	shader_material = get_active_material(0) as ShaderMaterial
	
	# Conectar la señal del área (detección de meteoritos)
	$Area3D.body_entered.connect(_on_body_entered)

# Función cuando un cuerpo entra en el área
func _on_body_entered(body: Node):
<<<<<<< HEAD
	if body is RigidBody3D and body.name == "Meteorito":
		print("¡Impacto detectado en el planeta!")
		_simulate_impact(body.global_position)
		animate_crater()
		#body.queue_free() # Elimina el meteorito tras impacto
=======
	if body is RigidBody3D and body.name == "Meteorite":
		print("¡Impacto detectado en el planeta!")
		_simulate_impact(body.global_position)
		animate_crater()
		body.queue_free() # Elimina el meteorito tras impacto
>>>>>>> 6bafaee (Actualizacion de coasas)

# Simula impacto en el shader
func _simulate_impact(hit_position: Vector3):
	# Convertir la posición a espacio local
	var local_pos = to_local(hit_position)
<<<<<<< HEAD
	
	shader_material.set_shader_parameter("impact_position", local_pos)
	shader_material.set_shader_parameter("impact_radius", 100.5)
	shader_material.set_shader_parameter("impact_strength", 3.0) # empieza en 0
=======
	shader_material.set_shader_parameter("impact_position", local_pos)
	shader_material.set_shader_parameter("impact_radius", 0.5)
	shader_material.set_shader_parameter("impact_strength", 0.0) # empieza en 0
>>>>>>> 6bafaee (Actualizacion de coasas)

# Animar crecimiento del cráter
func animate_crater():
	var t = 0.0
	while t < 1.0:
		shader_material.set_shader_parameter("impact_strength", t)
		t += 0.05
		await get_tree().create_timer(0.05).timeout
