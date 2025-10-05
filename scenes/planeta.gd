extends Node3D

const CRATER_SCENE = preload("res://scenes/crater.tscn")

func recibir_impacto(posicion_impacto: Vector3, normal_impacto: Vector3):
	print("¡Impacto! Creando cráter.")
	
	var crater = CRATER_SCENE.instantiate()
	
	add_child(crater)
	
	crater.global_position = posicion_impacto
	
	crater.look_at(posicion_impacto + normal_impacto)
