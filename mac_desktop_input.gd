extends Node

const INTERACTION_MASK := 2
const MOVE_SPEED := 1.2
const LOOK_SPEED := 0.003
const PAN_SPEED := 0.0025
const ZOOM_STEP := 0.18

var camera: Camera3D
var starting_transform: Transform3D
var touch_target: CollisionObject3D
var touch_plane: Plane
var touch_world_position := Vector3.ZERO
var touch_normal := Vector3.ZERO
var touch_shape := 0


func _ready() -> void:
	if (
		not OS.is_debug_build()
		or not OS.has_feature("macos")
		or DisplayServer.get_name() == "headless"
	):
		set_process(false)
		set_process_input(false)
		return
	camera = get_parent().get_node("RealityVolumeCamera3D/PreviewCamera") as Camera3D
	starting_transform = camera.transform
	camera.make_current()
	get_viewport().physics_object_picking = false
	print(
		"Mac controls: left drag touch, right drag look, middle drag pan, "
		+ "wheel/WASD/QE move, Shift fast, F reset camera"
	)


func _process(delta: float) -> void:
	var motion := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		motion -= camera.global_basis.z
	if Input.is_key_pressed(KEY_S):
		motion += camera.global_basis.z
	if Input.is_key_pressed(KEY_A):
		motion -= camera.global_basis.x
	if Input.is_key_pressed(KEY_D):
		motion += camera.global_basis.x
	if Input.is_key_pressed(KEY_Q):
		motion -= Vector3.UP
	if Input.is_key_pressed(KEY_E):
		motion += Vector3.UP
	if not motion.is_zero_approx():
		var speed := MOVE_SPEED * (3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
		camera.global_position += motion.normalized() * speed * delta


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		camera.transform = starting_transform
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_begin_touch(mouse_button.position)
			elif touch_target:
				_emit_touch(mouse_button.position, false)
				touch_target = null
		elif (
			mouse_button.pressed
			and mouse_button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
		):
			var direction := 1.0 if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			camera.global_position -= camera.global_basis.z * ZOOM_STEP * direction
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if mouse_motion.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			camera.rotation.y -= mouse_motion.relative.x * LOOK_SPEED
			camera.rotation.x = clampf(
				camera.rotation.x - mouse_motion.relative.y * LOOK_SPEED, -1.5, 1.5
			)
		elif mouse_motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			camera.global_position += (
				-camera.global_basis.x * mouse_motion.relative.x
				+ camera.global_basis.y * mouse_motion.relative.y
			) * PAN_SPEED
		elif touch_target and mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_emit_drag(mouse_motion)
		get_viewport().set_input_as_handled()


func _begin_touch(screen_position: Vector2) -> void:
	var hit := _raycast_interactable(screen_position)
	if hit.is_empty():
		return
	touch_target = hit["collider"] as CollisionObject3D
	touch_world_position = hit["position"]
	touch_normal = hit["normal"]
	touch_shape = hit["shape"]
	touch_plane = Plane(camera.global_basis.z, touch_world_position)
	_emit_touch(screen_position, true)


func _emit_touch(screen_position: Vector2, pressed: bool) -> void:
	var event := InputEventSpatialTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = screen_position
	event.world_position = touch_world_position
	event.has_selection_ray = true
	event.selection_ray_origin = camera.project_ray_origin(screen_position)
	event.selection_ray_direction = camera.project_ray_normal(screen_position)
	touch_target.emit_signal(
		"input_event", camera, event, touch_world_position, touch_normal, touch_shape
	)


func _emit_drag(mouse_motion: InputEventMouseMotion) -> void:
	var next_world_position: Vector3 = touch_plane.intersects_ray(
		camera.project_ray_origin(mouse_motion.position),
		camera.project_ray_normal(mouse_motion.position)
	)
	var event := InputEventSpatialDrag.new()
	event.index = 0
	event.position = mouse_motion.position
	event.relative = mouse_motion.relative
	event.screen_relative = mouse_motion.screen_relative
	event.world_position = next_world_position
	event.world_relative = next_world_position - touch_world_position
	event.has_selection_ray = true
	event.selection_ray_origin = camera.project_ray_origin(mouse_motion.position)
	event.selection_ray_direction = camera.project_ray_normal(mouse_motion.position)
	touch_world_position = next_world_position
	touch_target.emit_signal(
		"input_event", camera, event, touch_world_position, touch_normal, touch_shape
	)


func _raycast_interactable(screen_position: Vector2) -> Dictionary:
	var origin := camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(
		origin, origin + camera.project_ray_normal(screen_position) * 100.0, INTERACTION_MASK
	)
	var excluded: Array[RID] = []
	for _candidate in range(32):
		query.exclude = excluded
		var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return {}
		var collider := hit["collider"] as CollisionObject3D
		if (
			collider
			and collider.input_ray_pickable
			and collider.is_visible_in_tree()
			and collider.can_process()
		):
			return hit
		excluded.append(hit["rid"])
	return {}
