extends Node3D

@onready var display: Label3D = $Display

var running := false
var started_at_usec := 0
var stopped_elapsed_usec := 0


func _process(_delta: float) -> void:
	if running:
		_update_display(Time.get_ticks_usec() - started_at_usec)


func _on_start_activated() -> void:
	started_at_usec = Time.get_ticks_usec()
	stopped_elapsed_usec = 0
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
