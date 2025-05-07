extends CharacterBody2D

class_name Player

signal charge_updated(percent: float)

var loaded = false

@export var health = 100.0
@export var speed = 300.0
@export var min_jump_velocity = -400.0
@export var max_jump_velocity = -800.0
@export var shooting_speed = 100
@export var shooting_range = 70
@export var max_charge_time = 0.5  # Max time you can charge jump

@onready var health_bar = $"../CanvasLayer/HealthBar"


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_charge_time = 0.0
var charge_percent = 0.0
var charging_jump = false
var is_shooting = false
var is_emitting = false
var is_scaling_up = true
var direction

var animated_sprite: AnimatedSprite2D
var animation_player: AnimationPlayer
var tongue: CharacterBody2D
var captured_enemy
var emitting_timer = 0.3

enum State
{
	Normal,
	Loaded
}

var current_state: State = State.Normal

func _ready() -> void:
	animated_sprite = $AnimatedSprite2D
	animation_player = $PlayerAnimation
	tongue = $AnimatedSprite2D/Tongue
	health_bar.set_health_bar(health)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle charging while on floor
	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			velocity.y = min_jump_velocity
			$Audio/Jump.play()
		
		if Input.is_action_pressed("Crouch"):
			charging_jump = true
			jump_charge_time += delta
			jump_charge_time = min(jump_charge_time, max_charge_time)
			charge_percent = jump_charge_time / max_charge_time
			animation_player.play("charge")
			emit_signal("charge_updated", charge_percent)
		elif Input.is_action_just_released("Crouch") and charging_jump:
			emit_signal("charge_updated", charge_percent)
			velocity.y = lerp(min_jump_velocity, max_jump_velocity, charge_percent)
			charging_jump = false
			jump_charge_time = 0.0
			$Audio/Jump.play()
		else:
			# Reset if not holding
			charging_jump = false
			jump_charge_time = 0.0
			charge_percent = 0.0
			emit_signal("charge_updated", charge_percent)

	# Horizontal movement
	direction = Input.get_axis("MoveLeft", "MoveRight")
	if direction and not charging_jump:
		velocity.x = direction * speed
		animated_sprite.scale.x = direction
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	if Input.is_action_just_pressed("Fire"):
		if current_state == State.Normal:
			$Audio/Shoot.play()
			is_shooting = true
		else:
			shoot(delta)
	
	if is_shooting and not is_emitting:
		shoot(delta)
	
	if is_emitting:
		emitting_timer -= delta
		if emitting_timer <= 0:
			is_emitting = false
			is_shooting = false
			emitting_timer = 0.3
		
	handle_animations()

	move_and_slide()

func handle_animations() -> void:
	# Decide animation priority
	match current_state:
		State.Normal:
			if is_shooting:
				animation_player.play("shoot")
			elif not is_on_floor():
				animation_player.play("jump")
			elif charging_jump:
				animation_player.play("charge")
			elif direction != 0:
				animation_player.play("walk")
			else:
				animation_player.play("idle")
		State.Loaded:
			if is_shooting:
				animation_player.play("shoot")
			elif not is_on_floor():
				animation_player.play("jump_loaded")
			elif charging_jump:
				animation_player.play("charge_loaded")
			elif direction != 0:
				animation_player.play("walk_loaded")
			else:
				animation_player.play("idle_loaded")

func shoot(delta) -> void:
	
	match current_state:
		State.Normal:
			tongue.visible = true
			if is_scaling_up:
				tongue.scale.x += delta * shooting_speed
				if tongue.scale.x >= shooting_range:
					is_scaling_up = false  # Start scaling down
			else:
				tongue.scale.x -= delta * shooting_speed
				if tongue.scale.x <= 1:
					tongue.scale.x = 1
					tongue.visible = false
					is_shooting = false
					is_scaling_up = true
					if captured_enemy:
						captured_enemy.visible = false
						current_state = State.Loaded
		
		State.Loaded:
			captured_enemy.release()
			animation_player.play("shoot")
			is_shooting = true
			is_emitting = true
			current_state = State.Normal

func deal_damage(amount: float) -> void:
	health -= amount
	health_bar.change_health(health)
	$Audio/Damage.play()
	if health <= 0:
		call_deferred("reload_scene")
		
func heal(amount: float) -> void:
	if health < health_bar.max_value:
		$Audio/Heal.play()
		health += amount
		health_bar.change_health(health)

func reload_scene():
	get_tree().reload_current_scene()

func _on_tongue_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		captured_enemy = area.get_parent()
		print(captured_enemy.name)
		
