extends Node3D

const GLYPH_BATCHES := [
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	"abcdefghijklmnopqrstuvwxyz",
	"0123456789",
	"!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~",
]
const FONT_SIZES := [181, 227, 269, 317]

@onready var target_label: Label3D = $ReproViewport/TargetLabel
@onready var status_label: Label3D = $Status
@onready var heartbeat: Node3D = $Heartbeat/HandPivot

var triggered := false


func _process(delta: float) -> void:
	heartbeat.rotation.z -= delta * 4.0


func _on_trigger_button_input(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if triggered or not event is InputEventSpatialTouch or not event.pressed:
		return
	triggered = true
	status_label.text = "TRIGGERED: WATCH THE CYAN HAND"
	call_deferred("_run_reproduction")


func _run_reproduction() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	for attempt in range(32):
		var variant := attempt % GLYPH_BATCHES.size()
		target_label.font_size = FONT_SIZES[variant]
		target_label.text = GLYPH_BATCHES[variant] + " #%02d" % attempt
		await get_tree().process_frame
	status_label.text = "SURVIVED: FONT ATLAS RETRIES WORK"
