extends Control

@onready var background: ColorRect = $background
@onready var margin_container: MarginContainer = $MarginContainer
@onready var app_grid: GridContainer = $MarginContainer/AppGrid
# --- NEW: Reference to your windows folder ---
@onready var windows_folder: Node2D = $window 

const PADDING = 20 
const ICON_SPACING = 15 
const ICON_SIZE = Vector2(64, 80) 

func _ready() -> void:
	# Hide all windows at start
	for window in windows_folder.get_children():
		window.hide()
		
	setup_desktop_environment()

func setup_desktop_environment() -> void:
	margin_container.add_theme_constant_override("margin_top", PADDING)
	margin_container.add_theme_constant_override("margin_left", PADDING)
	margin_container.add_theme_constant_override("margin_bottom", PADDING)
	margin_container.add_theme_constant_override("margin_right", PADDING)
	
	app_grid.add_theme_constant_override("h_separation", ICON_SPACING)
	app_grid.add_theme_constant_override("v_separation", ICON_SPACING)
	
	for child in app_grid.get_children():
		if child is Button:
			style_as_retro_app(child)

func style_as_retro_app(app: Button) -> void:
	app.custom_minimum_size = ICON_SIZE
	app.vertical_icon_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_TOP
	app.icon_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	app.expand_icon = true
	app.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	app.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	app.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.add_theme_font_size_override("font_size", 11)

	# Styles (simplified for brevity)
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
			# Window was closed, so open it
			target_window.show()
			# Center it on screen initially if you want
			target_window.global_position = get_viewport_rect().size / 2 - target_window.size / 2
		
		# Always bring to front and "focus" it
		windows_folder.move_child(target_window, -1)
	else:
		print("No window asset found for: ", app_name)
