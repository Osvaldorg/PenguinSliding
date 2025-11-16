extends Area2D

class_name Switch

# Cañones que este switch controla
@export var controlled_cannons: Array[NodePath] = []
# Si el switch se puede desactivar (volver a apagar)
@export var can_toggle: bool = false
# Si empieza activado
@export var starts_active: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_active: bool = false
var cannon_nodes: Array[Cannon] = []

func _ready() -> void:
	# Conectar señal
	body_entered.connect(_on_body_entered)
	
	# Obtener referencias a los cañones
	for cannon_path in controlled_cannons:
		var cannon = get_node(cannon_path) as Cannon
		if cannon:
			cannon_nodes.append(cannon)
	
	# Aplicar estado inicial
	is_active = starts_active
	update_visual_state()
	update_cannons_state()
	
	print("[v0] Switch listo - Controla ", cannon_nodes.size(), " cañones")

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Si puede hacer toggle, cambiar estado
		if can_toggle:
			toggle()
		# Si no puede hacer toggle y ya está activo, no hacer nada
		elif not is_active:
			activate()

func activate() -> void:
	if is_active:
		return
	
	print("[v0] Switch activado")
	is_active = true
	update_visual_state()
	update_cannons_state()
	
	# Reproducir sonido si existe
	if has_node("AudioStreamPlayer2D"):
		$AudioStreamPlayer2D.play()

func deactivate() -> void:
	if not is_active:
		return
	
	print("[v0] Switch desactivado")
	is_active = false
	update_visual_state()
	update_cannons_state()

func toggle() -> void:
	if is_active:
		deactivate()
	else:
		activate()

func update_visual_state() -> void:
	if not sprite:
		return
	
	# Voltear el sprite según el estado
	# Izquierda = desactivado, Derecha = activado
	sprite.flip_h = is_active

func update_cannons_state() -> void:
	for cannon in cannon_nodes:
		if is_active:
			cannon.enable()
		else:
			cannon.disable()
