extends Node

# notes variables
var notes = {}
var held_notes = {}

# song variables
var song_chart = []
var song_timer := 0.0
var song_speed := 1.0
var hit_window := 0.6
var current_index := 0
var last_second := -1 # README: DELETE LATER

# time variables
var song_start_delay := 4.0
var delayed_timer := 0.0
var level_active := false

# miss variables
var miss_counter := 0   
var miss_threshold := 5

# wisps array
var active_wisps : Array = []

# win/fail bools
var level_won := false;
var level_failed := true;

# UI values and labels
var charm_value := 100
@onready var charm_bar := get_tree().get_root().find_child("CharmBar", true, false)
@onready var charm_bar_label := charm_bar.get_node("CharmBarLabel")
@onready var win_label = get_tree().get_root().find_child("WinLabel", true, false)
@onready var fail_label := get_tree().get_root().find_child("FailLabel", true, false)

# character references 
@onready var orpheus = get_tree().get_root().find_child("Orpheus", true, false)
@onready var charon = get_tree().get_root().find_child("Charon", true, false)

func _ready():
	# establish keybind-note key-value pairs
	notes = {
		KEY_1: $note_D4,
		KEY_2: $note_E4,
		KEY_3: $note_F4,
		KEY_4: $note_G4,
		KEY_5: $note_A4,
		KEY_6: $note_B4,
		KEY_7: $note_C5,
		KEY_8: $note_D5,
		KEY_9: $note_E5
	}

	# load song chart
	load_song_chart("res://json/song_chart.json")

	# set charm bar value and charm bar text
	charm_bar.value = charm_value
	charm_bar_label.text = str(charm_value)

	# 4-second delay before level start 
	await get_tree().create_timer(song_start_delay).timeout
	level_active = true

func load_song_chart(path: String):
	var f = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())

	var map = {
		"KEY_1": KEY_1, "KEY_2": KEY_2, "KEY_3": KEY_3,
		"KEY_4": KEY_4, "KEY_5": KEY_5, "KEY_6": KEY_6,
		"KEY_7": KEY_7, "KEY_8": KEY_8, "KEY_9": KEY_9
	}

	for n in data:
		if typeof(n.key) == TYPE_STRING and n.key in map:
			n.key = map[n.key]

	song_chart = data

func _process(delta):
	if not level_active:
		return
	
	# song timer
	song_timer += delta * song_speed
	
	# start character movement 
	orpheus.anim.play("walk_right")
	orpheus.position.x += orpheus.orpheus_speed * delta
	charon.anim.play("move_right")
	charon.position.x += charon.charon_speed * delta

	# detect misses from wisps reaching Orpheus
	for w in active_wisps:
		if not is_instance_valid(w):
			active_wisps.erase(w)
			continue

		if w.reached_orpheus:
			_on_wisp_missed(w)
			return
	
	# if charm <= 0 at any point -> fail level
	if charm_value <= 0:
		_on_charm_depleted()

func _input(event):
	if event is InputEventKey:
		if event.pressed and not event.echo:
			_on_note_pressed(event.keycode)
		elif not event.pressed:
			if event.keycode in held_notes:
				held_notes.erase(event.keycode)
				notes[event.keycode].stop()

func _on_note_pressed(keycode):
	if keycode in notes and keycode not in held_notes:
		held_notes[keycode] = true
		notes[keycode].stop()
		notes[keycode].play()
		
		# First: clean dead references from last frame
		active_wisps = active_wisps.filter(func(w): return w != null and w.is_inside_tree())
		
		# Now safe to notify wisps
		for w in active_wisps:
			if w != null and w.is_inside_tree():
				w.on_note_played(keycode)
				
		# Clean again in case on_note_played killed a wisp
		active_wisps = active_wisps.filter(func(w): return w != null and w.is_inside_tree())
				
		check_hit(keycode)

func check_hit(keycode):
	# end the song if no more notesx
	if current_index >= song_chart.size():
		_on_song_end()
		return

	var n = song_chart[current_index]

	# Correct key + inside timing window → HIT
	if keycode == n.key and abs(song_timer - n.time) <= hit_window:
		current_index += 1

func register_wisp(wisp):
	active_wisps.append(wisp)
	
func _on_wisp_missed(wisp):
	miss_counter += 1
	if miss_counter >= miss_threshold:
		_apply_charm_penalty()
		miss_counter = 0

	if wisp in active_wisps:
		active_wisps.erase(wisp)
	wisp.kill_wisp()
	
func kill_wisp_for_key(keycode):
	for w in active_wisps:
		if w.assigned_keycode == keycode:
			w.kill_wisp()
			active_wisps.erase(w)
			return
			
func _apply_charm_penalty():
	charm_value -= 5
	charm_bar.value = charm_value
	charm_bar_label.text = str(charm_value)
	
func _on_charm_depleted():
	level_active = false

	# stop all active wisps
	for w in active_wisps:
		if is_instance_valid(w):
			w.kill_wisp()
	active_wisps.clear()
	
	# README: add death animation instead of just stopping
	orpheus.orpheus_speed = 0
	orpheus.anim.stop()
	
	# stop charon
	charon.charon_speed = 0
	charon.anim.play("idle")
	
	# hide charm UI
	charm_bar.visible = false;
	charm_bar_label.visible = false;
	
	# show fail label UI
	fail_label.visible = true

func _on_song_end():
	level_active = false

	# stop all active wisps
	for w in active_wisps:
		if is_instance_valid(w):
			w.kill_wisp()
	active_wisps.clear()
	
	# stop orpheus
	orpheus.orpheus_speed = 0
	orpheus.anim.stop()
	
	# kill charon
	charon.charon_speed = 0
	charon.anim.play("idle")
	await get_tree().create_timer(0.5).timeout
	charon.anim.play("blink_out")
	
	# hide charm UI
	charm_bar.visible = false
	charm_bar_label.visible = false
	
	# show win label UI
	win_label.visible = true
