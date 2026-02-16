extends Control

@onready var alerts: Label = $Alerts/Alerts
@onready var time_label: Label = $task_bar/MarginContainer/time
@onready var background: ColorRect = $background
@onready var margin_container: MarginContainer = $MarginContainer
@onready var app_grid: GridContainer = $MarginContainer/AppGrid
@onready var windows_folder: Node2D = $window 

@onready var quote: Label = $VBoxContainer/quote
@onready var dark_screen: ColorRect = $dark_screen
@onready var restart: Button = $VBoxContainer/restart

# --- Time Variables ---
var current_day: int = 1
var hour: int = 9
var minute: int = 0
var time_accumulator: float = 0.0

var normal_speed: float = 3.0
var fast_speed: float = 10.0
var current_time_speed: float = normal_speed
var is_fast_forwarding: bool = false

const PADDING = 20
const ICON_SPACING = 15
const ICON_SIZE = Vector2(64, 80)

func _ready() -> void:
	alerts.text = ""
	for window in windows_folder.get_children():
		window.hide()
	setup_desktop_environment()
	update_time_display()
	show_alert("SYSTEM ONLINE - WELCOME, USER")

func _process(delta: float) -> void:
	_handle_clock(delta)

func _handle_clock(delta: float) -> void:
	time_accumulator += delta * current_time_speed
	
	# FIX: Use a WHILE loop to process all minutes accumulated in one frame
	while time_accumulator >= 1.0:
		time_accumulator -= 1.0
		minute += 1
		
		if minute >= 60:
			minute = 0
			hour += 1
			
			# Check for Midnight during Fast Forward
			if is_fast_forwarding and hour >= 24:
				_finalize_new_day()
				return # Exit the loop immediately
				
			if hour >= 24: 
				hour = 0
				
	update_time_display()

func update_time_display() -> void:
	var time_string = "%02d:%02d" % [hour, minute]
	var day_string = " - DAY " + str(current_day)
	time_label.text = time_string + day_string

func show_alert(message: String, duration: float = 4.0) -> void:
	alerts.text = "ALERT: " + message
	await get_tree().create_timer(duration).timeout
	if alerts.text == "ALERT: " + message:
		alerts.text = ""

func trigger_time_skip() -> void:
	is_fast_forwarding = true
	current_time_speed = fast_speed
	show_alert("SHIFT COMPLETE - SYNCHRONIZING...")

func _finalize_new_day() -> void:
	is_fast_forwarding = false
	current_time_speed = normal_speed
	hour = 9
	minute = 0
	current_day += 1
	update_time_display()
	
	show_alert("NEW SHIFT READY - DAY " + str(current_day))
	
	# Recursively find the work app reset function in all children
	_find_and_reset_work_apps(windows_folder)

# Better way to ensure the reset call finds the script
func _find_and_reset_work_apps(node: Node):
	if node.has_method("reset_for_new_shift"):
		node.reset_for_new_shift()
	for child in node.get_children():
		_find_and_reset_work_apps(child)

# --- Desktop Layout (Untouched) ---
func setup_desktop_environment() -> void:
	margin_container.add_theme_constant_override("margin_top", PADDING)
	margin_container.add_theme_constant_override("margin_left", PADDING)
	margin_container.add_theme_constant_override("margin_bottom", PADDING)
	margin_container.add_theme_constant_override("margin_right", PADDING)
	app_grid.add_theme_constant_override("h_separation", ICON_SPACING)
	app_grid.add_theme_constant_override("v_separation", ICON_SPACING)
	for child in app_grid.get_children():
		if child is Button: style_as_retro_app(child)

func style_as_retro_app(app: Button) -> void:
	app.custom_minimum_size = ICON_SIZE
	app.vertical_icon_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_TOP
	app.icon_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	app.expand_icon = true
	app.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	app.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	app.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.add_theme_font_size_override("font_size", 11)
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1, 1, 1, 0.1)
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.2, 0.5, 1.0, 0.4)
	app.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	app.add_theme_stylebox_override("hover", hover_style)
	app.add_theme_stylebox_override("pressed", pressed_style)
	app.add_theme_stylebox_override("focus", pressed_style)
	if not app.pressed.is_connected(_on_app_pressed):
		app.pressed.connect(_on_app_pressed.bind(app.name))

func _on_app_pressed(app_name: String) -> void:
	var target_window = windows_folder.get_node_or_null(app_name)
	if target_window:
		if not target_window.visible:
			target_window.show()
			target_window.global_position = get_viewport_rect().size / 2 - target_window.size / 2
		windows_folder.move_child(target_window, -1)

# --- Death Screen Logic ---
func trigger_death_screen(message: String):
	# 1. Show the dark screen
	dark_screen.show()
	dark_screen.color = Color.BLACK
	dark_screen.z_index = 100 
	
	# 2. Setup the quote
	quote.show()
	quote.z_index = 101
	quote.text = message
	quote.add_theme_color_override("font_color", Color(0.86, 0.08, 0.24)) 
	
	# 3. Hide UI
	margin_container.hide()
	$task_bar.hide()
	
	# 4. Wait 3 seconds, then show the restart button
	await get_tree().create_timer(3.0).timeout
	restart.show()
	restart.z_index = 102

func _on_restart_pressed():
	# Wipe everything
	current_day = 1
	hour = 9
	minute = 0
	
	# Reset all apps (including savings/hunger in Employment)
	_find_and_hard_reset_apps(windows_folder)
	
	# Hide death screen and bring back the desktop
	dark_screen.hide()
	quote.hide()
	restart.hide()
	margin_container.show()
	$task_bar.show()
	
	update_time_display()
	show_alert("RESTORING SYSTEM FROM BACKUP...")

# Special reset for death (wipes persistent stats)
func _find_and_hard_reset_apps(node: Node):
	if node.has_method("hard_reset"):
		node.hard_reset()
	for child in node.get_children():
		_find_and_hard_reset_apps(child)
