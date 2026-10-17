extends Node

var tooltip: Control
var touch_timer := Timer.new()
var _caller: Control
var _at_position: Vector2
var _item: Item


func _ready() -> void:
	add_child(touch_timer)
	touch_timer.timeout.connect(show_tooltip)


func request_tooltip(caller: Control, at_position: Vector2, item: Item):
	touch_timer.start(0.5)
	_caller = caller
	_at_position = at_position
	_item = item


func create_tooltip(text: String) -> Control:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.custom_minimum_size = Vector2(200.0, 0.0)
	label.fit_content = true
	label.add_theme_font_size_override("normal_font_size", 12)
	label.add_theme_stylebox_override("normal",
		preload("res://game/ui/inventario/tooltip panel.tres"))
	label.append_text(text)
	#var content_width = label.get_content_width()
	#if content_width < 200:
		#label.custom_minimum_size = Vector2(content_width, 0.0)
	return label


func show_tooltip():
	if tooltip:
		erase_tooltip()
	tooltip = create_tooltip(_item.get_tooltip(_caller.tooltip_text))
	_caller.add_child(tooltip)
	tooltip.top_level = true
	tooltip.position = _caller.global_position + _at_position


func erase_tooltip():
	tooltip.get_parent().remove_child(tooltip)
	tooltip.queue_free()
	tooltip = null


func _input(event: InputEvent) -> void:
	if not touch_timer.is_stopped():
		if (event is InputEventScreenDrag and event.screen_relative.length() > 3) or \
		((event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed == false):
				touch_timer.stop()
	if tooltip:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.pressed:
				erase_tooltip()
