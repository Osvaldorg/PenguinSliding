extends Node2D

@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var player: Player = $Player
@onready var meter_container: Control = $CanvasLayer/MeterContainer
@onready var meter_full: TextureRect = $CanvasLayer/MeterContainer/MeterFull
@onready var meter_empty: TextureRect = $CanvasLayer/MeterContainer/MeterEmpty

var time: = 0.0
var is_timer_running: = true

func _ready() -> void:
	player.level_finished.connect(finish_level)
	player.meter_updated.connect(update_meter_display)

func _process(delta: float) -> void:
	if is_timer_running:
		time += delta
		timer_label.text = "%.2f" % time
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().reload_current_scene()

func update_meter_display(value: float) -> void:
	print("[v0] Meter updated to: ", value, " (", (value / player.max_meter_value * 100), "%)")
	var percentage = value / player.max_meter_value
	# Clip the meter_full texture to show only the filled portion
	if meter_full and meter_full.material:
		meter_full.material.set_shader_parameter("fill_amount", percentage)
	else:
		print("[v0] ERROR: meter_full or material is null!")

func finish_level() -> void:
	player.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	is_timer_running = false
