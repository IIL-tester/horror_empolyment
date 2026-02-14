extends Node2D

var dragging_node = null
var resizing_node = null
var drag_offset = Vector2()
var window_restore_data = {} 

func _ready() -> void:
	for child in get_children():
		if child is Control:
			_setup_window_functionality(child)

func _setup_window_functionality(window: Control) -> void:
	# PATH UPDATE: Added "top/" prefix to match your new scene tree
	var label = window.get_node_or_null("top/top bar/top bar/window_name")
	if label and label is Label:
		label.text = " " + window.name
	
	var exit_btn = window.get_node_or_null("top/top bar/edge buttons/Exit button")
	if exit_btn and exit_btn is Button:
		exit_btn.pressed.connect(func(): window.hide())
		
	var max_btn = window.get_node_or_null("top/top bar/edge buttons/resize button")
	if max_btn and max_btn is Button:
		max_btn.pressed.connect(func(): _toggle_maximize(window))

func _toggle_maximize(window: Control):
	var desktop_size = get_viewport_rect().size
	
	if window_restore_data.has(window):
		# RESTORE
		var data = window_restore_data[window]
		window.size = data["size"]
		window.global_position = data["pos"]
		window_restore_data.erase(window)
	else:
		# MAXIMIZE
		window_restore_data[window] = {
			"pos": window.global_position,
			"size": window.size
		}
		window.global_position = Vector2.ZERO
		window.size = desktop_size
	
	move_child(window, -1)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_attempt_action()
			else:
				dragging_node = null
				resizing_node = null

	if event is InputEventMouseMotion:
		if dragging_node:
			if window_restore_data.has(dragging_node):
				_toggle_maximize(dragging_node)
				drag_offset = Vector2(dragging_node.size.x / 2, 10) 
			
			dragging_node.global_position = get_global_mouse_position() - drag_offset
			
		elif resizing_node:
			var new_size = get_global_mouse_position() - resizing_node.global_position
			resizing_node.size = Vector2(max(200, new_size.x), max(150, new_size.y))

func _attempt_action() -> void:
	var mouse_pos = get_global_mouse_position()
	var children = get_children()
	children.reverse()
	
	for child in children:
		if child is Control and child.visible:
			if not child.get_global_rect().has_point(mouse_pos):
				continue
				
			move_child(child, -1)

			if _is_mouse_over_button(child, mouse_pos):
				return 

			# PATH UPDATE: Added "top/" prefix
			var resize_btn = child.get_node_or_null("top/top bar/edge buttons/resize button")
			if resize_btn and resize_btn.get_global_rect().has_point(mouse_pos):
				resizing_node = child
				get_viewport().set_input_as_handled()
				return 

			# PATH UPDATE: Added "top/" prefix (The draggable title bar area)
			var title_bar = child.get_node_or_null("top/top bar")
			if title_bar and title_bar.get_global_rect().has_point(mouse_pos):
				dragging_node = child
				drag_offset = mouse_pos - child.global_position
				get_viewport().set_input_as_handled()
				return
				
			get_viewport().set_input_as_handled()
			return

func _is_mouse_over_button(window: Control, mouse_pos: Vector2) -> bool:
	# PATH UPDATE: Added "top/" prefix
	var exit_btn = window.get_node_or_null("top/top bar/edge buttons/Exit button")
	var max_btn = window.get_node_or_null("top/top bar/edge buttons/resize button")
	
	if exit_btn and exit_btn.get_global_rect().has_point(mouse_pos):
		return true
	if max_btn and max_btn.get_global_rect().has_point(mouse_pos):
		return true
	return false
