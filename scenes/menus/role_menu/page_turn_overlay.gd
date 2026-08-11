extends TextureRect
class_name PageTurnOverlay

@export var animation_duration: float = 0.5

func play(front_texture: Texture2D, back_texture: Texture2D, direction: int) -> void:
	visible = true
	texture = front_texture
	material.set_shader_parameter("back_texture", back_texture)
	material.set_shader_parameter("direction", direction)
	material.set_shader_parameter("progress", 0.0)

	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, animation_duration)
	await tween.finished

	visible = false

func _set_progress(value: float) -> void:
	material.set_shader_parameter("progress", value)
