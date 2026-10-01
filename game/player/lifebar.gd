extends TextureProgressBar

@onready var offset = position

func _process(_delta: float) -> void:
	position = offset + get_parent().position
