extends Sprite2D

# charon variable(s)
var charon_speed : float =20.0

# animation player
@onready var anim := $AnimationPlayer

# REMINDERS:
# will need to add a variable for Charon's death when game is won

func _ready() -> void:
	anim.play("emerge")

func _process(_delta: float):
	pass

# call animations after certain ones finish 
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "emerge":
		$AnimationPlayer.play("idle")
		
