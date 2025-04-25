extends CharacterBody2D

var pos: Vector2
var dir: float

@export var speed: float

func _ready() -> void:
	global_position = pos
	#global_rotation = dir
	
func _physics_process(delta: float) -> void:
	velocity = Vector2(speed, 0).rotated(dir)
	move_and_slide()
