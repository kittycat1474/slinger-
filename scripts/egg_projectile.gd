class_name EggProjectile
extends Node2D

@export var flight_duration: float = 0.38
@export var arc_height: float = 190.0

var target: Wolf
var start_position: Vector2
var elapsed: float = 0.0

func launch(new_target: Wolf) -> void:
	target = new_target
	start_position = global_position
	z_index = 3000

func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_defeated:
		queue_free()
		return
	elapsed += delta
	var progress := clampf(elapsed / flight_duration, 0.0, 1.0)
	# Homing endpoint keeps the prototype punchy while retaining a deterministic arc.
	var endpoint := target.global_position + Vector2(0, -35)
	global_position = start_position.lerp(endpoint, progress) + Vector2.UP * sin(progress * PI) * arc_height
	rotation += delta * 9.0
	scale = Vector2.ONE * lerpf(0.75, 1.25, sin(progress * PI))
	queue_redraw()
	if progress >= 1.0:
		target.take_hit()
		queue_free()

func _draw() -> void:
	draw_ellipse(Vector2.ZERO, 20.0, 29.0, Color("#fffdf2"))
	draw_arc(Vector2(-5, -7), 9.0, PI, TAU, 10, Color(1, 1, 1, 0.75), 4.0)
