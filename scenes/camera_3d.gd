# OrbitalCamera.gd
extends Camera3D

# --- Variables para controlar la cámara desde el Inspector ---
@export var initial_target: NodePath 
@export var rotation_speed = 1.0

# --- Variables internas de la cámara ---
var target: Node3D = null
var distance = 500.0

# La función _ready se ejecuta una sola vez al iniciar el juego.
func _ready():
	# Revisa si se asignó un objetivo inicial en el editor.
	if not initial_target.is_empty():
		var target_node = get_node_or_null(initial_target)
		if target_node:
			# Si lo encuentra, llama a set_target para enfocarlo.
			set_target(target_node)
		else:
			print("ADVERTENCIA: No se pudo encontrar el objetivo inicial asignado en la ruta: ", initial_target)

func _physics_process(_delta):
	if target == null:
		return

	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var offset = Vector3(0, 0, distance)
	offset = offset.rotated(Vector3.RIGHT, input.y)
	offset = offset.rotated(Vector3.UP, input.x)
	
	global_position = target.global_position + offset
	look_at(target.global_position)

# Esta función la usará tu menú para cambiar de objetivo.
func set_target(new_target: Node3D):
	target = new_target
	if target:
		print("Cámara ahora enfocando a: ", target.name)
		# Forzamos una actualización inmediata para que no haya un "salto" de cámara.
		_physics_process(0)
		# Mostrar propiedades de la cámara y coordenadas
		_show_camera_info()

# Función para mostrar información detallada de la cámara
func _show_camera_info():
	if target:
		print("=== INFORMACIÓN DE LA CÁMARA ===")
		print("Objetivo: ", target.name)
		print("Posición de la cámara: ", global_position)
		print("Posición del objetivo: ", target.global_position)
		print("Distancia: ", distance)
		print("Rotación de la cámara: ", global_rotation_degrees)
		print("Velocidad de rotación: ", rotation_speed)
		print("Campo de visión: ", fov, " grados")
		print("=================================")
		
		# Mostrar información del planeta si es un MeshInstance3D (planeta)
		_show_planet_info()

# Función para mostrar información del planeta
func _show_planet_info():
	if target and target is MeshInstance3D:
		print("=== INFORMACIÓN DEL PLANETA ===")
		print("Nombre del planeta: ", target.name)
		print("Tipo de nodo: ", target.get_class())
		print("Posición global: ", target.global_position)
		print("Rotación global: ", target.global_rotation_degrees)
		print("Escala: ", target.scale)
		
		# Verificar si tiene material
		if target.get_surface_override_material_count() > 0:
			print("Materiales: ", target.get_surface_override_material_count())
		
		# Verificar si tiene Area3D para detección de impactos
		var area = target.get_node_or_null("Area3D")
		if area:
			print("Detección de impactos: Activada")
		else:
			print("Detección de impactos: No encontrada")
		
		# Verificar si tiene RigidBody3D
		if target is RigidBody3D:
			print("Tipo: Cuerpo rígido")
			print("Masa: ", target.mass)
			print("Velocidad: ", target.linear_velocity)
			print("Velocidad angular: ", target.angular_velocity)
		
		print("=================================")
