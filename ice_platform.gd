extends StaticBody2D

class_name IcePlatform

# Velocidad mínima de caída para romper la plataforma
@export var break_velocity_threshold: float = 150.0
# Velocidad de caída cuando se rompe
@export var fall_speed: float = 100.0
# Duración del desvanecimiento
@export var fade_duration: float = 1.0

var is_broken: bool = false
var fall_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea

func _ready() -> void:
	# Conectar la señal del área de detección
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		print("[v0] Plataforma de hielo lista")

func _physics_process(delta: float) -> void:
	if is_broken:
		# Hacer caer la plataforma
		position.y += fall_speed * delta
		fall_timer += delta
		
		# Desvanecer gradualmente
		if sprite:
			sprite.modulate.a = 1.0 - (fall_timer / fade_duration)
		
		# Eliminar cuando esté completamente desvanecida
		if fall_timer >= fade_duration:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_broken:
		return
	
	# Verificar si es el jugador
	if body is Player:
		var player = body as Player
		
		# Obtener la velocidad vertical del jugador
		var impact_velocity = abs(player.velocity.y)
		
		print("[v0] Impacto detectado - Velocidad: ", impact_velocity)
		
		# Si el impacto es suficientemente fuerte, romper la plataforma
		if impact_velocity >= break_velocity_threshold:
			break_platform()
		else:
			print("[v0] Impacto muy débil, plataforma intacta")

func break_platform() -> void:
	if is_broken:
		return
	
	print("[v0] ¡Plataforma rota!")
	is_broken = true
	
	# Cambiar sprite a hielo roto
	if sprite:
		var broken_texture = load("res://textures/ice_shard.png")
		if broken_texture:
			sprite.texture = broken_texture
	
	# Desactivar colisión para que el jugador caiga a través
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Desactivar el área de detección
	if detection_area:
		detection_area.monitoring = false
