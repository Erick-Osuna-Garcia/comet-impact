extends Node3D

# Referencias (arrastra en el editor)
@export_node_path("$Planets/PlanetTerrestrial") var terrain_node_path
@export_node_path("$Wather") var water_node_path
@export_node_path("$Environment/WorldEnvironment") var world_env_path
@export_node_path("$ParticlesRoot") var particles_root_path

@export var biome_map : ImageTexture # imagen que codifica biomas (RGB -> tipo)
@export var heightmap_image_texture : ImageTexture # texture que controla displacement
@export var impact_map_texture : ImageTexture # texture donde "pintamos" impulsos para agua

# Thresholds (ajustables)
@export var energy_threshold_crater := 1e6
@export var energy_threshold_earthquake := 5e7
@export var energy_threshold_massive := 5e8

# radios y escalas
@export var crater_base_radius := 8.0
@export var crater_strength := 0.5
@export var tsunami_influence_radius := 200.0

# internal
var heightmap_image : Image
var impact_map_image : Image
var world_env : WorldEnvironment

func _ready():
	# convertir textures en Image editables
	if heightmap_image_texture:
		heightmap_image = heightmap_image_texture.get_image().duplicate() # mutable
	if impact_map_texture:
		impact_map_image = impact_map_texture.get_image().duplicate()
	if world_env_path:
		world_env = get_node(world_env_path) as WorldEnvironment

	# Asegúrate que imágenes sean mutables y en formato adecuado (F32 o RGBA8 para painting)
	if heightmap_image:
		heightmap_image.lock()
	if impact_map_image:
		impact_map_image.lock()

# llamada desde meteorito en colisión
# pos: Vector3 world, mass: float, velocity: Vector3, radius_meteor: float, angle: float
func apply_impact(pos: Vector3, mass: float, velocity: Vector3, radius_meteor: float, angle: float) -> void:
	var speed = velocity.length()
	var energy = 0.5 * mass * speed * speed  # energía cinética (J) — escala como necesites
	print("Impact energy: ", energy)

	# determinar tipo de superficie usando biome_map (mapa UV/world->UV simplificado)
	var biome = sample_biome_at_world(pos)
	var is_water = biome == "ocean"
	var near_coast = biome == "coast"
	var is_on_land = biome == "land"

	# escala radius por energía y tamaño
	var crater_radius = crater_base_radius * (1.0 + log(energy + 1.0) * 0.05) * clamp(radius_meteor, 0.3, 5.0)

	# 1) crater si está en tierra
	if is_on_land or near_coast:
		_create_crater(pos, crater_radius, energy)

	# 2) tsunami si en agua o cerca de costa y energía suficiente
	if is_water or near_coast:
		_create_tsunami_impulse(pos, energy, crater_radius)

	# 3) terremoto si energía >= threshold y en tierra
	if is_on_land and energy >= energy_threshold_earthquake:
		_trigger_earthquake(pos, energy)

	# 4) capa de polvo global si energía >= massive threshold
	if energy >= energy_threshold_massive:
		_trigger_global_dust(energy)

	# efectos encadenados (ejemplo: siempre ejecutar partículas y camera shake según magnitud)
	_spawn_ejecta_particles(pos, energy, crater_radius)
	_camera_shake(energy)

# ----------------------
# Helpers
# ----------------------
func sample_biome_at_world(world_pos: Vector3) -> String:
	# Necesitas mapear world_pos -> uv del biome_map. 
	# Aquí pongo un ejemplo simple si terrain es un plane que cubre XZ [-size/2, size/2]
	var terrain = get_node_or_null(terrain_node_path)
	if not terrain or not biome_map:
		return "land"
	# supón que terrain tiene scale en XZ que define cobertura
	var t = terrain as MeshInstance3D
	var size_x = 1000.0  # adapta a tu mundo
	var size_z = 1000.0
	var u = (world_pos.x / size_x) + 0.5
	var v = (world_pos.z / size_z) + 0.5
	u = clamp(u, 0.0, 1.0)
	v = clamp(v, 0.0, 1.0)
	var img = biome_map.get_image()
	var col = img.get_pixelv(Vector2(u * (img.get_width()-1), v * (img.get_height()-1)))
	# mapear color a biome (ejemplo: azul = oceano, verde = tierra, amarillo = costa)
	if col.r > 0.5 and col.g < 0.3 and col.b > 0.6:
		return "ocean"
	if col.r > 0.8 and col.g > 0.7 and col.b < 0.4:
		return "coast"
	return "land"

# ----------------------
# Crear crater (editar heightmap Image)
# ----------------------
func _create_crater(world_pos:Vector3, radius:float, energy:float) -> void:
	if not heightmap_image:
		return
	# convert world_pos a coords en la imagen del heightmap (similar a sample_biome)
	var img_w = heightmap_image.get_width()
	var img_h = heightmap_image.get_height()
	# suponemos coverage igual que en sample_biome
	var size_x = 1000.0
	var size_z = 1000.0
	var u = clamp((world_pos.x / size_x) + 0.5, 0.0, 1.0)
	var v = clamp((world_pos.z / size_z) + 0.5, 0.0, 1.0)
	var cx = int(u * (img_w - 1))
	var cy = int(v * (img_h - 1))
	var pixel_radius = int(radius / max(size_x / img_w, size_z / img_h))
	# gaussian depression
	var strength = clamp(energy / 1e7, 0.1, 10.0) * crater_strength
	for yy in range(max(0, cy - pixel_radius), min(img_h, cy + pixel_radius)):
		for xx in range(max(0, cx - pixel_radius), min(img_w, cx + pixel_radius)):
			var dx = float(xx - cx)
			var dy = float(yy - cy)
			var dist = sqrt(dx*dx + dy*dy)
			if dist <= pixel_radius:
				var t = dist / float(pixel_radius)
				# gauss-like falloff
				var falloff = exp(-t * t * 4.0)
				# leer valor actual (suponemos grayscale almacenado en r)
				var old = heightmap_image.get_pixel(xx, yy).r
				# restar (deformar hacia abajo)
				var newh = clamp(old - falloff * strength * 0.01, 0.0, 1.0)
				heightmap_image.set_pixel(xx, yy, Color(newh, newh, newh, 1.0))
	# subir la textura modificada al GPU
	var tex := ImageTexture.create_from_image(heightmap_image, 0)
	# asigna al material del terrain (asume que material espera 'heightmap')
	var terrain = get_node_or_null(terrain_node_path)
	if terrain and terrain.get_active_material(0):
		var mat = terrain.get_active_material(0)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("heightmap", tex)

# ----------------------
# Tsunami: pintar impulso en impact_map (usado por shader de agua)
# ----------------------
func _create_tsunami_impulse(world_pos:Vector3, energy:float, radius:float) -> void:
	if not impact_map_image:
		return
	var img_w = impact_map_image.get_width()
	var img_h = impact_map_image.get_height()
	var size_x = 1000.0
	var size_z = 1000.0
	var u = clamp((world_pos.x / size_x) + 0.5, 0.0, 1.0)
	var v = clamp((world_pos.z / size_z) + 0.5, 0.0, 1.0)
	var cx = int(u * (img_w - 1))
	var cy = int(v * (img_h - 1))
	var pixel_radius = int(radius * 2.0)
	var amplitude = clamp(energy / 1e7, 0.05, 5.0)
	for yy in range(max(0, cy - pixel_radius), min(img_h, cy + pixel_radius)):
		for xx in range(max(0, cx - pixel_radius), min(img_w, cx + pixel_radius)):
			var dx = float(xx - cx)
			var dy = float(yy - cy)
			var dist = sqrt(dx*dx + dy*dy)
			if dist <= pixel_radius:
				var t = dist / float(pixel_radius)
				var falloff = (1.0 - t) * amplitude
				# escribir en canal R como impulso inicial; G/B pueden usarse para tiempo
				var old = impact_map_image.get_pixel(xx, yy)
				var newr = clamp(old.r + falloff, 0.0, 10.0)
				impact_map_image.set_pixel(xx, yy, Color(newr, 0.0, 0.0, 1.0))
	# actualizar textura en GPU
	var tex := ImageTexture.create_from_image(impact_map_image, 0)
	var water = get_node_or_null(water_node_path)
	if water and water.get_active_material(0):
		var mat = water.get_active_material(0)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("impact_map", tex)

# ----------------------
# Terremoto: cámara + partículas + temblores
# ----------------------
func _trigger_earthquake(epicenter:Vector3, energy:float) -> void:
	# vibración global — mueve la cámara y el root temporalmente
	var cam = get_viewport().get_camera_3d()
	if cam:
		var shake_amount = clamp(log(energy + 1.0) * 0.02, 0.05, 5.0)
		# simple camera shake: tween translation
		var tween = Tween.new()
		add_child(tween)
		var orig = cam.transform
		tween.tween_property(cam, "translation", cam.translation + Vector3(randf()-0.5, randf()-0.5, randf()-0.5) * shake_amount, 0.4).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(Callable(self, "_restore_camera"), [cam, orig])
		tween.play()
	# particulas de polvo
	_spawn_quake_particles(epicenter, energy)

func _restore_camera(cam, orig):
	cam.transform = orig

# ----------------------
# Polvo global: modificar WorldEnvironment.fog/color
# ----------------------
func _trigger_global_dust(energy:float) -> void:
	if not world_env:
		return
	var env = world_env.environment
	if not env:
		return
	var target_density = clamp(log(energy) * 0.02, 0.1, 1.0)
	# animate with Tween
	var tween = Tween.new()
	add_child(tween)
	var start = env.fog_density
	tween.tween_property(env, "fog_density", target_density, 5.0)
	tween.tween_property(env, "fog_color", Color(0.15, 0.12, 0.1), 5.0)
	tween.play()

# ----------------------
# Partículas y cámara
# ----------------------
func _spawn_ejecta_particles(pos:Vector3, energy:float, radius:float) -> void:
	# instanciar un CPUParticles3D preconfigurado, o configurar al vuelo
	var part = CPUParticles3D.new()
	part.amount = int(clamp(energy / 1e6, 50, 2000))
	part.lifetime = clamp(log(energy + 1.0)*0.4, 0.5, 6.0)
	part.emitting = true
	part.one_shot = true
	part.global_transform.origin = pos + Vector3(0, 5, 0)
	get_node(particles_root_path).add_child(part)
	# config basica de direction, speed, etc
	part.initial_velocity = clamp(log(energy + 1.0) * 2.0, 5, 60)
	part.direction = Vector3(0,1,0)
	# material simple
	var mat = ParticlesMaterial.new()
	mat.gravity = Vector3(0,-9.8,0)
	mat.velocity_random = 0.6
	mat.angle = 1.2
	part.process_material = mat

func _spawn_quake_particles(pos:Vector3, energy:float) -> void:
	# polvo de área (menor)
	_spawn_ejecta_particles(pos, energy * 0.3, 1.0)

func _camera_shake(energy:float) -> void:
	# adicional: sacudida local a cámara principal
	# implementado por _trigger_earthquake y aquí como fallback
	pass
