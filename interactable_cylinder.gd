extends StaticBody3D

signal activated


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventScreenTouch and event.pressed:
		$AnimationPlayer.stop()
		$AnimationPlayer.play("bounce")
		activated.emit()
