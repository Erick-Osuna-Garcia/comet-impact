extends RigidBody3D

@onready var procedural_mesh = $MeshInstance3D
@export var meteor_group_name: String = "meteors"

var attractable_meteors: Array = []

func _ready():
	contact_monitor = true
	max_contacts_reported = 10
	
	custom_integrator = true
	
	attractable_meteors = get_tree().get_nodes_in_group(meteor_group_name)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	for meteor in attractable_meteors:
		if is_instance_valid(meteor) and meteor is RigidBody3D:
			var dir = (global_position - meteor.global_position).normalized()
			meteor.apply_central_force(dir * 50.0)

	if state.get_contact_count() > 0:
		for i in range(state.get_contact_count()):
			var collider_node = state.get_contact_collider_object(i)
			
			if is_instance_valid(collider_node) and collider_node.is_in_group(meteor_group_name):
				var contact_point_global = state.get_contact_local_position(i)
				var contact_point_local = to_local(contact_point_global)
				
				var collision_impulse = state.get_contact_impulse(i)
				var force_magnitude = collision_impulse.length() * collider_node.mass
				
				if procedural_mesh:
					procedural_mesh.deform_on_impact(contact_point_local, force_magnitude)
