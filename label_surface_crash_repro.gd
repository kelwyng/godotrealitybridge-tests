extends Node3D

const SMALL_TEXT := "A"
const LARGE_TEXT := """ABCDEFGHIJKLMNOPQRSTUVWXYZ
αβγδεζηθικλμνξοπρστυφχψω
АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
日本語 中文 한국어 العربية हिन्दी
0123456789 !@#$%^&*()[]{}"""

@onready var crash_label: Label3D = $CrashViewport/CrashLabel
@onready var warning_label: Label3D = $Warning

var triggered := false


func _on_crash_button_input(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if (
		triggered
		or not event is InputEventSpatialTouch
		or not event.pressed
	):
		return
	triggered = true
	warning_label.text = "TRIGGERED — UNPATCHED GDRK SHOULD CRASH"
	call_deferred("_run_reproduction")


func _run_reproduction() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	for iteration in range(20):
		crash_label.text = LARGE_TEXT if iteration % 2 == 0 else SMALL_TEXT
		await get_tree().process_frame
	warning_label.text = "SURVIVED — SURFACE GUARD IS WORKING"
