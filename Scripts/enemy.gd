extends CharacterBody2D

var projectile_path = preload("res://scenes/projectile.tscn")

signal deal_damage(damage: float)

@export var player: Player

@export var speed = 150.0
@export var acceleration = 1.0  # Higher means snappier
@export var max_distance = 100
@export var fire_range = 400

var direction = 1
var velocity_x = 0.0  # We'll interpolate this instead of setting velocity.x directly
var original_position

var tongue_area: Area2D = null
var captured_offset: Vector2
var launch_direction

var release_time = 0.5

enum State
{
	Patrol,
	Captured,
	Released
}

var current_state: State = State.Patrol

func _ready() -> void:
	original_position = transform.get_origin()

func _physics_process(delta: float) -> void:
	
	match current_state:
		State.Patrol:
			var target_velocity_x = speed * direction
			velocity_x = lerp(velocity_x, target_velocity_x, acceleration * delta)
			velocity.x = velocity_x
			
			if abs(position.x - original_position.x) >= max_distance:
				direction = -1 if direction == 1 else 1
				original_position.x = position.x
				
		State.Captured:
			velocity = Vector2.ZERO
			$FireTimer.stop()
			if tongue_area:
				global_position = tongue_area.global_position + captured_offset
				
		State.Released:
			visible = true
			velocity.x = 300 * launch_direction
			player.captured_enemy = null
			release_time -= delta
			if release_time <= 0:
				$FireTimer.start()
				player.loaded = false
				release_time = 0.5
				current_state = State.Patrol
			
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

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		kill()
		
	if area.is_in_group("Player") and current_state == State.Patrol:
		area.get_parent().deal_damage(25)
	
	if current_state == State.Patrol:
		if area.is_in_group("Tongue") and player.is_shooting:
			current_state = State.Captured
			tongue_area = area
			captured_offset = global_position - tongue_area.global_position
	elif current_state == State.Released:
		if area.is_in_group("Obstacle"):
			kill()

func _on_player_release() -> void:
	launch_direction = player.animated_sprite.scale.x
	current_state = State.Released
	position = player.position

func kill():
	player.captured_enemy = null
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Obstacle") and current_state == State.Released:
		kill()
