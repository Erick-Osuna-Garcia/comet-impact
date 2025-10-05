extends Control

@export var camera: Camera3D
@export var camera_2d: Camera3D
var is_flat_view = false

# Variables para guardar el estado inicial de la cámara orbital
var initial_camera_position: Vector3
var initial_camera_rotation: Vector3
var initial_camera_fov: float

func _ready():
	# Buscar las cámaras si no están asignadas
	if not camera:
		camera = get_node("../Camera3D")
	if not camera_2d:
		camera_2d = get_node("../Camera3D2")
	
	# Guardar el estado inicial de la cámara orbital
	if camera:
		initial_camera_position = camera.global_position
		initial_camera_rotation = camera.global_rotation
		initial_camera_fov = camera.fov
	
	# Ocultar la vista 2D al inicio
	var tierra_2d_view = get_node("../Tierra2DView")
	if tierra_2d_view:
		tierra_2d_view.visible = false
	
	# Conectar el botón
	var button = get_node("VBoxContainer/FlatViewButton")
	if button:
		button.pressed.connect(_on_flat_view_button_pressed)

func _on_flat_view_button_pressed():
	is_flat_view = !is_flat_view
	toggle_flat_view()

func toggle_flat_view():
	if not camera or not camera_2d:
		return
		
	var button = get_node("VBoxContainer/FlatViewButton")
	var planets = get_node("../Planets")
	var tierra_2d_view = get_node("../Tierra2DView")
		
	if is_flat_view:
		# Ocultar el nodo Planets y mostrar Tierra2DView
		if planets:
			planets.visible = false
		if tierra_2d_view:
			tierra_2d_view.visible = true
		
		# Cambiar a la cámara 2D directamente
		camera.current = false
		camera_2d.current = true
		
		if button:
			button.text = "Vista Orbital"
	else:
		# Mostrar el nodo Planets y ocultar Tierra2DView
		if planets:
			planets.visible = true
		if tierra_2d_view:
			tierra_2d_view.visible = false
		
		# Cambiar de vuelta a la cámara normal
		camera_2d.current = false
		camera.current = true
		
		# Restaurar el estado inicial de la cámara orbital
		# restore_initial_camera_state()
		
		if button:
			button.text = "Vista Satelital"
		
		# Reanudar el control orbital
		if camera.has_method("set_target"):
			if planets and planets.get_child_count() > 0:
				camera.set_target(planets.get_child(0))

func restore_initial_camera_state():
	if camera:
		camera.global_position = initial_camera_position
		camera.global_rotation = initial_camera_rotation
		camera.fov = initial_camera_fov
