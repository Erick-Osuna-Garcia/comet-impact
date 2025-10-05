extends RigidBody3D

@export var planet: Node3D

func _physics_process(_delta):
	if planet:
		var dir = (planet.global_position - global_position).normalized()
		apply_central_force(dir * 50.0)  # fuerza de atracción hacia el planeta
