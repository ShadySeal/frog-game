extends CharacterBody2D

var pos: Vector2
var dir: float

@export var speed: float

func _ready() -> void:
	global_position = pos
	
func _physics_process(delta: float) -> void:
	velocity = Vector2(speed, 0).rotated(dir)
	move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		area.get_parent().deal_damage(25)
