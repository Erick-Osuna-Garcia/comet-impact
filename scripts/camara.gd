# camara.gd
extends Camera3D

# --- Variables para controlar la cámara desde el Inspector ---
@export var initial_target: NodePath
@export var planet_target: Node3D
@export var rotation_speed = 1.0
@export var zoom_speed = 10
@export var min_zoom = 450
@export var max_zoom = 10000

# --- NUEVAS VARIABLES PARA LOS MODOS DE CÁMARA ---
enum ModoCamara { ORBITAL, PERSECUCION }
var modo_actual = ModoCamara.ORBITAL

@onready var target_label = $CanvasLayer/Titulo

# --- Variables internas de la cámara ---
var target: Node3D = null
var distance = 500.0
var yaw = 0.0
var pitch = deg_to_rad(-30)
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
	# --- Lógica para cambiar de modo con '1' y '2' ---
	if Input.is_action_just_pressed("cam_modo_orbital"):
		modo_actual = ModoCamara.ORBITAL
		print("Cámara en modo ORBITAL")
	if Input.is_action_just_pressed("cam_modo_persecucion"):
		modo_actual = ModoCamara.PERSECUCION
		print("Cámara en modo PERSECUCIÓN")

	# Lógica para ciclar objetivos con "Cambiar Astro"
	if Input.is_action_just_pressed("Cambiar Astro") and not all_targets.is_empty():
		current_target_index = (current_target_index + 1) % all_targets.size()
		set_target(all_targets[current_target_index])

	# Lógica para activar gravedad con "F"
	if Input.is_action_just_pressed("activar_gravedad") and target != null:
		if target != planet_target and target.has_method("activar_gravedad"):
			target.activar_gravedad()

	if target == null: return
	
	# El zoom y la rotación solo funcionan en modo ORBITAL
	if modo_actual == ModoCamara.ORBITAL:
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

	# --- Lógica de movimiento separada por modo ---
	match modo_actual:
		ModoCamara.ORBITAL:
			# El código de la cámara orbital que ya tenías
			var input = Input.get_vector("Izquierda", "Derecha", "Arriba", "Abajo")
			yaw += input.x * rotation_speed * delta
			pitch += input.y * rotation_speed * delta
			pitch = clamp(pitch, deg_to_rad(-85), deg_to_rad(85))
			
			var offset = Vector3(0, 0, distance)
			offset = offset.rotated(Vector3.RIGHT, pitch)
			offset = offset.rotated(Vector3.UP, yaw)
			
			global_position = target.global_position + offset
			look_at(target.global_position)
		
		ModoCamara.PERSECUCION:
			# --- CÓDIGO MODIFICADO ---
			# La cámara ahora se posiciona 20 unidades detrás del asteroide
			if is_instance_valid(planet_target) and is_instance_valid(target):
				# Calcula la dirección desde el planeta hacia el asteroide (para ponernos detrás)
				var direccion = (target.global_position - planet_target.global_position).normalized()
				# La nueva posición es la del asteroide + 20 unidades en esa dirección (y un poco elevado)
				global_position = target.global_position + (direccion * 20) + (Vector3.UP * 5)
				# Miramos siempre al planeta
				look_at(planet_target.global_position)

	# La actualización de la UI se hace sin importar el modo
	if is_instance_valid(planet_target) and is_instance_valid(target):
		var distancia_actual = planet_target.global_position.distance_to(target.global_position)
		target_label.text = "%s\nDistancia: %s unidades" % [target.name, int(distancia_actual)]

func set_target(new_target: Node3D):
	target = new_target
	# Al cambiar de objetivo, siempre volvemos al modo ORBITAL por defecto
	modo_actual = ModoCamara.ORBITAL
	
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
