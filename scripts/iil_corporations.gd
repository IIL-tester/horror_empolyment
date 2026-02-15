extends PanelContainer

@onready var daily_funds_label: Label = $content/main_buttons/daily_funds
@onready var approve: Button = $content/main_buttons/approve
@onready var deny: Button = $content/main_buttons/deny
@onready var skip: Button = $content/main_buttons/skip
@onready var happiness_level: ProgressBar = $content/main_buttons/happiness_level
@onready var letter_label: Label = $content/Letter

var starting_funds: float = 2500.0
var conversion_rate: float = 10.0 
var current_funds: float = 0.0
var current_happiness: float = 80.0 
var drain_speed: float = 0.33 
var inactivity_limit: float = 5.0 
var time_since_last_action: float = 0.0
var processing_active: bool = false
var shift_complete: bool = false

var letters: Array = [
	{"text": "My windshield cracked on the I-95. A small pebble flew up from a construction truck.", "cost": 450, "impact": 5},
	{"text": "My basement flooded. There are things swimming in the dark. They have human fingers.", "cost": 1200, "impact": 15},
	{"text": "The claim is for my husband. He didn't die, he just... thinned out. He's under the rug now.", "cost": 5000, "impact": 20},
	{"text": "Requesting a refund for a spoiled gallon of milk. It expired two days before the date.", "cost": 4, "impact": 5},
	{"text": "Reimbursement for 40lbs of industrial salt. The circles must stay unbroken.", "cost": 80, "impact": 10},
	{"text": "I can't stop seeing the face in the static of my TV. Does the policy cover 'Cognitive Contamination'?", "cost": 300, "impact": 12},
	{"text": "A tree branch fell on my roof during the storm. No structural damage, just shingles.", "cost": 600, "impact": 8},
	{"text": "My house has grown a new room overnight. There is no door, but I can hear scratching from inside.", "cost": 4500, "impact": 25},
	{"text": "Claiming for a lost suitcase during my flight to Denver. It contained mostly socks.", "cost": 150, "impact": 5}
]
var current_letter_index: int = 0

func _ready() -> void:
	reset_for_new_shift()

func reset_for_new_shift() -> void:
	current_funds = starting_funds
	current_happiness = 80.0
	current_letter_index = 0
	shift_complete = false
	processing_active = false
	time_since_last_action = 0.0
	approve.show(); deny.show(); skip.show()
	approve.disabled = false; deny.disabled = false; skip.disabled = false
	set_process(true)
	update_ui()

func _process(delta: float) -> void:
	if current_letter_index < letters.size() and not processing_active and not shift_complete:
		time_since_last_action += delta
		if time_since_last_action >= inactivity_limit:
			current_happiness -= drain_speed * delta
			current_happiness = clamp(current_happiness, 0, 100)
			happiness_level.value = current_happiness
		
		if current_happiness <= 0: _trigger_game_over()

func update_ui() -> void:
	daily_funds_label.text = "Funds: $" + str(snapped(current_funds, 0.01))
	happiness_level.value = current_happiness
	if current_letter_index < letters.size():
		var l = letters[current_letter_index]
		letter_label.text = l["text"] + "\n\n[CLAIM AMOUNT: $" + str(l["cost"]) + "]"
	else:
		_end_shift()

func process_decision(choice: String) -> void:
	if current_letter_index >= letters.size() or processing_active or shift_complete: return
	var l = letters[current_letter_index]
	
	if choice == "approve" and current_funds < l["cost"]:
		letter_label.text = "ERROR: INSUFFICIENT FUNDS."
		return

	processing_active = true
	approve.disabled = true; deny.disabled = true; skip.disabled = true
	letter_label.text = "UPLOADING TO CENTRAL... PLEASE WAIT."
	await get_tree().create_timer(randf_range(1.0, 2.0)).timeout

	match choice:
		"approve":
			current_happiness += l["impact"]
			current_funds -= l["cost"]
		"deny":
			current_happiness -= (l["impact"] * 0.5)
		"skip":
			current_happiness -= 10.0 

	current_letter_index += 1
	processing_active = false
	approve.disabled = false; deny.disabled = false; skip.disabled = false
	update_ui()

func _end_shift() -> void:
	shift_complete = true
	set_process(false)
	
	var paycheck = int(floor(current_happiness * conversion_rate))
	approve.hide(); deny.hide(); skip.hide()
	
	# IMPROVED FINDER: Search for the node that actually has the trigger_time_skip method
	var desktop = null
	
	# Try the Scene Tree Root first
	desktop = get_tree().root.find_child("game", true, false)
	
	# If that fails, look for the parent of the window folder (usually the Desktop)
	if not desktop or not desktop.has_method("trigger_time_skip"):
		var node = self
		while node != null:
			if node.has_method("trigger_time_skip"):
				desktop = node
				break
			node = node.get_parent()

	if desktop:
		desktop.trigger_time_skip()
		print("Desktop found! Fast-forwarding...")
	else:
		print("CRITICAL ERROR: Desktop node not found!")
	
	letter_label.text = "SHIFT COMPLETE.\nPaycheck: $" + str(paycheck) + "\n\nWAITING FOR NEXT DAY..."

func _trigger_game_over() -> void:
	set_process(false)
	shift_complete = true
	letter_label.text = "TERMINATED. ACCESS REVOKED."
	approve.hide(); deny.hide(); skip.hide()

func _on_approve_pressed(): process_decision("approve")
func _on_deny_pressed(): process_decision("deny")
func _on_skip_pressed(): process_decision("skip")
