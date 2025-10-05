# asteroides.gd
extends RigidBody3D

@export var fuerza_gravedad = 10000000000000.0

var planeta_cercano = null
var gravedad_activa = false # Nueva variable para controlar la activación

func _ready():
	# Hacemos que la física esté desactivada al iniciar.
	set_physics_process(false)

func _physics_process(delta):
	if not is_instance_valid(planeta_cercano):
		return

	# (El resto de tu lógica de cálculo de fuerza se queda igual)
	var direccion = planeta_cercano.global_position - self.global_position
	var distancia_cuadrada = direccion.length_squared()
	
	if distancia_cuadrada == 0:
		return
		
	var magnitud_fuerza = (fuerza_gravedad * self.mass) / distancia_cuadrada
	var fuerza_final = direccion.normalized() * magnitud_fuerza
	apply_central_force(fuerza_final)
	
	print("Aplicando fuerza a ", self.name, ": ", fuerza_final)

func encontrar_planeta_cercano():
	# (Esta función se queda igual)
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
	
	if is_instance_valid(planeta_cercano):
		print(self.name, " encontró su planeta: ", planeta_cercano.name)

# --- NUEVA FUNCIÓN PARA ACTIVAR LA GRAVEDAD ---
# Esta función será llamada desde la cámara.
func activar_gravedad():
	# Si ya está activa, no hace nada más.
	if gravedad_activa:
		return
	
	gravedad_activa = true
	print("¡Gravedad ACTIVADA para ", self.name, "!")
	# Busca el planeta más cercano en el momento de la activación.
	encontrar_planeta_cercano()
	# Activa la ejecución de _physics_process().
	set_physics_process(true)
