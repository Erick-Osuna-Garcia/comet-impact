# Meteorite.gd
extends RigidBody3D

func _ready():
	# Ajustar gravedad o darle un impulso inicial hacia el planeta
	apply_impulse(Vector3.ZERO, Vector3(0, -5, 0)) # ejemplo, hacia abajo
