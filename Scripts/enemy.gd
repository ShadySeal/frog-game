extends CharacterBody2D

var projectile_path = preload("res://Scenes/projectile.tscn")

@export var player: Player

@export var speed = 150.0
@export var acceleration = 1.0  # Higher means snappier
@export var max_distance = 100
@export var fire_range = 400

var direction = 1
var velocity_x = 0.0  # We'll interpolate this instead of setting velocity.x directly
var original_position

func _ready() -> void:
	original_position = transform.get_origin()

func _physics_process(delta: float) -> void:
	var target_velocity_x = speed * direction
	velocity_x = lerp(velocity_x, target_velocity_x, acceleration * delta)
	velocity.x = velocity_x
	
	if abs(position.x - original_position.x) >= max_distance:
		direction = -1 if direction == 1 else 1
		original_position.x = position.x
	
	move_and_slide()

func fire() -> void:
	var projectile = projectile_path.instantiate()
	var direction_to_player = (player.global_position - global_position).normalized()
	projectile.dir = direction_to_player.angle()
	projectile.pos = global_position
	get_parent().add_child(projectile)


func _on_fire_timer_timeout() -> void:
	if global_position.distance_to(player.global_position) <= fire_range:
			fire()
