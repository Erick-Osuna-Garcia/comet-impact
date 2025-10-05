extends Node3D

const ASTEROID_SCENE = preload("res://scenes/Asteroides.tscn")

# --- Constantes de escala definidas a nivel del script ---
const DIAMETRO_REAL_TIERRA_KM = 12742.0
const DIAMETRO_JUEGO_PLANETA = 400.0
const escala_km_a_unidades = DIAMETRO_JUEGO_PLANETA / DIAMETRO_REAL_TIERRA_KM

func _ready():
	# Define la ruta a tu archivo JSON local
	var archivo_path = "res://scripts/Nasa.json"
	
	# Abre y lee el archivo de texto
	var file = FileAccess.open(archivo_path, FileAccess.READ)
	if not FileAccess.file_exists(archivo_path):
		print("Error: El archivo JSON no se encuentra en la ruta: ", archivo_path)
		return
		
	var json_string = file.get_as_text()
	
	# Convierte el texto a datos
	var json_data = JSON.parse_string(json_string)
	
	# Procesa los datos y llama a la función para generar asteroides
	if json_data:
		var asteroides = json_data.get("near_earth_objects", [])
		print("Asteroides cargados desde archivo local: ", asteroides.size())
		generar_asteroides(asteroides)
	else:
		print("Error: No se pudo interpretar el archivo JSON.")

func generar_asteroides(datos_asteroides):
	# El bucle ahora recorrerá todos los elementos sin detenerse
	for data in datos_asteroides:
		var asteroide = ASTEROID_SCENE.instantiate()

		# --- CONFIGURACIÓN DE TAMAÑO ---
		asteroide.name = data.get("name", "Asteroide Sin Nombre")
		var diametro_km = data.estimated_diameter.kilometers.estimated_diameter_max
		var escala_juego_tamano = diametro_km / 100.0
		asteroide.scale = Vector3.ONE * escala_juego_tamano

		# --- CONFIGURACIÓN DE POSICIÓN BASADA EN EL JSON ---
		if not data.has("close_approach_data") or data.close_approach_data.is_empty():
			continue

		var distancia_real_km = data.close_approach_data[0].miss_distance.kilometers.to_float()
		var distancia_juego = distancia_real_km * escala_km_a_unidades
		
		var direccion_aleatoria = Vector3.ZERO.direction_to(
			Vector3(randf(), randf(), randf()).normalized()
		)

		# --- LÍNEAS INDENTADAS CORRECTAMENTE DENTRO DEL BUCLE ---
		var radio_planeta = DIAMETRO_JUEGO_PLANETA / 2.0
		asteroide.position = direccion_aleatoria * (radio_planeta + distancia_juego)
		
		add_child(asteroide)
