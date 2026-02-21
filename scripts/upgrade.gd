extends PanelContainer

@onready var grid_container: GridContainer = $content/MarginContainer/upgrades/GridContainer
@onready var buttons: Array = [
	$content/MarginContainer/upgrades/GridContainer/Button,
	$content/MarginContainer/upgrades/GridContainer/Button2,
	$content/MarginContainer/upgrades/GridContainer/Button3,
	$content/MarginContainer/upgrades/GridContainer/Button4,
	$content/MarginContainer/upgrades/GridContainer/Button5,
	$"content/MarginContainer/upgrades/GridContainer/???"
]

@onready var shutdown: Button = $"../../task_bar/HBoxContainer/Shutdown"

func _ready() -> void:
	self.resized.connect(_on_window_resized)
	
	# IMPORTANT: For buttons to shrink, they must have NO minimum size
	for btn in buttons:
		btn.custom_minimum_size = Vector2.ZERO 
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# This prevents long text from forcing the button to stay wide
		btn.clip_text = true 
	
	_on_window_resized()

func _on_window_resized() -> void:
	# 1. Reset the GridContainer's min size so it doesn't block shrinking
	grid_container.custom_minimum_size = Vector2.ZERO
	
	# 2. Force the GridContainer to match the current width of the content area
	# This ensures all 3 buttons stay within the visible bounds
	var available_width = self.size.x * 0.9 # Leave a small 10% margin
	grid_container.custom_minimum_size.x = available_width

func _on__pressed():
	shutdown.visible = true
