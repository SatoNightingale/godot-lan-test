extends TextureProgressBar

@export var offset = Vector2(-18, -30)

func _process(_delta: float) -> void:
	position = offset + get_parent().position
