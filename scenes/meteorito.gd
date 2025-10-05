extends RigidBody3D

@export var multiplo_gravedad = 10
@export var fuerza_gravedad = 9.8 

var planeta_cercano = null
var gravedad_activa = false # Nueva variable para controlar la activación

func _ready():
	# Hacemos que la física esté desactivada al iniciar.
	fuerza_gravedad = multiplo_gravedad * fuerza_gravedad
	set_physics_process(false)

func _physics_process(delta):
	if not is_instance_valid(planeta_cercano):
		return
	
	print(fuerza_gravedad)
	# (El resto de tu lógica de cálculo de fuerza se queda igual)
	var direccion = planeta_cercano.global_position - self.global_position
	var distancia_cuadrada = direccion.length_squared()
	
	if distancia_cuadrada == 0:
		return
		
	var magnitud_fuerza = (fuerza_gravedad * self.mass) / distancia_cuadrada
	var fuerza_final = direccion.normalized() * magnitud_fuerza
	apply_central_force(fuerza_final)
	
	#print("Aplicando fuerza a ", self.name, ": ", fuerza_final)

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

func _integrate_forces(state):
	# Revisa si hay algún contacto en este fotograma.
	if state.get_contact_count() > 0:
		print("--- Depuración de Colisión ---")
		print("1. ¡Colisión detectada!")

		var collider = state.get_contact_collider_object(0)
		print("2. Chocó con: ", collider.name if collider else "null")

		if collider:
			print("3. ¿El objeto es un cuerpo gravitacional?: ", collider.is_in_group("cuerpos_gravitacionales"))
			print("4. ¿El objeto tiene el script de planeta?: ", collider.has_method("recibir_impacto"))

			if collider.is_in_group("cuerpos_gravitacionales") and collider.has_method("recibir_impacto"):
				print("5. ¡Éxito! Enviando orden de impacto al planeta...")
				var impact_position = state.get_contact_local_position(0)
				var impact_normal = state.get_contact_local_normal(0)
				collider.recibir_impacto(impact_position, impact_normal)
			else:
				print("--- Fallo: El objeto no es el planeta o no tiene el script correcto. ---")
		queue_free()
