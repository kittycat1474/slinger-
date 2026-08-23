class_name Wolf
extends Node2D

signal defeated
signal hit_feedback
signal health_changed(current: int, maximum: int)
signal attacked_chicken(attacker: Wolf)

@export var max_hp: int = 3
@export var far_speed: float = 135.0
@export var near_speed: float = 275.0
@export var spawn_y: float = 210.0
@export var danger_y: float = 1570.0
@export var far_scale: float = 0.45
@export var near_scale: float = 1.25
@export var chase_trigger_distance: float = 285.0
@export var contact_distance: float = 145.0
@export var attack_interval: float = 1.1
@export var close_chase_speed: float = 185.0

var hp: int
var target_x: float = 540.0
var is_defeated: bool = false
var stun_time: float = 0.0
var defeat_time: float = 0.0
var flash_time: float = 0.0
var base_rotation: float = 0.0
var is_boss: bool = false
var attack_cooldown: float = 0.0
var chicken: ChickenMama

func _ready() -> void:
	hp = max_hp
	add_to_group("wolves")
	chicken = get_tree().get_first_node_in_group("chicken_mama") as ChickenMama
	update_depth()

func setup(destination_x: float, source_y: float, end_y: float) -> void:
	target_x = destination_x
	spawn_y = source_y
	danger_y = end_y

func setup_boss(destination_x: float, source_y: float, end_y: float) -> void:
	is_boss = true
	max_hp = 10
	hp = max_hp
	far_speed = 75.0
	near_speed = 145.0
	far_scale = 0.68
	near_scale = 1.75
	close_chase_speed = 105.0
	contact_distance = 205.0
	setup(destination_x, source_y, end_y)
	health_changed.emit(hp, max_hp)
	queue_redraw()

func _process(delta: float) -> void:
	flash_time = maxf(0.0, flash_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if is_defeated:
		defeat_time += delta
		position.y -= 330.0 * delta
		rotation += 5.5 * delta
		modulate.a = maxf(0.0, 1.0 - defeat_time / 0.55)
		scale *= 1.0 + 0.7 * delta
		if defeat_time >= 0.55:
			queue_free()
		return
	if stun_time > 0.0:
		stun_time -= delta
	else:
		move_toward_chicken(delta)
	update_depth()
	queue_redraw()

func move_toward_chicken(delta: float) -> void:
	if not is_instance_valid(chicken):
		return
	var desired_contact := chicken.global_position + Vector2(0.0, -65.0)
	var distance_to_chicken := global_position.distance_to(desired_contact)
	if distance_to_chicken <= contact_distance:
		if attack_cooldown <= 0.0:
			perform_attack(desired_contact)
		return
	if global_position.y >= chicken.global_position.y - chase_trigger_distance:
		global_position = global_position.move_toward(desired_contact, close_chase_speed * delta)
	else:
		var progress := get_depth_progress()
		var speed := lerpf(far_speed, near_speed, progress)
		position.y += speed * delta
		position.x = move_toward(position.x, target_x, speed * 0.16 * delta)

func perform_attack(chicken_position: Vector2) -> void:
	attack_cooldown = attack_interval
	attacked_chicken.emit(self)
	var retreat_direction := (global_position - chicken_position).normalized()
	if retreat_direction == Vector2.ZERO:
		retreat_direction = Vector2.UP
	global_position += retreat_direction * (175.0 if is_boss else 105.0)
	stun_time = 0.2

func take_hit(damage: int = 1) -> void:
	if is_defeated:
		return
	hp -= damage
	health_changed.emit(hp, max_hp)
	flash_time = 0.11
	stun_time = 0.14
	position.y -= 62.0
	rotation = randf_range(-0.12, 0.12)
	hit_feedback.emit()
	if hp <= 0:
		is_defeated = true
		defeated.emit()
	queue_redraw()

func get_depth_progress() -> float:
	return clampf(inverse_lerp(spawn_y, danger_y, position.y), 0.0, 1.0)

func update_depth() -> void:
	var s := lerpf(far_scale, near_scale, get_depth_progress())
	scale = Vector2.ONE * s
	z_index = int(position.y)

func _draw() -> void:
	var depth := get_depth_progress()
	draw_ellipse(Vector2(0, 56), 68.0 + 22.0 * depth, 20.0 + 8.0 * depth, Color(0.08, 0.1, 0.13, 0.18 + depth * 0.16))
	var fur := Color.WHITE if flash_time > 0.0 else (Color("#41414f") if is_boss else Color("#65717d"))
	draw_circle(Vector2(0, 0), 68.0, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-60, -45), Vector2(-75, -120), Vector2(-18, -67)]), Color("#4a535d"))
	draw_colored_polygon(PackedVector2Array([Vector2(60, -45), Vector2(75, -120), Vector2(18, -67)]), Color("#4a535d"))
	draw_circle(Vector2(0, -52), 61.0, fur)
	draw_circle(Vector2(-23, -62), 7.0, Color("#ffe66f"))
	draw_circle(Vector2(23, -62), 7.0, Color("#ffe66f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -33), Vector2(14, -33), Vector2(0, -18)]), Color("#22242b"))
	if is_boss:
		draw_colored_polygon(PackedVector2Array([Vector2(-52, -133), Vector2(-37, -174), Vector2(0, -142), Vector2(37, -174), Vector2(52, -133)]), Color("#f2c84b"))
	else:
		# HP pips make repeated hits readable.
		for i: int in max_hp:
			draw_circle(Vector2(-13 + i * 26, -142), 8.0, Color("#e85050") if i < hp else Color(0.2, 0.2, 0.2, 0.35))
