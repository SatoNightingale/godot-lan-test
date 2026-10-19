extends Node

var tooltip: Control
var touch_timer := Timer.new()
var _caller: Control
var _at_position: Vector2
var _item: Item

const drag_deadzone = 3


func _ready() -> void:
	add_child(touch_timer)
	touch_timer.one_shot = true


func request_tooltip(caller: Control, at_position: Vector2, item: Item):
	touch_timer.start(0.15)
	_caller = caller
	_at_position = at_position
	_item = item


func _input(event: InputEvent) -> void:
	if touch_timer.time_left > 0:
		if event is InputEventScreenDrag and \
		event.screen_relative.length() > drag_deadzone: # <=
			touch_timer.stop()
		if ((event is InputEventScreenTouch or event is InputEventMouseButton) and event.is_released()):
			touch_timer.stop()
			show_tooltip()
	if tooltip:
		if ((event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed) \
		or (event is InputEventScreenDrag and event.screen_relative.length() > drag_deadzone):
			erase_tooltip()


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
	var tooltip_pos = _caller.global_position + _at_position
	var view_end = get_viewport().get_visible_rect().size
	if tooltip_pos.x + tooltip.size.x > view_end.x:
		tooltip_pos.x = view_end.x - tooltip.size.x
	if tooltip_pos.y + tooltip.size.y > view_end.y:
		tooltip_pos.y = view_end.y - tooltip.size.y
	tooltip.position = tooltip_pos


func erase_tooltip():
	tooltip.get_parent().remove_child(tooltip)
	tooltip.queue_free()
	tooltip = null
