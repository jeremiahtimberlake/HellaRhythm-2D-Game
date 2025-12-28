extends Area2D

# wisp properties
var assigned_keycode : int
var note_time : float = 0.0   
var drift_speed : float = 0.0
var target_orpheus : CharacterBody2D = null
var lyre : Node = null

# travel bools
var reached_orpheus := false

@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var note_label : Label = $NoteLabel

func _ready():
	# register with Lyre so it can track this wisp
	if lyre:
		lyre.register_wisp(self)
		
	# display assigned assigned scale degree (1-9)
	if note_label:
		note_label.text = _keycode_to_number(assigned_keycode)
		
	# play emerge animation first
	if anim.has_animation("emerge"):
		anim.play("emerge")
		anim.animation_finished.connect(_on_anim_finished)

	# connect collision only once
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))


func _on_anim_finished(anim_name):
	if anim_name == "emerge" and anim.has_animation("move"):
		anim.play("move")


func _process(delta):
	if target_orpheus == null:
		return

	# move wisp towards orpheus
	var dir = (target_orpheus.global_position - global_position).normalized()
	global_position += dir * drift_speed * delta


func on_note_played(keycode):
	if keycode != assigned_keycode:
		return

	var dt = abs(lyre.song_timer - note_time)

	if dt <= lyre.hit_window:
		kill_wisp()

func kill_wisp():
	if is_queued_for_deletion():  # prevent double killing
		return
	if anim and anim.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	queue_free()

func _on_body_entered(body):
	if body == target_orpheus and not reached_orpheus:
		reached_orpheus = true

		# notify lyre of a miss
		if lyre:
			lyre._on_wisp_missed(self)

		kill_wisp()

func _keycode_to_number(keycode):
	return str(char(keycode))
