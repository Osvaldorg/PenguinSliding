class_name Player extends CharacterBody2D

@export var acceleration: float = 150
@export var max_speed: float = 290
@export var friction: float = 200
@export var air_friction: float = 60
@export var up_gravity: float = 250
@export var down_gravity: float = 500
@export var jump_force: float = 180
@export var unjump_force: float = 25
@export var landing_acceleration: float = 2250.0
@export var air_jump_speed_reduction: float = 1500
@export var coyote_time_amount: float = 0.15
@export var min_zoom_amount: float = 0.9
@export var max_zoom_amount: float = 1.5

@export var max_meter_value: float = 100.0
@export var meter_decrease_on_collision: float = 30.0
@export var meter_decrease_on_slow: float = 15.0
@export var meter_recovery_rate: float = 5.0
@export var slow_speed_threshold: float = 100.0

var target_tilt: float = 0.0
var air_jump: bool = true
var coyote_time: float = 0.0
var finish_x: float = -1

var speed_meter: float = 100.0
var is_frozen: bool = false

@onready var anchor: Node2D = $Anchor
@onready var sprite_2d: Sprite2D = $Anchor/Sprite2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

@onready var normal_texture = preload("res://textures/penquin.png")
@onready var frozen_texture = preload("res://textures/frozen_penquin.png")

signal level_finished()
signal meter_updated(value: float)

func _ready() -> void:
	camera_2d.zoom = Vector2(max_zoom_amount, max_zoom_amount)
	speed_meter = max_meter_value / 2.0
	meter_updated.emit(speed_meter)

func _physics_process(delta: float) -> void:
	if is_frozen:
		velocity = Vector2.ZERO
		return
	
	coyote_time += delta
	
	check_for_finish_line()
	
	if is_on_floor() or coyote_time <= coyote_time_amount:
		gpu_particles_2d.emitting = true
		air_jump = true
		target_tilt = 0
		if velocity.x <= max_speed:
			velocity.x = move_toward(velocity.x, max_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, max_speed, friction * delta)
		
		if velocity.x > slow_speed_threshold:
			speed_meter = min(speed_meter + meter_recovery_rate * delta, max_meter_value)
			meter_updated.emit(speed_meter)
		
		if velocity.x < slow_speed_threshold and velocity.x > 0:
			speed_meter = max(speed_meter - meter_decrease_on_slow * delta, 0)
			meter_updated.emit(speed_meter)
			# Check if meter reached 0
			if speed_meter <= 0:
				freeze_penguin()
				return
		
		if Input.is_action_just_pressed("ui_up"):
			velocity.y = -jump_force
	else:
		gpu_particles_2d.emitting = false
		target_tilt = clamp(velocity.y / 4, -30, 30)
		
		velocity.x = move_toward(velocity.x, 0, air_friction * delta)
		
		var current_speed = velocity.length()
		if current_speed < slow_speed_threshold:
			speed_meter = max(speed_meter - meter_decrease_on_slow * delta * 0.5, 0)
			meter_updated.emit(speed_meter)
			# Check if meter reached 0
			if speed_meter <= 0:
				freeze_penguin()
				return
		
		if Input.is_action_just_pressed("ui_up") and air_jump:
			velocity.y = -jump_force
			velocity.x -= air_jump_speed_reduction * delta
			air_jump = false
			var tween = create_tween()
			tween.tween_property(sprite_2d, "rotation_degrees", 0, 0.4).from(360 + sprite_2d.rotation_degrees)
		
		if Input.is_action_just_released("ui_up"):
			velocity.y = unjump_force
		
		if velocity.y > 0:
			velocity.y += down_gravity * delta
		else:
			velocity.y += up_gravity * delta
	
	var previous_velocity = velocity
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		
		# Check if it's a wall collision (normal pointing left/right, not up/down)
		# Wall has normal.x close to 1 or -1, and normal.y close to 0
		if abs(normal.x) > 0.7 and abs(normal.y) < 0.5:
			print("[v0] Wall collision detected! Normal: ", normal)
			speed_meter = 0.0
			meter_updated.emit(speed_meter)
			freeze_penguin()
			return
	
	var just_left_ledge = was_on_floor and not is_on_floor() and velocity.y >= 0
	
	if just_left_ledge:
		coyote_time = 0
	
	if velocity.y == 0 and previous_velocity.y > 5:
		anchor.scale = Vector2(1.5, 0.8)
		velocity.x += landing_acceleration * delta
	
	sprite_2d.rotation_degrees = lerp(sprite_2d.rotation_degrees, target_tilt, 0.2)
	anchor.scale = anchor.scale.lerp(Vector2.ONE, 0.05)
	
	var y_offset_target: float = clamp(ray_cast_2d.get_collision_point().y - global_position.y, -16, 128)
	camera_2d.offset.y = lerp(camera_2d.offset.y, y_offset_target, 0.02)
	
	var x_offset_target: float = clamp(velocity.x, 64, 128)
	camera_2d.offset.x = lerp(camera_2d.offset.x, x_offset_target, 0.02)
	
	var zoom_target_amount: float = clamp(max_zoom_amount - (velocity.x / 150), min_zoom_amount, max_zoom_amount)
	var zoom_target: Vector2 = Vector2(zoom_target_amount, zoom_target_amount)
	camera_2d.zoom = camera_2d.zoom.lerp(zoom_target, 0.02)

func freeze_penguin() -> void:
	print("[v0] Penguin frozen! Game Over")
	is_frozen = true
	velocity = Vector2.ZERO
	
	gpu_particles_2d.emitting = false
	gpu_particles_2d.visible = false
	
	sprite_2d.texture = frozen_texture
	sprite_2d.hframes = 1
	sprite_2d.frame = 0

func check_for_finish_line() -> void:
	if global_position.x > finish_x and finish_x != -1:
		level_finished.emit()
		gpu_particles_2d.set_deferred("emitting", false)
