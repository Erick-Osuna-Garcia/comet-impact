extends RigidBody3D

@export var fuerza_gravedad = 1000000.0

var planeta_cercano = null

func _ready():
	# Busca el planeta más cercano al iniciar el juego.
	encontrar_planeta_cercano()

func _physics_process(delta):
	if not is_instance_valid(planeta_cercano):
		# Si no hay planeta, no hace nada.
		return

	# Calcula el vector de dirección desde el asteroide hacia el planeta.
	var direccion = planeta_cercano.global_position - self.global_position
	var distancia_cuadrada = direccion.length_squared()
	
	if distancia_cuadrada == 0:
		return
		
	# Calcula la magnitud de la fuerza.
	var magnitud_fuerza = (fuerza_gravedad * self.mass) / distancia_cuadrada
	
	# Crea el vector de fuerza final.
	var fuerza_final = direccion.normalized() * magnitud_fuerza
	
	# Aplica la fuerza al centro del asteroide.
	apply_central_force(fuerza_final)
	
	# --- LÍNEA DE DEPURACIÓN ---
	# Imprime la fuerza que se está aplicando en cada fotograma de física.
	# Puedes comentar o borrar esta línea cuando todo funcione bien.
	print("Aplicando fuerza: ", fuerza_final)


func encontrar_planeta_cercano():
	var cuerpos = get_tree().get_nodes_in_group("cuerpos_gravitacionales")
	var distancia_minima = INF
	
	if cuerpos.size() == 0:
		print("ADVERTENCIA: No se encontró ningún nodo en el grupo 'cuerpos_gravitacionales'.")
		return

	for cuerpo in cuerpos:
		var distancia = self.global_position.distance_to(cuerpo.global_position)
		if distancia < distancia_minima:
			distancia_minima = distancia
			planeta_cercano = cuerpo
	
	# --- LÍNEA DE DEPURACIÓN ---
	if is_instance_valid(planeta_cercano):
		print("Planeta encontrado : ", planeta_cercano.name)
