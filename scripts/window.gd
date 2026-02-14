extends Node2D

var dragging_node: Control = null
var resizing_node: Control = null
var drag_offset = Vector2()
var window_restore_data = {} 

func _ready() -> void:
	await get_tree().process_frame
	for child in get_children():
		if child is Control:
			_setup_window_functionality(child)

func _setup_window_functionality(window: Control) -> void:
	var label = window.find_child("window_name", true, false)
	if label and label is Label:
		label.text = " " + window.name
	
	var exit_btn = window.find_child("Exit button", true, false)
	if exit_btn and exit_btn is Button:
		if not exit_btn.pressed.is_connected(window.hide):
			exit_btn.pressed.connect(window.hide)
		
	var max_btn = window.find_child("resize button", true, false)
	if max_btn and max_btn is Button:
		# Use callable to ensure we don't connect multiple times
		var toggle_call = _toggle_maximize.bind(window)
		if not max_btn.pressed.is_connected(toggle_call):
			max_btn.pressed.connect(toggle_call)

func _toggle_maximize(window: Control):
	var desktop_size = get_viewport_rect().size
	
	if window_restore_data.has(window):
		var data = window_restore_data[window]
		window.size = data["size"]
		window.global_position = data["pos"]
		window_restore_data.erase(window)
	else:
		window_restore_data[window] = {
			"pos": window.global_position,
			"size": window.size
		}
		window.global_position = Vector2.ZERO
		window.size = desktop_size
	
	window.move_to_front()

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
				drag_offset = Vector2(dragging_node.size.x / 2, 15) 
			
			dragging_node.global_position = event.global_position - drag_offset
			
		elif resizing_node:
			var mouse_pos = event.global_position
			var new_size = mouse_pos - resizing_node.global_position
			resizing_node.size = Vector2(max(300, new_size.x), max(200, new_size.y))

func _attempt_action() -> void:
	var mouse_pos = get_global_mouse_position()
	var children = get_children()
	
	for i in range(children.size() - 1, -1, -1):
		var child = children[i]
		if child is Control and child.visible:
			if not child.get_global_rect().has_point(mouse_pos):
				continue
				
			child.move_to_front()

			# FIX: If we are over a button, STOP and let the button's own signal work
			if _is_mouse_over_button(child, mouse_pos):
				# Do NOT set dragging_node. Let the button handle the click.
				return 

			# Check Drag Area (The bar)
			var title_bar = child.find_child("top bar", true, false)
			if title_bar and title_bar.get_global_rect().has_point(mouse_pos):
				dragging_node = child
				drag_offset = mouse_pos - child.global_position
				get_viewport().set_input_as_handled()
				return
				
			get_viewport().set_input_as_handled()
			return

func _is_mouse_over_button(window: Control, mouse_pos: Vector2) -> bool:
	var exit_btn = window.find_child("Exit button", true, false)
	var max_btn = window.find_child("resize button", true, false)
	
	# Check both buttons. If mouse is over either, we shouldn't start a window drag.
	if exit_btn and exit_btn.get_global_rect().has_point(mouse_pos):
		return true
	if max_btn and max_btn.get_global_rect().has_point(mouse_pos):
		return true
		
	return false
