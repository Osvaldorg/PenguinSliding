extends Area2D

class_name Cannon

# Configuración del cañón
@export var launch_force: float = 400.0  # Fuerza de lanzamiento
@export var launch_angle: float = 10.0  # Ángulo de lanzamiento en grados
@export var charge_time: float = .1  # Tiempo de carga en segundos
@export var enabled: bool = true  # Si el cañón está habilitado
@export var starts_disabled: bool = false  # Si empieza deshabilitado (para switches)

# Referencias a los nodos
@onready var cannon_center: Sprite2D = $CannonCenter
@onready var cannon_end: Sprite2D = $CannonEnd
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Estado del cañón
var is_charging: bool = false
var charge_timer: float = 0.0
var captured_player: Player = null

# Escalas originales
var center_original_scale: Vector2
var end_original_scale: Vector2

func _ready() -> void:
	if starts_disabled:
		enabled = false
		set_visual_state(false)
	
	# Guardar escalas originales
	if cannon_center:
		center_original_scale = cannon_center.scale
	if cannon_end:
		end_original_scale = cannon_end.scale
	
	# Conectar señales
	body_entered.connect(_on_body_entered)
	
	print("[v0] Cañón listo - Fuerza: ", launch_force, " Ángulo: ", launch_angle, " Habilitado: ", enabled)

func _physics_process(delta: float) -> void:
	if is_charging and captured_player:
		charge_timer += delta
		
		# Animación de escalamiento durante la carga
		var progress = charge_timer / charge_time
		
		# Escalar cannon_center (se expande durante la carga)
		if cannon_center:
			var scale_factor = 1.0 + (progress * 0.2)  # Crece hasta 1.3x
			cannon_center.scale = center_original_scale * scale_factor
		
		# Mantener al jugador en posición
		if captured_player:
			captured_player.velocity = Vector2.ZERO
			captured_player.global_position = global_position
		
		# Cuando termine la carga, lanzar
		if charge_timer >= charge_time:
			launch_player()

func _on_body_entered(body: Node2D) -> void:
	if not enabled or is_charging:
		return
	
	# Verificar si es el jugador
	if body is Player:
		capture_player(body as Player)

func capture_player(player: Player) -> void:
	print("[v0] Pingüino capturado por el cañón")
	captured_player = player
	is_charging = true
	charge_timer = 0.0
	
	# Detener al jugador
	player.velocity = Vector2.ZERO
	
	# Desactivar el control del jugador temporalmente
	player.set_physics_process(false)

func launch_player() -> void:
	if not captured_player:
		return
	
	print("[v0] ¡Lanzando pingüino!")
	
	# Animación de retroceso (recoil) del cañón
	if cannon_end:
		var tween = create_tween()
		
		# Calcular dirección del cañón para moverlo hacia atrás
		var recoil_distance = 7.0  # Distancia de retroceso en píxeles
		var angle_rad = deg_to_rad(launch_angle)
		var recoil_direction = Vector2(-cos(angle_rad), sin(angle_rad))  # Hacia atrás del disparo
		
		var original_position = cannon_end.position
		var recoil_position = original_position + recoil_direction * recoil_distance
		
		# Movimiento hacia atrás rápido
		tween.tween_property(cannon_end, "position", recoil_position, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Regreso suave a su posición original
		tween.tween_property(cannon_end, "position", original_position, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Calcular dirección de lanzamiento
	var angle_rad = deg_to_rad(launch_angle)
	var launch_direction = Vector2(cos(angle_rad), -sin(angle_rad))
	
	# Aplicar fuerza de lanzamiento
	captured_player.velocity = launch_direction * launch_force
	
	# Reactivar el control del jugador
	captured_player.set_physics_process(true)
	
	# Resetear el cañón
	reset_cannon()

func reset_cannon() -> void:
	is_charging = false
	charge_timer = 0.0
	captured_player = null
	
	# Restaurar escalas originales
	if cannon_center:
		cannon_center.scale = center_original_scale
	if cannon_end:
		cannon_end.scale = end_original_scale
	
	print("[v0] Cañón reseteado")

func enable() -> void:
	enabled = true
	set_visual_state(true)
	print("[v0] Cañón habilitado")

func disable() -> void:
	enabled = false
	set_visual_state(false)
	print("[v0] Cañón deshabilitado")

func set_visual_state(is_enabled: bool) -> void:
	# Cambiar opacidad para indicar estado
	var alpha = 1.0 if is_enabled else 0.3
	if cannon_center:
		cannon_center.modulate.a = alpha
	if cannon_end:
		cannon_end.modulate.a = alpha
