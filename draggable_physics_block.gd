extends RigidBody3D

const MAX_THROW_SPEED := 8.0
const AREA_MIN := Vector3(-10.35, 1.68, -10.35)
const AREA_MAX := Vector3(10.35, 22.0, 10.35)

var dragging := false
var drag_index := -1
var last_drag_usec := 0
var throw_velocity := Vector3.ZERO


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventSpatialTouch:
		if event.pressed and not dragging:
			dragging = true
			drag_index = event.index
			last_drag_usec = Time.get_ticks_usec()
			throw_velocity = Vector3.ZERO
			freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			freeze = true
		elif not event.pressed and dragging and event.index == drag_index:
			_release()
	elif event is InputEventSpatialDrag and dragging and event.index == drag_index:
		var now := Time.get_ticks_usec()
		var elapsed := maxf(float(now - last_drag_usec) / 1000000.0, 1.0 / 240.0)
		var bounded_position := _bounded_position(global_position + event.world_relative)
		throw_velocity = (
			((bounded_position - global_position) / elapsed).limit_length(MAX_THROW_SPEED)
		)
		global_position = bounded_position
		last_drag_usec = now


func _release() -> void:
	dragging = false
	drag_index = -1
	freeze = false
	sleeping = false
	linear_velocity = _bounded_velocity(global_position, throw_velocity)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if dragging:
		return
	var area := get_parent_node_3d()
	var local_position := area.to_local(state.transform.origin)
	var bounded_position := local_position.clamp(AREA_MIN, AREA_MAX)
	if not local_position.is_equal_approx(bounded_position):
		state.transform.origin = area.to_global(bounded_position)
		var local_velocity := area.global_basis.inverse() * state.linear_velocity
		if not is_equal_approx(local_position.x, bounded_position.x):
			local_velocity.x = 0.0
		if not is_equal_approx(local_position.y, bounded_position.y):
			local_velocity.y = 0.0
		if not is_equal_approx(local_position.z, bounded_position.z):
			local_velocity.z = 0.0
		state.linear_velocity = area.global_basis * local_velocity


func _bounded_position(world_position: Vector3) -> Vector3:
	var area := get_parent_node_3d()
	return area.to_global(area.to_local(world_position).clamp(AREA_MIN, AREA_MAX))


func _bounded_velocity(world_position: Vector3, world_velocity: Vector3) -> Vector3:
	var area := get_parent_node_3d()
	var position := area.to_local(world_position)
	var velocity := area.global_basis.inverse() * world_velocity
	if (position.x <= AREA_MIN.x and velocity.x < 0.0) or (
		position.x >= AREA_MAX.x and velocity.x > 0.0
	):
		velocity.x = 0.0
	if (position.y <= AREA_MIN.y and velocity.y < 0.0) or (
		position.y >= AREA_MAX.y and velocity.y > 0.0
	):
		velocity.y = 0.0
	if (position.z <= AREA_MIN.z and velocity.z < 0.0) or (
		position.z >= AREA_MAX.z and velocity.z > 0.0
	):
		velocity.z = 0.0
	return area.global_basis * velocity
