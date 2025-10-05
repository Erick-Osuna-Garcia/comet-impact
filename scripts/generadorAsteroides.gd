# generadorAsteroides.gd
extends Node3D

const ASTEROID_SCENE = preload("res://scenes/Asteroides.tscn")

# --- Constantes de escala definidas a nivel del script ---
# Nota: La constante 'escala_km_a_unidades' ya no se usa para la posición,
# pero la dejamos por si la necesitas para otros cálculos.
const DIAMETRO_REAL_TIERRA_KM = 12742.0
const DIAMETRO_JUEGO_PLANETA = 400.0
const escala_km_a_unidades = DIAMETRO_JUEGO_PLANETA / DIAMETRO_REAL_TIERRA_KM

func _ready():
	var archivo_path = "res://scripts/Nasa.json"
	
	var file = FileAccess.open(archivo_path, FileAccess.READ)
	if not FileAccess.file_exists(archivo_path):
		print("Error: El archivo JSON no se encuentra en la ruta: ", archivo_path)
		return
		
	var json_string = file.get_as_text()
	var json_data = JSON.parse_string(json_string)
	
	if json_data:
		var asteroides = json_data.get("near_earth_objects", [])
		print("Asteroides cargados desde archivo local: ", asteroides.size())
		generar_asteroides(asteroides)
	else:
		print("Error: No se pudo interpretar el archivo JSON.")

func generar_asteroides(datos_asteroides):
	if datos_asteroides.is_empty():
		return

	# --- PASO 1: Encontrar las distancias mínimas y máximas del JSON ---
	var min_distancia_real = INF
	var max_distancia_real = 0.0
	
	for data in datos_asteroides:
		if data.has("close_approach_data") and not data.close_approach_data.is_empty():
			var distancia_km = data.close_approach_data[0].miss_distance.kilometers.to_float()
			min_distancia_real = min(min_distancia_real, distancia_km)
			max_distancia_real = max(max_distancia_real, distancia_km)
			
	print("Rango de distancias reales (km): ", min_distancia_real, " a ", max_distancia_real)

	# --- PASO 2: Generar los asteroides usando el rango remapeado ---
	var radio_planeta = DIAMETRO_JUEGO_PLANETA / 2.0
	
	for data in datos_asteroides:
		var asteroide = ASTEROID_SCENE.instantiate()

		# --- CONFIGURACIÓN DE TAMAÑO ---
		asteroide.name = data.get("name", "Asteroide Sin Nombre")
		var diametro_km = data.estimated_diameter.kilometers.estimated_diameter_max
		var escala_juego_tamano = diametro_km / 100.0
		asteroide.scale = Vector3.ONE * escala_juego_tamano

		# --- CONFIGURACIÓN DE POSICIÓN REMAPEADA ---
		if not data.has("close_approach_data") or data.close_approach_data.is_empty():
			continue

		var distancia_real_km = data.close_approach_data[0].miss_distance.kilometers.to_float()
		
		# Remapeamos la distancia real al rango del juego (desde el borde del planeta hasta 2000).
		var distancia_juego = remap(distancia_real_km, min_distancia_real, max_distancia_real, radio_planeta, 2000.0)
		
		var direccion_aleatoria = Vector3.ZERO.direction_to(
			Vector3(randf(), randf(), randf()).normalized()
		)

		asteroide.position = direccion_aleatoria * distancia_juego
		
		asteroide.add_to_group("asteroides")
		add_child(asteroide)
