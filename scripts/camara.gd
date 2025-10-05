# camara.gd
extends Camera3D

# --- Variables para controlar la cámara desde el Inspector ---
@export var initial_target: NodePath
@export var planet_target: Node3D # Arrastra tu nodo del planeta aquí
@export var rotation_speed = 1.0
@export var zoom_speed = 10
@export var min_zoom = 450 # Límite mínimo de zoom para el planeta
@export var max_zoom = 10000 # Límite máximo de zoom para el planeta

# --- Referencia a la etiqueta de texto ---
@onready var target_label = $CanvasLayer/Titulo

# --- Variables internas de la cámara ---
var target: Node3D = null
var distance = 500.0 # Distancia por defecto
var yaw = 0.0
var pitch = deg_to_rad(-30)

# --- Variables para ciclar objetivos ---
var all_targets = []
var current_target_index = 0

func _ready():
	target_label.text = ""
	await get_tree().create_timer(0.1).timeout
	find_all_targets()
	
	if target == null and not all_targets.is_empty():
		set_target(all_targets[0])
	elif not initial_target.is_empty():
		var target_node = get_node_or_null(initial_target)
		if target_node:
			set_target(target_node)

func _unhandled_input(event):
	# Lógica para cambiar de objetivo con la acción "Cambiar Astro".
	if Input.is_action_just_pressed("Cambiar Astro") and not all_targets.is_empty():
		current_target_index = (current_target_index + 1) % all_targets.size()
		set_target(all_targets[current_target_index])

	# --- CÓDIGO DE DEPURACIÓN PARA LA TECLA 'F' ---
	if Input.is_action_just_pressed("activar_gravedad"):
		print("--- Depurando la tecla 'F' ---")
		print("1. Tecla 'F' presionada.")
		print("2. Objetivo actual: ", target)
		
		if target != null:
			print("3. ¿Es el planeta?: ", target == planet_target)
			print("4. ¿Tiene el método 'activar_gravedad'?: ", target.has_method("activar_gravedad"))
			
			if target != planet_target and target.has_method("activar_gravedad"):
				target.activar_gravedad()
			else:
				print("--- Una condición falló. No se llamó a activar_gravedad(). ---")
		else:
			print("--- Condición 2 falló: No hay objetivo seleccionado ---")
	
	# Código para el zoom con la rueda del mouse.
	if target == null:
		return
		
	if event is InputEventMouseButton:
		var new_distance = distance
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			new_distance -= zoom_speed
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			new_distance += zoom_speed
		
		if target == planet_target:
			distance = clamp(new_distance, min_zoom, max_zoom)
		else:
			distance = clamp(new_distance, 10, 20)

func _physics_process(delta):
	if target == null:
		return

	var input = Input.get_vector("Izquierda", "Derecha", "Arriba", "Abajo")
	yaw += input.x * rotation_speed * delta
	pitch += input.y * rotation_speed * delta
	pitch = clamp(pitch, deg_to_rad(-85), deg_to_rad(85))
	
	var offset = Vector3(0, 0, distance)
	offset = offset.rotated(Vector3.RIGHT, pitch)
	offset = offset.rotated(Vector3.UP, yaw)
	
	global_position = target.global_position + offset
	look_at(target.global_position)
	
	if is_instance_valid(planet_target):
		var distancia_actual = planet_target.global_position.distance_to(target.global_position)
		target_label.text = "%s\nDistancia: %s unidades" % [target.name, int(distancia_actual)]

func set_target(new_target: Node3D):
	target = new_target
	if target:
		if target == planet_target:
			distance = 500.0
		else:
			distance = 20.0
		_physics_process(0)
	else:
		target_label.text = ""

func find_all_targets():
	all_targets = get_tree().get_nodes_in_group("asteroides")
	if planet_target:
		all_targets.push_front(planet_target)
	print("Cámara encontró ", all_targets.size(), " objetivos para enfocar.")
