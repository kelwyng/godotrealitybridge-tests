extends Node3D

const GLYPH_POOL := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZΩЖ中₹✓★→∑∞¿¡§¶æøß"
const GLYPH_INTERVAL_USEC := 1_000_000

@onready var display: Label3D = $Display
@onready var growing_display: Label3D = $GrowingDisplay

var running := false
var started_at_usec := 0
var stopped_elapsed_usec := 0
var next_glyph_at_usec := 0
var growing_text := ""
var remaining_glyphs := Array(GLYPH_POOL.split(""))
var rng := RandomNumberGenerator.new()


func _process(_delta: float) -> void:
	if running:
		var now := Time.get_ticks_usec()
		_update_display(now - started_at_usec)
		while now >= next_glyph_at_usec:
			if remaining_glyphs.is_empty():
				remaining_glyphs = Array(GLYPH_POOL.split(""))
			growing_text += remaining_glyphs.pop_at(rng.randi_range(0, remaining_glyphs.size() - 1))
			growing_display.text = "Glyphs: " + growing_text
			next_glyph_at_usec += GLYPH_INTERVAL_USEC


func _on_start_activated() -> void:
	started_at_usec = Time.get_ticks_usec()
	stopped_elapsed_usec = 0
	next_glyph_at_usec = started_at_usec + GLYPH_INTERVAL_USEC
	growing_text = ""
	remaining_glyphs = Array(GLYPH_POOL.split(""))
	rng.seed = 0x1ABE13D
	growing_display.text = "Glyphs:"
	running = true
	_update_display(0)


func _on_stop_activated() -> void:
	if running:
		stopped_elapsed_usec = Time.get_ticks_usec() - started_at_usec
		running = false
	_update_display(stopped_elapsed_usec)


func _on_top_button_input(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventScreenDrag or not event.is_pressed():
		return
	if running:
		_on_stop_activated()
	else:
		_on_start_activated()


func _update_display(elapsed_usec: int) -> void:
	var total_milliseconds := int(elapsed_usec / 1000.0)
	var minutes := int(total_milliseconds / 60000.0)
	var seconds := int(total_milliseconds / 1000.0) % 60
	var milliseconds := total_milliseconds % 1000
	display.text = "%d:%02d.%03d" % [minutes, seconds, milliseconds]
