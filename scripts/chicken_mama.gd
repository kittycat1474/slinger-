class_name ChickenMama
extends Node2D

@export var follow_speed: float = 9.0
@export var left_limit: float = 190.0
@export var right_limit: float = 890.0
@export var attack_width: float = 260.0
@export var attack_range: float = 1160.0
@export var attack_interval: float = 0.52
@export var release_delay: float = 0.18
@export var egg_scene: PackedScene

@onready var projectile_layer: Node2D = get_node("../ProjectileLayer")

var target_x: float
var dragging: bool = false
var drag_pointer_id: int = -1
var attack_cooldown: float = 0.2
var attack_target: Wolf
var throwing: bool = false
var throw_time: float = 0.0
var facing_motion: float = 0.0
var show_attack_zone: bool = false
var hit_flash_time: float = 0.0

func _ready() -> void:
	add_to_group("chicken_mama")
	target_x = position.x
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_attack_zone"):
		show_attack_zone = not show_attack_zone
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			target_x = event.position.x
	elif event is InputEventMouseMotion and dragging:
		target_x = event.position.x
	elif event is InputEventScreenTouch:
		if event.pressed and drag_pointer_id == -1:
			drag_pointer_id = event.index
			dragging = true
			target_x = event.position.x
		elif not event.pressed and event.index == drag_pointer_id:
			drag_pointer_id = -1
			dragging = false
	elif event is InputEventScreenDrag and event.index == drag_pointer_id:
		target_x = event.position.x

func _process(delta: float) -> void:
	hit_flash_time = maxf(0.0, hit_flash_time - delta)
	var previous_x: float = position.x
	position.x = lerpf(position.x, clampf(target_x, left_limit, right_limit), 1.0 - exp(-follow_speed * delta))
	facing_motion = (position.x - previous_x) / maxf(delta, 0.001)
	attack_cooldown -= delta
	if throwing:
		throw_time += delta
		if throw_time >= release_delay:
			release_egg()
	elif attack_cooldown <= 0.0:
		var target: Wolf = find_best_target()
		if target != null:
			start_attack(target)
	queue_redraw()

func play_hit_feedback() -> void:
	hit_flash_time = 0.22
	queue_redraw()

func find_best_target() -> Wolf:
	var best: Wolf
	var best_distance: float = INF
	for candidate: Node in get_tree().get_nodes_in_group("wolves"):
		if not is_instance_valid(candidate) or candidate.is_defeated:
			continue
		var wolf := candidate as Wolf
		var offset := wolf.global_position - global_position
		if offset.y < -40.0 and offset.y >= -attack_range and absf(offset.x) <= attack_width * 0.5:
			var distance := offset.length_squared()
			if distance < best_distance:
				best = wolf
				best_distance = distance
	return best

func start_attack(target: Wolf) -> void:
	attack_target = target
	throwing = true
	throw_time = 0.0
	queue_redraw()

func release_egg() -> void:
	throwing = false
	attack_cooldown = attack_interval - release_delay
	if not is_instance_valid(attack_target) or attack_target.is_defeated:
		return
	var egg := egg_scene.instantiate() as EggProjectile
	projectile_layer.add_child(egg)
	egg.global_position = global_position + Vector2(0, -245)
	egg.launch(attack_target)

func _draw() -> void:
	if show_attack_zone:
		draw_rect(Rect2(-attack_width * 0.5, -attack_range, attack_width, attack_range), Color(0.2, 0.9, 0.4, 0.16), true)
		draw_rect(Rect2(-attack_width * 0.5, -attack_range, attack_width, attack_range), Color(0.1, 0.7, 0.3, 0.65), false, 4.0)
	# Shadow, body, wings, head, beak and scarf sling.
	draw_ellipse(Vector2(0, 38), 185.0, 54.0, Color(0.12, 0.16, 0.18, 0.25))
	var body_color := Color("#ff8f8f") if hit_flash_time > 0.0 else Color("#fff3cf")
	var head_color := Color("#ffaaaa") if hit_flash_time > 0.0 else Color("#fff8dc")
	draw_circle(Vector2(0, -72), 170.0, body_color)
	draw_circle(Vector2(-116, -70), 78.0, Color("#f4cf72"))
	draw_circle(Vector2(116, -70), 78.0, Color("#f4cf72"))
	draw_circle(Vector2(0, -230), 105.0, head_color)
	draw_circle(Vector2(-35, -250), 10.0, Color("#25242c"))
	draw_circle(Vector2(35, -250), 10.0, Color("#25242c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-22, -220), Vector2(22, -220), Vector2(0, -184)]), Color("#f2a23a"))
	var lean: float = clampf(facing_motion / 900.0, -0.12, 0.12)
	var scarf_tip := Vector2((150.0 if not throwing else -205.0), -280.0 if not throwing else -340.0)
	draw_polyline(PackedVector2Array([Vector2(-75, -288), Vector2(20 + lean * 100.0, -318), scarf_tip]), Color("#d84242"), 34.0, true)
	if throwing:
		draw_arc(Vector2(0, -245), 185.0, PI * 1.05, PI * 1.85, 24, Color("#ef6666"), 16.0, true)
