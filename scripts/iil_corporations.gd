extends PanelContainer

@onready var daily_funds_label: Label = $content/main_buttons/daily_funds
@onready var approve: Button = $content/main_buttons/approve
@onready var deny: Button = $content/main_buttons/deny
@onready var skip: Button = $content/main_buttons/skip
@onready var happiness_level: ProgressBar = $content/main_buttons/happiness_level
@onready var letter_label: Label = $content/Letter

# --- Game Balance Variables ---
var starting_funds: float = 2500.0
var conversion_rate: float = 10.0 
var current_funds: float = 0.0
var current_happiness: float = 80.0 
var drain_speed: float = 0.4
var inactivity_limit: float = 4.0 
var time_since_last_action: float = 0.0
var processing_active: bool = false
var shift_complete: bool = false

# --- Shift Logic ---
var active_shift_deck: Array = []
var current_letter_index: int = 0
var letters_per_shift: int = 6 

var master_letters: Array = [
	{"text": "My windshield cracked on the I-95. A small pebble flew up from a construction truck.", "cost": 450, "impact": 5},
	{"text": "A tree branch fell on my roof during the storm. No structural damage, just shingles.", "cost": 600, "impact": 8},
	{"text": "Claiming for a lost suitcase during my flight to Denver. It contained mostly socks.", "cost": 150, "impact": 5},
	{"text": "Requesting a refund for a spoiled gallon of milk. It expired two days before the date.", "cost": 4, "impact": 5},
	{"text": "My basement flooded. There are things swimming in the dark. They have human fingers.", "cost": 1200, "impact": 15},
	{"text": "Reimbursement for 40lbs of industrial salt. The circles must stay unbroken.", "cost": 80, "impact": 10},
	{"text": "I can't stop seeing the face in the static of my TV. Does the policy cover 'Cognitive Contamination'?", "cost": 300, "impact": 12},
	{"text": "The claim is for my husband. He didn't die, he just... thinned out. He's under the rug now.", "cost": 5000, "impact": 20},
	{"text": "My house has grown a new room overnight. There is no door, but I can hear scratching from inside.", "cost": 4500, "impact": 25},
	{"text": "Claiming for 'Internal Structural Damage.' My ribs are growing in the shape of a birdcage.", "cost": 8500, "impact": 40},
	{"text": "The previous claims adjuster promised me a payout. He sounded like he was underwater.", "cost": 900, "impact": 15},
	{"text": "I am claiming for the loss of my reflection. I walked past a mirror and it just stayed there.", "cost": 0, "impact": 30},
	{"text": "Emergency extraction requested. The walls of my cubicle are getting closer.", "cost": 2200, "impact": 20},
	{"text": "My son replaced his eyes with marbles. He says the 'Tall Man' likes the colors.", "cost": 1100, "impact": 18},
	{"text": "Requesting funds for a 'Silence Perimeter.' The neighbors are screaming, but their mouths are sewn shut.", "cost": 3000, "impact": 22},
	{"text": "I found a hole in the backyard. It isn't a hole. It's a throat. It's asking for a down payment.", "cost": 666, "impact": 13}
]

func _ready() -> void:
	randomize()
	reset_for_new_shift()

func reset_for_new_shift() -> void:
	current_funds = starting_funds
	current_happiness = 80.0
	current_letter_index = 0
	shift_complete = false
	processing_active = false
	time_since_last_action = 0.0
	
	active_shift_deck = master_letters.duplicate()
	active_shift_deck.shuffle()
	active_shift_deck = active_shift_deck.slice(0, letters_per_shift)
	
	approve.show(); deny.show(); skip.show()
	approve.disabled = false; deny.disabled = false; skip.disabled = false
	set_process(true)
	update_ui()

func _process(delta: float) -> void:
	if current_letter_index < active_shift_deck.size() and not processing_active and not shift_complete:
		time_since_last_action += delta
		if time_since_last_action >= inactivity_limit:
			current_happiness -= drain_speed * delta
			current_happiness = clamp(current_happiness, 0, 100)
			happiness_level.value = current_happiness
		
		if current_happiness <= 0: _trigger_game_over()

func update_ui() -> void:
	daily_funds_label.text = "Funds: $" + str(snapped(current_funds, 0.01))
	happiness_level.value = current_happiness
	
	# Reset any glitch visuals
	letter_label.pivot_offset = Vector2.ZERO
	letter_label.rotation = 0
	
	if current_letter_index < active_shift_deck.size():
		var l = active_shift_deck[current_letter_index]
		letter_label.text = l["text"] + "\n\n[CLAIM AMOUNT: $" + str(l["cost"]) + "]"
		letter_label.modulate = Color(1, 0.5, 0.5) if l["impact"] > 25 else Color(1, 1, 1)
	else:
		_end_shift()

func process_decision(choice: String) -> void:
	if current_letter_index >= active_shift_deck.size() or processing_active or shift_complete: 
		return
	
	var l = active_shift_deck[current_letter_index]
	
	if choice == "approve" and current_funds < l["cost"]:
		letter_label.text = "ERROR: SYSTEM CANNOT AUTHORIZE DEBT."
		return

	processing_active = true
	time_since_last_action = 0.0
	approve.disabled = true; deny.disabled = true; skip.disabled = true
	
	var glitch_intensity = 0.0
	if l["impact"] > 15:
		glitch_intensity = float(l["impact"]) / 40.0
	
	await _run_upload_sequence(glitch_intensity)

	match choice:
		"approve":
			current_happiness = clamp(current_happiness + l["impact"], 0, 100)
			current_funds -= l["cost"]
		"deny":
			current_happiness -= (l["impact"] * 0.6)
		"skip":
			current_happiness -= 15.0 

	current_letter_index += 1
	processing_active = false
	approve.disabled = false; deny.disabled = false; skip.disabled = false
	update_ui()

func _run_upload_sequence(intensity: float) -> void:
	var base_text = "UPLOADING TO CENTRAL... \nDO NOT LOOK AT THE SCREEN."
	var chars = "01#?!@$%&*"
	var hidden_messages = ["HE IS WATCHING", "WHY DID YOU SIGN?", "IT TASTES LIKE COPPER", "IGNORE THE TEETH"]
	
	var duration = 1.2 + (intensity * 1.5)
	var elapsed = 0.0
	
	letter_label.modulate = Color(1, 1, 1)
	
	while elapsed < duration:
		var frame_text = base_text
		
		if intensity > 0.3 and randf() < 0.05:
			frame_text = hidden_messages[randi() % hidden_messages.size()]
		elif intensity > 0.1 and randf() < intensity:
			# FIX: Convert to Array explicitly and use length() for strings
			var text_array = Array(frame_text.split(""))
			for i in range(3):
				if text_array.size() > 0:
					var pos = randi() % text_array.size()
					text_array[pos] = chars[randi() % chars.length()]
			frame_text = "".join(text_array)
		
		letter_label.text = frame_text
		
		if intensity > 0.1:
			letter_label.pivot_offset = Vector2(randf_range(-10, 10) * intensity, randf_range(-10, 10) * intensity)
		
		var wait = randf_range(0.05, 0.1)
		await get_tree().create_timer(wait).timeout
		elapsed += wait
	
	letter_label.pivot_offset = Vector2.ZERO

func _end_shift() -> void:
	shift_complete = true
	set_process(false)
	var paycheck = int(floor(current_happiness * conversion_rate))
	approve.hide(); deny.hide(); skip.hide()
	
	# Recursively search for a parent that can handle the time skip
	var desktop = self
	while desktop != null:
		if desktop.has_method("trigger_time_skip"):
			desktop.trigger_time_skip()
			break
		desktop = desktop.get_parent()
	
	letter_label.modulate = Color(1, 1, 1)
	letter_label.text = "SHIFT COMPLETE.\nQuota Met.\nPaycheck: $" + str(paycheck) + "\n\nREST IS MANDATORY."

func _trigger_game_over() -> void:
	set_process(false)
	shift_complete = true
	letter_label.modulate = Color(1, 0, 0)
	letter_label.text = "TERMINATED.\nREASON: EMOTIONAL INSTABILITY.\nGOODBYE."
	approve.hide(); deny.hide(); skip.hide()

func _on_approve_pressed(): process_decision("approve")
func _on_deny_pressed(): process_decision("deny")
func _on_skip_pressed(): process_decision("skip")
