extends StaticBody3D

# --- Carga la escena del "sello" de cráter que creaste ---
# Asegúrate de que la ruta a tu crater.tscn sea correcta.
const CRATER_SCENE = preload("res://scenes/crater.tscn")

func recibir_impacto(posicion_impacto: Vector3, normal_impacto: Vector3):
	print("¡Impacto! Creando cráter en la superficie.")
	
	# 1. Crea una instancia del cráter.
	var crater = CRATER_SCENE.instantiate()
	
	# 2. Añádelo como hijo del planeta.
	add_child(crater)
	
	# 3. Mueve el cráter al lugar exacto del impacto.
	crater.global_position = posicion_impacto
	
	# --- CÓDIGO DE ALINEACIÓN CORREGIDO ---
	
	# 4. Primero, orienta el "frente" del cráter para que apunte hacia afuera de la superficie.
	crater.look_at(posicion_impacto + normal_impacto)
	
	# 5. Luego, rótalo 90 grados sobre su propio eje X para "acostarlo".
	crater.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
