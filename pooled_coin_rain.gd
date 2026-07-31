extends Node3D

const POOL_SIZE := 48
const SPAWN_Y := 7.0
const PORTAL_Y := 1.55
const RECYCLE_Y := -3.5
const COIN_RADIUS := 0.35
const COIN_HALF_THICKNESS := 0.06
const COIN_COLLISION_LAYER := 4
const COUNT_STEP_SECONDS := 2.5
const COUNT_STEPS := [48, 8, 32, 16, 40, 4, 24]
const STREAM_SPACING_Y := 0.21875
const HIDDEN_TRANSFORM := Transform3D(Basis.IDENTITY, Vector3(0, -100, 0))
const SPAWN_LANES := [
	Vector2(0.5, 0.0),
	Vector2(0.25, 0.433),
	Vector2(-0.25, 0.433),
	Vector2(-0.5, 0.0),
	Vector2(-0.25, -0.433),
	Vector2(0.25, -0.433),
]

@onready var normal_visuals: MultiMeshInstance3D = $CoinVisuals
@onready var portal_visuals: MultiMeshInstance3D = $CoinPortalWorld/PortalCoinVisuals
@onready var normal_multimesh: MultiMesh = normal_visuals.multimesh
@onready var portal_multimesh: MultiMesh = portal_visuals.multimesh
@onready var count_label: Label3D = $CountLabel

var coin_shape := RID()
var coin_bodies: Array[RID] = []
var rng := RandomNumberGenerator.new()
var requested_visible_count := POOL_SIZE
var count_step := 0
var count_elapsed := 0.0


func _ready() -> void:
	rng.seed = 0xC01C1C
	coin_shape = PhysicsServer3D.convex_polygon_shape_create()
	var points := PackedVector3Array()
	for y in [-COIN_HALF_THICKNESS, COIN_HALF_THICKNESS]:
		for segment in range(8):
			var angle := TAU * float(segment) / 8.0
			points.append(Vector3(cos(angle) * COIN_RADIUS, y, sin(angle) * COIN_RADIUS))
	PhysicsServer3D.shape_set_data(coin_shape, points)

	for index in range(POOL_SIZE):
		var body := PhysicsServer3D.body_create()
		PhysicsServer3D.body_add_shape(body, coin_shape)
		PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_MASS, 0.08)
		PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_FRICTION, 0.45)
		PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_BOUNCE, 0.05)
		PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_LINEAR_DAMP, 0.05)
		PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_ANGULAR_DAMP, 0.4)
		PhysicsServer3D.body_set_collision_layer(body, COIN_COLLISION_LAYER)
		PhysicsServer3D.body_set_collision_mask(body, COIN_COLLISION_LAYER)
		PhysicsServer3D.body_set_space(body, get_world_3d().space)
		coin_bodies.append(body)
		_place_body(index, SPAWN_Y - float(index) * STREAM_SPACING_Y)
	_update_count_display()


func _physics_process(delta: float) -> void:
	count_elapsed += delta
	if count_elapsed >= COUNT_STEP_SECONDS:
		count_elapsed -= COUNT_STEP_SECONDS
		count_step = (count_step + 1) % COUNT_STEPS.size()
		_set_visible_count(COUNT_STEPS[count_step])

	for index in range(POOL_SIZE):
		var transform: Transform3D = PhysicsServer3D.body_get_state(
			coin_bodies[index], PhysicsServer3D.BODY_STATE_TRANSFORM
		)
		var local_y := to_local(transform.origin).y
		if local_y < RECYCLE_Y:
			_place_body(index, SPAWN_Y + rng.randf_range(0.0, 0.4))
			transform = PhysicsServer3D.body_get_state(
				coin_bodies[index], PhysicsServer3D.BODY_STATE_TRANSFORM
			)
			local_y = to_local(transform.origin).y
		_write_instance(index, transform, local_y)


func _set_visible_count(new_count: int) -> void:
	requested_visible_count = new_count
	normal_multimesh.visible_instance_count = requested_visible_count
	portal_multimesh.visible_instance_count = requested_visible_count
	_update_count_display()


func _update_count_display() -> void:
	count_label.text = "You currently should only see %d coins" % requested_visible_count


func _place_body(index: int, y: float) -> void:
	var lane: Vector2 = SPAWN_LANES[index % SPAWN_LANES.size()]
	var local_transform := Transform3D(
		Basis.from_euler(
			Vector3(
				rng.randf_range(0.0, TAU),
				rng.randf_range(0.0, TAU),
				rng.randf_range(0.0, TAU)
			)
		),
		Vector3(lane.x, y, lane.y)
	)
	var body := coin_bodies[index]
	PhysicsServer3D.body_set_state(
		body, PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform * local_transform
	)
	PhysicsServer3D.body_set_state(
		body, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3(0, -0.4, 0)
	)
	PhysicsServer3D.body_set_state(
		body,
		PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY,
		Vector3(
			rng.randf_range(-2.5, 2.5),
			rng.randf_range(-2.5, 2.5),
			rng.randf_range(-2.5, 2.5)
		)
	)
	PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_SLEEPING, false)


func _write_instance(index: int, world_transform: Transform3D, local_y: float) -> void:
	if local_y > PORTAL_Y:
		normal_multimesh.set_instance_transform(
			index, normal_visuals.global_transform.affine_inverse() * world_transform
		)
		portal_multimesh.set_instance_transform(index, HIDDEN_TRANSFORM)
	else:
		normal_multimesh.set_instance_transform(index, HIDDEN_TRANSFORM)
		portal_multimesh.set_instance_transform(
			index, portal_visuals.global_transform.affine_inverse() * world_transform
		)


func _exit_tree() -> void:
	for body in coin_bodies:
		PhysicsServer3D.free_rid(body)
	coin_bodies.clear()
	if coin_shape.is_valid():
		PhysicsServer3D.free_rid(coin_shape)
		coin_shape = RID()
