extends Node2D

@export var orpheus_path : NodePath
@export var wisp_scene : PackedScene

@export var spawn_distance_ahead := 0.0
@export var vertical_random_range := 25.0
@export var vertical_offset := 30.0
@export var horizontal_spacing := 60.0
@export var drift_speed := 0.0

var orpheus : CharacterBody2D
var lyre : Node = null
var song_chart = []
var song_index := 0
var song_timer := 0.0
var song_speed := 1.0

func _ready():
	orpheus = get_node_or_null(orpheus_path)
	lyre = get_tree().get_root().find_child("Lyre", true, false)
	
	song_chart = lyre.song_chart
	song_speed = lyre.song_speed

	randomize()

func _process(_delta):
	if lyre == null or not lyre.level_active:
		return
		
	if song_chart.is_empty():
		return

	song_timer = lyre.song_timer

	if song_index < song_chart.size():
		var next_note = song_chart[song_index]

		if song_timer >= next_note.time:
			spawn_wisp(next_note)
			song_index += 1


func spawn_wisp(note):
	# instantiate wisp scence
	var wisp = wisp_scene.instantiate()

	# assign wisp time properites
	wisp.assigned_keycode = note.key
	wisp.note_time = note.time
	wisp.lyre = lyre
	
	# assign wisp destination and travel properties
	wisp.target_orpheus = orpheus
	wisp.drift_speed = drift_speed

	# assign wisp position properties 
	var spawn_pos = orpheus.global_position
	spawn_pos.x += spawn_distance_ahead + horizontal_spacing
	spawn_pos.y += vertical_offset + randf_range(-vertical_random_range, vertical_random_range)
	wisp.global_position = spawn_pos

	# add wisp to scene
	add_child(wisp)
