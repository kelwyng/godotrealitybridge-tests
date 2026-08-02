extends Node3D

const NOTO_EMOJI_PATH := "res://fonts/NotoColorEmoji.ttf"

var added := false


func _on_add_emoji_input(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if added or not event is InputEventSpatialTouch or not event.pressed:
		return
	added = true
	$AddEmojiButton/Label.text = "LOADING..."
	call_deferred("_add_emoji")


func _add_emoji() -> void:
	var emoji_font := load(NOTO_EMOJI_PATH) as Font
	if emoji_font == null:
		$AddEmojiButton/Label.text = "LOAD FAILED"
		added = false
		return

	var emoji := Label3D.new()
	emoji.name = "ColorEmoji"
	emoji.position = Vector3(-4.1, -1.5, 4)
	emoji.text = "🌈"
	emoji.font = emoji_font
	emoji.font_size = 96
	emoji.pixel_size = 0.006
	add_child(emoji)
	$AddEmojiButton.visible = false
