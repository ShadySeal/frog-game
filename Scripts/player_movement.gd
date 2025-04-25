extends CharacterBody2D

class_name Player

signal charge_updated(percent: float)

@export var speed = 300.0
@export var min_jump_velocity = -400.0
@export var max_jump_velocity = -800.0
@export var max_charge_time = 0.5  # Max time you can charge jump

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_charge_time = 0.0
var charge_percent = 0.0
var charging_jump = false

var animated_sprite: AnimatedSprite2D
var animation_player: AnimationPlayer

func _ready() -> void:
	animated_sprite = $AnimatedSprite2D
	animation_player = $PlayerAnimation
	$AnimatedSprite2D/Tongue.set_process(false)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle charging while on floor
	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			velocity.y = min_jump_velocity
			animation_player.play("jump")
		
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
		else:
			# Reset if not holding
			charging_jump = false
			jump_charge_time = 0.0
			charge_percent = 0.0
			emit_signal("charge_updated", charge_percent)

	# Horizontal movement
	var direction = Input.get_axis("MoveLeft", "MoveRight")
	if direction and not charging_jump:
		velocity.x = direction * speed
		animated_sprite.scale.x = direction
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	if Input.is_action_just_pressed("Fire"):
		shoot()
	
	# Decide animation priority
	if not is_on_floor():
		animation_player.play("jump")
	elif charging_jump:
		animation_player.play("charge")
	elif direction != 0:
		animation_player.play("walk")
	else:
		animation_player.play("idle")

	move_and_slide()

func shoot() -> void:
	$AnimatedSprite2D/Tongue.set_process(true)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy") or area.is_in_group("Projectile"):
		call_deferred("reload_scene")

func reload_scene():
	get_tree().reload_current_scene()
