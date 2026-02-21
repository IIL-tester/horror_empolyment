extends PanelContainer

@onready var daily_funds_label: Label = $content/main_buttons/daily_funds
@onready var approve: Button = $content/main_buttons/approve
@onready var deny: Button = $content/main_buttons/deny
@onready var skip: Button = $content/main_buttons/skip
@onready var happiness_level: ProgressBar = $content/main_buttons/happiness_level
@onready var letter_label: Label = $content/Letter

# after shift UI
@onready var yes: Button = $content/Letter/MarginContainer/HBoxContainer/yes
@onready var no: Button = $content/Letter/MarginContainer/HBoxContainer/no
@onready var hunger_bar: ProgressBar = $content/Letter/MarginContainer/HBoxContainer/VBoxContainer/hunger_level
@onready var cafeteria_ui: Control = $content/Letter/MarginContainer 

# --- Progression & Horror Variables ---
var current_day: int = 1
var starting_funds: float = 5500.0
var conversion_rate: float = 10.0 
var total_savings: float = 0.0 
var current_funds: float = 0.0
var current_happiness: float = 80.0 
var current_hunger: float = 100.0
var drain_speed: float = 0.4
var inactivity_limit: float = 4.0 
var time_since_last_action: float = 0.0
var processing_active: bool = false
var shift_complete: bool = false

# --- Narrative & Ending Logic ---
var special_timer: float = 15.0
var is_showing_special: bool = false
var is_showing_error: bool = false
var has_bought_mystery_item: bool = false
var is_marked_for_promotion: bool = false

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
	cafeteria_ui.hide()
	reset_for_new_shift()

# Call this from your Upgrades App when "???" is purchased
func _on_mystery_item_purchased():
	has_bought_mystery_item = true

func reset_for_new_shift() -> void:
	# End game check
	if current_day >= 15 and not shift_complete:
		_trigger_afterlife_ending()
		return

	current_funds = starting_funds
	current_happiness = 80.0
	current_letter_index = 0
	shift_complete = false
	processing_active = false
	time_since_last_action = 0.0
	is_showing_special = false
	is_showing_error = false
	
	active_shift_deck = master_letters.duplicate()
	active_shift_deck.shuffle()
	active_shift_deck = active_shift_deck.slice(0, letters_per_shift)
	
	# --- Story Injections ---
	if current_day == 2:
		active_shift_deck.insert(3, {"text": "911 DISPATCH: 'Hang in there, we'll get you out soon enough. Stay away from the vents.'", "cost": 0, "impact": 0, "special": true})
	
	if current_day == 4:
		active_shift_deck.insert(2, {"text": "911 DISPATCH: 'Listen carefully. Buy the item marked \"???\" in your Upgrade App. We've hidden the extraction code inside it.'", "cost": 0, "impact": 0, "special": true})

	if has_bought_mystery_item and not is_marked_for_promotion:
		is_marked_for_promotion = true
		active_shift_deck.insert(1, {"text": "MESSAGE FROM THE BOSS: 'You've been such a good employee. Me and HR think you deserve a promotion. We're thinking of doing it on Day 15.'", "cost": 0, "impact": 50, "boss": true, "special": true})

	if current_day == 6:
		active_shift_deck.insert(2, {"text": "ANONYMOUS: 'They are listening. You have to shutdown the computer to escape. Shutdown the computer while theres still time.'", "cost": 0, "impact": 0, "special": true})

	if current_day > 3:
		_corrupt_deck()

	approve.show(); deny.show(); skip.show()
	cafeteria_ui.hide()
	approve.disabled = false; deny.disabled = false; skip.disabled = false
	set_process(true)
	update_ui()

func _corrupt_deck():
	var index = randi() % active_shift_deck.size()
	if not active_shift_deck[index].has("special"):
		active_shift_deck[index]["text"] = "I can see you through the webcam. You haven't blinked in four minutes."

func _process(delta: float) -> void:
	if current_letter_index < active_shift_deck.size() and not processing_active and not shift_complete:
		if is_showing_special:
			special_timer -= delta
			update_countdown_display()
			if special_timer <= 0:
				_skip_special_letter()
			return

		time_since_last_action += delta
		if time_since_last_action >= inactivity_limit:
			current_happiness -= drain_speed * delta
			current_happiness = clamp(current_happiness, 0, 100)
			happiness_level.value = current_happiness
		
		if current_hunger <= 30.0:
			var shake_intensity = (30.0 - current_hunger) / 30.0 
			if randf() < 0.15: 
				letter_label.pivot_offset = Vector2(randf_range(-8, 8) * shake_intensity, randf_range(-8, 8) * shake_intensity)
				letter_label.rotation_degrees = randf_range(-2, 2) * shake_intensity

		if current_happiness <= 0: _trigger_game_over()

func update_ui() -> void:
	if is_showing_error: return 
	
	daily_funds_label.text = "DAY " + str(current_day) + "\nFunds:\n$" + str(snapped(current_funds, 0.01))
	happiness_level.value = current_happiness
	letter_label.pivot_offset = Vector2.ZERO
	letter_label.rotation = 0
	
	if current_letter_index < active_shift_deck.size():
		var l = active_shift_deck[current_letter_index]
		if l.has("special"):
			is_showing_special = true
			special_timer = 15.0
			letter_label.modulate = Color(1, 0, 0) if not l.has("boss") else Color(1, 1, 0) # Red for 911, Yellow for Boss
			update_countdown_display()
		else:
			is_showing_special = false
			letter_label.text = l["text"] + "\n\n[CLAIM AMOUNT: $" + str(l["cost"]) + "]"
			letter_label.modulate = Color(1, 0.5, 0.5) if l["impact"] > 25 else Color(1, 1, 1)
	else:
		_end_shift()

func update_countdown_display() -> void:
	var l = active_shift_deck[current_letter_index]
	var header = ">>> INCOMING TRANSMISSION <<<" if l.has("boss") else ">>> ENCRYPTED MESSAGE <<<"
	letter_label.text = header + "\n\n" + l["text"] + "\n\n[SIGNAL LOST IN: " + str(ceil(special_timer)) + "s]"

func _skip_special_letter() -> void:
	is_showing_special = false
	current_letter_index += 1
	update_ui()

# --- New Ending Logic ---

# Call this if the player clicks a "Shutdown" button in your OS UI
func trigger_shutdown_victory():
	_apply_horror_screen("SYSTEM OFFLINE.\n\nYou pulled the plug. The office is dark.\nYou are finally free.\n\nHAPPY ENDING.")

func _trigger_afterlife_ending():
	_apply_horror_screen("PROMOTION DAY.\n\nHR has arrived. The door is locked.\nYou are being promoted to the afterlife.\n\nGAME OVER.")

# --- Existing Decisions & UI Logic ---

func process_decision(choice: String) -> void:
	if current_letter_index >= active_shift_deck.size() or processing_active or shift_complete or is_showing_error: return
	var l = active_shift_deck[current_letter_index]
	
	if choice == "approve" and current_funds < l["cost"]:
		_show_temporary_error("ERROR: SYSTEM CANNOT AUTHORIZE DEBT.")
		return
		
	processing_active = true
	time_since_last_action = 0.0
	approve.disabled = true; deny.disabled = true; skip.disabled = true
	
	var glitch_intensity = float(l["impact"]) / 40.0 if l["impact"] > 15 else 0.0
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

func _show_temporary_error(msg: String) -> void:
	is_showing_error = true
	approve.disabled = true; deny.disabled = true; skip.disabled = true
	letter_label.text = msg
	await get_tree().create_timer(5.0).timeout 
	is_showing_error = false
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
			var text_array = Array(frame_text.split(""))
			for i in range(3):
				if text_array.size() > 0:
					var pos = randi() % text_array.size()
					text_array[pos] = chars[randi() % chars.length()]
			frame_text = "".join(PackedStringArray(text_array))
			
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
	total_savings += paycheck
	approve.hide(); deny.hide(); skip.hide()
	
	var food_price = get_current_food_price()
	letter_label.text = "SHIFT COMPLETE.\nPaycheck: $" + str(paycheck) + "\nSavings: $" + str(total_savings) + "\n\nPurchase lunch from the cafeteria?\nCost: $" + str(snapped(food_price, 1))
	
	hunger_bar.value = current_hunger
	yes.disabled = (current_hunger >= 100.0)
	cafeteria_ui.show()

func get_current_food_price() -> float:
	return 200.0 + (65.0 - current_hunger) * (200.0 / 65.0)

func _on_yes_pressed():
	if current_hunger >= 100.0:
		letter_label.text = "YOU ARE FULL. \nGLUTTONY IS UNPRODUCTIVE."
		return
	var food_price = get_current_food_price()
	if total_savings >= food_price:
		total_savings -= food_price
		current_hunger = 100.0
		_finish_day()
	else:
		_show_temporary_error("INSUFFICIENT PERSONAL FUNDS.\nSTARVATION IS NOT AN EXCUSE.")

func _on_no_pressed():
	current_hunger = clamp(current_hunger - 35, 0, 100)
	if current_hunger <= 0:
		_pay_starvation_fee()
	else:
		_finish_day()

func _pay_starvation_fee():
	var fee = 400.0
	if total_savings >= fee:
		total_savings -= fee
		letter_label.text = "STARVATION DETECTED.\n$400 RECOVERY FEE DEDUCTED.\n\nSTAY PRODUCTIVE."
		await get_tree().create_timer(3.0).timeout
		_finish_day()
	else:
		_trigger_poverty_death()

func _finish_day():
	current_day += 1
	cafeteria_ui.hide()
	letter_label.text = "REST IS MANDATORY. \n\nNext Shift at 9:00."
	var desktop = self
	while desktop != null:
		if desktop.has_method("trigger_time_skip"):
			desktop.trigger_time_skip()
			break
		desktop = desktop.get_parent()

func _trigger_poverty_death():
	_apply_horror_screen("YOU'RE FIRED!\nThe world only has room for the wealthy.")

func _trigger_game_over():
	_apply_horror_screen("YOU'RE FIRED!\nThis company doesn't need useless employees.")

func _apply_horror_screen(message: String):
	set_process(false)
	shift_complete = true
	cafeteria_ui.hide()
	approve.hide(); deny.hide(); skip.hide()
	yes.hide(); no.hide()

	var main_game = self
	while main_game != null:
		if main_game.has_method("trigger_death_screen"):
			main_game.trigger_death_screen(message)
			break
		main_game = main_game.get_parent()

func hard_reset():
	total_savings = 0.0
	current_hunger = 100.0
	current_day = 1
	has_bought_mystery_item = false
	is_marked_for_promotion = false
	reset_for_new_shift()

func _on_approve_pressed(): process_decision("approve")
func _on_deny_pressed(): process_decision("deny")
func _on_skip_pressed(): process_decision("skip")
