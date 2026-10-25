class_name GrenadeProjectile
extends RigidBody3D

var grenade_type: String = "he_grenade"
var thrower: Node = null
var fuse_timer: float = 2.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	contact_monitor = true
	max_contacts_reported = 2

	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.12
	col.shape = sph
	add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.06
	cyl.height = 0.16
	mesh_inst.mesh = cyl
	var mat := StandardMaterial3D.new()
	if grenade_type == "he_grenade":
		mat.albedo_color = Color(0.25, 0.45, 0.22)
	elif grenade_type == "flashbang":
		mat.albedo_color = Color(0.85, 0.85, 0.90)
	else:
		mat.albedo_color = Color(0.45, 0.50, 0.48)
	mesh_inst.material_override = mat
	add_child(mesh_inst)

func _physics_process(delta: float) -> void:
	fuse_timer -= delta
	if fuse_timer <= 0.0:
		_detonate()

func _detonate() -> void:
	var pos := global_position
	match grenade_type:
		"he_grenade":
			SfxManager.play_3d("explosion", pos, 60.0)
			GameManager.spawn_explosion_vfx(pos, Color(1.0, 0.55, 0.15), 4.5)
			for actor in GameManager.actors:
				if not is_instance_valid(actor) or not actor.is_alive:
					continue
				var d: float = actor.global_position.distance_to(pos)
				if d <= 10.5:
					var dmg: float = 98.0 * (1.0 - (d / 10.5))
					actor.apply_damage(dmg, 0.65, thrower, "HE Grenade", false)
		"flashbang":
			SfxManager.play_3d("flash", pos, 55.0)
			GameManager.spawn_explosion_vfx(pos, Color(1.0, 1.0, 1.0), 2.5)
			for actor in GameManager.actors:
				if not is_instance_valid(actor) or not actor.is_alive:
					continue
				var eye_pos: Vector3 = actor.get_eye_position()
				var dist: float = eye_pos.distance_to(pos)
				if dist <= 24.0 and GameManager.has_clear_line_of_sight(eye_pos, pos):
					var dir_to_flash: Vector3 = (pos - eye_pos).normalized()
					var look_dir: Vector3 = actor.get_look_direction()
					var dot: float = look_dir.dot(dir_to_flash)
					var intensity: float = clampf((dot + 0.35) * (1.0 - dist / 26.0), 0.15, 1.0)
					actor.apply_flashbang(intensity * 3.8)
		"smoke_grenade":
			SfxManager.play_3d("silenced", pos, 35.0)
			GameManager.spawn_smoke_cloud(pos)

	queue_free()