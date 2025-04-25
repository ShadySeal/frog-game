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

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle charging while on floor
	if is_on_floor():
		if Input.is_action_pressed("Jump"):
			charging_jump = true
			jump_charge_time += delta
			jump_charge_time = min(jump_charge_time, max_charge_time)
			charge_percent = jump_charge_time / max_charge_time
			emit_signal("charge_updated", charge_percent)
		elif Input.is_action_just_released("Jump") and charging_jump:
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
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy") or area.is_in_group("Projectile"):
		call_deferred("reload_scene")

func reload_scene():
	get_tree().reload_current_scene()
