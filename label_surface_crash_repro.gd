extends Node3D

const SMALL_TEXT := "A"
const LARGE_TEXT := """ABCDEFGHIJKLMNOPQRSTUVWXYZ
αβγδεζηθικλμνξοπρστυφχψω
АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
日本語 中文 한국어 العربية हिन्दी
0123456789 !@#$%^&*()[]{}"""
const STRESS_FONT_SIZES := [257, 389, 521, 769]
const STRESS_OUTLINE_SIZES := [8, 24, 48, 72]

@onready var crash_label: Label3D = $CrashLabel
@onready var crash_viewport: SubViewport = $CrashViewport
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
	_add_capture_preview()
	warning_label.text = "TRIGGERED — UNPATCHED GDRK SHOULD CRASH"
	call_deferred("_run_reproduction")


func _add_capture_preview() -> void:
	if $CrashButton.has_node("CapturePreview"):
		return
	var preview := Sprite3D.new()
	preview.name = "CapturePreview"
	preview.transform = Transform3D(
		Basis(Vector3.RIGHT, PI / 2.0),
		Vector3(0, 0.26, 0)
	)
	preview.pixel_size = 0.0012
	preview.texture = crash_viewport.get_texture()
	$CrashButton.add_child(preview)


func _run_reproduction() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var iteration := 0
	var stop_time := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < stop_time:
		crash_label.font_size = STRESS_FONT_SIZES[iteration % STRESS_FONT_SIZES.size()]
		crash_label.outline_size = STRESS_OUTLINE_SIZES[iteration % STRESS_OUTLINE_SIZES.size()]
		crash_label.text = LARGE_TEXT
		await _capture_frame()
		crash_label.text = SMALL_TEXT
		await _capture_frame()
		iteration += 1
	warning_label.text = "SURVIVED 1-SECOND SURFACE-RACE TEST"
	triggered = false


func _capture_frame() -> void:
	crash_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var capture_image := crash_viewport.get_texture().get_image()
	if capture_image == null or capture_image.is_empty():
		warning_label.text = "CAPTURE TEXTURE READBACK FAILED"
