# EventLogs.gd - Sistema de logging para cámaras y planetas
extends Node3D

# Variables para almacenar estados anteriores
var previous_camera_states = {}
var previous_planet_states = {}
var log_enabled = true

# Referencias a nodos importantes
var cameras = []
var planets = []

func _ready():
	print("=== SISTEMA DE LOGS INICIADO ===")
	# Buscar todas las cámaras y planetas en la escena
	_find_cameras_and_planets()
	
	# Inicializar estados
	_initialize_states()
	
	# Conectar señales de cambio de visibilidad
	_connect_visibility_signals()
	
	print("Logs activados para ", cameras.size(), " cámaras y ", planets.size(), " planetas")

# Buscar cámaras y planetas en la escena
func _find_cameras_and_planets():
	cameras.clear()
	planets.clear()
	
	# Buscar cámaras
	var camera_nodes = _find_nodes_by_class("Camera3D")
	cameras = camera_nodes
	
	# Buscar planetas (MeshInstance3D con nombre que contenga "planet")
	var mesh_nodes = _find_nodes_by_class("MeshInstance3D")
	for mesh in mesh_nodes:
		if "planet" in mesh.name.to_lower():
			planets.append(mesh)

# Función auxiliar para buscar nodos por clase
func _find_nodes_by_class(node_class: String) -> Array:
	var found_nodes = []
	_find_nodes_recursive(get_tree().current_scene, node_class, found_nodes)
	return found_nodes

func _find_nodes_recursive(node: Node, node_class: String, result: Array):
	if node.get_class() == node_class:
		result.append(node)
	
	for child in node.get_children():
		_find_nodes_recursive(child, node_class, result)

# Inicializar estados de todos los objetos
func _initialize_states():
	# Estados iniciales de cámaras
	for camera in cameras:
		if camera:
			previous_camera_states[camera] = {
				"visible": camera.visible,
				"position": camera.global_position,
				"rotation": camera.global_rotation,
				"target": null
			}
	
	# Estados iniciales de planetas
	for planet in planets:
		if planet:
			previous_planet_states[planet] = {
				"visible": planet.visible,
				"position": planet.global_position,
				"rotation": planet.global_rotation,
				"scale": planet.scale
			}

# Conectar señales de visibilidad
func _connect_visibility_signals():
	# Conectar señales para cámaras
	for camera in cameras:
		if camera and camera.has_signal("visibility_changed"):
			camera.visibility_changed.connect(_on_camera_visibility_changed.bind(camera))
	
	# Conectar señales para planetas
	for planet in planets:
		if planet and planet.has_signal("visibility_changed"):
			planet.visibility_changed.connect(_on_planet_visibility_changed.bind(planet))

# Monitoreo continuo en _process
func _process(_delta):
	if not log_enabled:
		return
		
	_check_camera_changes()
	_check_planet_changes()

# Verificar cambios en cámaras
func _check_camera_changes():
	for camera in cameras:
		if not camera:
			continue
			
		var current_state = {
			"visible": camera.visible,
			"position": camera.global_position,
			"rotation": camera.global_rotation,
			"target": null
		}
		
		# Verificar si la cámara tiene un target (para cámaras orbitales)
		if camera.has_method("get") and camera.get("target"):
			current_state.target = camera.target.name if camera.target else null
		
		var previous_state = previous_camera_states.get(camera, {})
		
		# Verificar cambios
		if previous_state.get("visible") != current_state.visible:
			_log_camera_visibility_change(camera, current_state.visible)
		
		if previous_state.get("position") != current_state.position:
			_log_camera_position_change(camera, previous_state.get("position"), current_state.position)
		
		# Comentado: Logs de rotación de cámara deshabilitados
		# if previous_state.get("rotation") != current_state.rotation:
		# 	_log_camera_rotation_change(camera, previous_state.get("rotation"), current_state.rotation)
		
		if previous_state.get("target") != current_state.target:
			_log_camera_target_change(camera, previous_state.get("target"), current_state.target)
		
		previous_camera_states[camera] = current_state

# Verificar cambios en planetas
func _check_planet_changes():
	for planet in planets:
		if not planet:
			continue
			
		var current_state = {
			"visible": planet.visible,
			"position": planet.global_position,
			"rotation": planet.global_rotation,
			"scale": planet.scale
		}
		
		var previous_state = previous_planet_states.get(planet, {})
		
		# Verificar cambios
		if previous_state.get("visible") != current_state.visible:
			_log_planet_visibility_change(planet, current_state.visible)
		
		if previous_state.get("position") != current_state.position:
			_log_planet_position_change(planet, previous_state.get("position"), current_state.position)
		
		# Comentado: Logs de rotación de planeta deshabilitados
		# if previous_state.get("rotation") != current_state.rotation:
		# 	_log_planet_rotation_change(planet, previous_state.get("rotation"), current_state.rotation)
		
		if previous_state.get("scale") != current_state.scale:
			_log_planet_scale_change(planet, previous_state.get("scale"), current_state.scale)
		
		previous_planet_states[planet] = current_state

# Funciones de logging para cámaras
func _log_camera_visibility_change(camera: Camera3D, visibility_state: bool):
	var timestamp = Time.get_datetime_string_from_system()
	var visibility = "VISIBLE" if visibility_state else "INVISIBLE"
	print("[", timestamp, "] CAMERA: ", camera.name, " cambió a ", visibility)

func _log_camera_position_change(camera: Camera3D, old_pos: Vector3, new_pos: Vector3):
	var timestamp = Time.get_datetime_string_from_system()
	print("[", timestamp, "] CAMERA: ", camera.name, " posición: ", old_pos, " -> ", new_pos)

# Comentado: Función de logging de rotación de cámara deshabilitada
# func _log_camera_rotation_change(camera: Camera3D, old_rot: Vector3, new_rot: Vector3):
# 	var timestamp = Time.get_datetime_string_from_system()
# 	print("[", timestamp, "] CAMERA: ", camera.name, " rotación: ", old_rot, " -> ", new_rot)

func _log_camera_target_change(camera: Camera3D, old_target, new_target):
	var timestamp = Time.get_datetime_string_from_system()
	var old_str = old_target if old_target != null else "null"
	var new_str = new_target if new_target != null else "null"
	print("[", timestamp, "] CAMERA: ", camera.name, " objetivo: ", old_str, " -> ", new_str)

# Funciones de logging para planetas
func _log_planet_visibility_change(planet: MeshInstance3D, visibility_state: bool):
	var timestamp = Time.get_datetime_string_from_system()
	var visibility = "VISIBLE" if visibility_state else "INVISIBLE"
	print("[", timestamp, "] PLANET: ", planet.name, " cambió a ", visibility)

func _log_planet_position_change(planet: MeshInstance3D, old_pos: Vector3, new_pos: Vector3):
	var timestamp = Time.get_datetime_string_from_system()
	print("[", timestamp, "] PLANET: ", planet.name, " posición: ", old_pos, " -> ", new_pos)

# Comentado: Función de logging de rotación de planeta deshabilitada
# func _log_planet_rotation_change(planet: MeshInstance3D, old_rot: Vector3, new_rot: Vector3):
# 	var timestamp = Time.get_datetime_string_from_system()
# 	print("[", timestamp, "] PLANET: ", planet.name, " rotación: ", old_rot, " -> ", new_rot)

func _log_planet_scale_change(planet: MeshInstance3D, old_scale: Vector3, new_scale: Vector3):
	var timestamp = Time.get_datetime_string_from_system()
	print("[", timestamp, "] PLANET: ", planet.name, " escala: ", old_scale, " -> ", new_scale)

# Funciones de callback para señales de visibilidad
func _on_camera_visibility_changed(camera: Camera3D):
	if log_enabled:
		_log_camera_visibility_change(camera, camera.visible)

func _on_planet_visibility_changed(planet: MeshInstance3D):
	if log_enabled:
		_log_planet_visibility_change(planet, planet.visible)

# Funciones públicas para controlar el logging
func enable_logging():
	log_enabled = true
	print("=== LOGGING ACTIVADO ===")

func disable_logging():
	log_enabled = false
	print("=== LOGGING DESACTIVADO ===")

func get_log_summary():
	print("=== RESUMEN DE ESTADOS ACTUALES ===")
	print("Cámaras monitoreadas: ", cameras.size())
	for camera in cameras:
		if camera:
			print("  - ", camera.name, ": ", "VISIBLE" if camera.visible else "INVISIBLE")
	
	print("Planetas monitoreados: ", planets.size())
	for planet in planets:
		if planet:
			print("  - ", planet.name, ": ", "VISIBLE" if planet.visible else "INVISIBLE")
	print("===================================")
