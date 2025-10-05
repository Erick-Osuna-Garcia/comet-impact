# OrbitalCamera.gd
extends Camera3D

# --- Variables para controlar la cámara desde el Inspector ---
@export var initial_target: NodePath 
@export var rotation_speed = 1.0
@export var zoom_speed = 0.005
@export var min_zoom = 500
@export var max_zoom = 1000

# --- Variables internas de la cámara ---
var target: Node3D = null
var distance = 300.0
var yaw = 0.0
var pitch = deg_to_rad(-30)

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

func _unhandled_input(event):
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

	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	yaw += input.x * rotation_speed * delta
	pitch += input.y * rotation_speed * delta
	pitch = clamp(pitch, deg_to_rad(-85), deg_to_rad(85))
	
	var offset = Vector3(0, 0, distance)
	offset = offset.rotated(Vector3.RIGHT, pitch)
	offset = offset.rotated(Vector3.UP, yaw)
	
	global_position = target.global_position + offset
	look_at(target.global_position)

# Esta función la usará tu menú para cambiar de objetivo.
func set_target(new_target: Node3D):
	target = new_target
	if target:
		print("Cámara ahora enfocando a: ", target.name)
		# Forzamos una actualización inmediata para que no haya un "salto" de cámara.
		_physics_process(0)
