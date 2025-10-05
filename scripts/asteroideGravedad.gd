# OrbitalCamera.gd
extends Camera3D

# --- Variables para controlar la cámara desde el Inspector ---
@export var initial_target: NodePath
@export var rotation_speed = 1.0
@export var zoom_speed = 10
@export var min_zoom = 450
@export var max_zoom = 10000

# --- Referencia a la etiqueta de texto ---
@onready var target_label = $CanvasLayer/TargetNameLabel

# --- Variables internas de la cámara ---
var target: Node3D = null
var distance = 500.0
var yaw = 0.0
var pitch = deg_to_rad(-30)

# --- NUEVAS VARIABLES PARA CICLAR OBJETIVOS ---
var all_targets = []
var current_target_index = 0

# La función _ready se ejecuta una sola vez al iniciar el juego.
func _ready():
	target_label.text = ""

	# Revisa si se asignó un objetivo inicial en el editor.
	if not initial_target.is_empty():
		var target_node = get_node_or_null(initial_target)
		if target_node:
			set_target(target_node)
		else:
			print("ADVERTENCIA: No se pudo encontrar el objetivo inicial asignado.")
	
	# NUEVO: Espera un momento y luego busca todos los asteroides.
	await get_tree().create_timer(0.1).timeout
	find_all_targets()

func _unhandled_input(event):
	# --- NUEVO: Lógica para cambiar de objetivo con 'Tab' ---
	# (Asegúrate de tener una acción "cycle_target" asignada a la tecla Tab)
	if Input.is_action_just_pressed("Cambiar Astro") and not all_targets.is_empty():
		current_target_index += 1
		if current_target_index >= all_targets.size():
			current_target_index = 0
		set_target(all_targets[current_target_index])

	# (Tu código para el zoom se queda igual)
	if target == null:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			distance = clamp(distance - zoom_speed, min_zoom, max_zoom)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			distance = clamp(distance + zoom_speed, min_zoom, max_zoom)

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

func set_target(new_target: Node3D):
	target = new_target
	if target:
		print("Cámara ahora enfocando a: ", target.name)
		target_label.text = target.name
		_physics_process(0)
	else:
		target_label.text = ""

# --- NUEVA FUNCIÓN: Busca todos los asteroides ---
func find_all_targets():
	# Busca todos los nodos que estén en el grupo "asteroides".
	all_targets = get_tree().get_nodes_in_group("asteroides")
	print("Cámara encontró ", all_targets.size(), " asteroides para enfocar.")
	
	# Si no hay un objetivo inicial, enfoca el primer asteroide de la lista.
	if target == null and not all_targets.is_empty():
		set_target(all_targets[0])
