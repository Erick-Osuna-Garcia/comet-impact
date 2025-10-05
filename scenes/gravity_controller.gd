extends Node3D

@export var planet_path: NodePath
@export var gravity_strength: float = 4000.0
@export var max_gravity: float = 180.0
@export var stop_distance: float = 0.55   # radio planeta (0.5) + margen

var _planet: Node3D

func _ready():
	_planet = planet_path.is_empty() if null else get_node_or_null(planet_path)

func _physics_process(_delta: float) -> void:
	if _planet == null:
		return
	var planet_pos = _planet.global_position
	var meteors = get_tree().get_nodes_in_group("meteors")

	for m in meteors:
		if not is_instance_valid(m): continue
		if not (m is RigidBody3D): continue
		var diff = planet_pos - m.global_position
		var dist = diff.length()
		if dist < 0.001 or dist < stop_distance:
			continue
		var dir = diff / dist
		var force = gravity_strength / max(dist * dist, 0.01)
		force = min(force, max_gravity)
		m.apply_central_force(dir * force)
