class_name WolfSpawner
extends Node

signal boss_spawned(boss: Wolf)

@export var wolf_scene: PackedScene
@export var min_spawn_interval: float = 0.8
@export var max_spawn_interval: float = 1.35
@export var left_spawn_limit: float = 250.0
@export var right_spawn_limit: float = 830.0
@export var distant_spawn_y: float = 190.0
@export var destination_left: float = 170.0
@export var destination_right: float = 910.0
@export var danger_y: float = 1560.0
@export var initial_delay: float = 0.45
@export var normal_defeats_to_boss: int = 10

@onready var wolf_layer: Node2D = get_node("../WolfLayer")
var time_until_spawn: float
var normal_defeats: int = 0
var waiting_for_clear: bool = false
var boss_active: bool = false

func _ready() -> void:
	time_until_spawn = initial_delay

func _process(delta: float) -> void:
	if waiting_for_clear:
		if get_tree().get_nodes_in_group("wolves").is_empty():
			waiting_for_clear = false
			spawn_boss()
		return
	if boss_active:
		return
	time_until_spawn -= delta
	if time_until_spawn <= 0.0:
		spawn_wolf()
		time_until_spawn = randf_range(min_spawn_interval, max_spawn_interval)

func spawn_wolf() -> void:
	var wolf := wolf_scene.instantiate() as Wolf
	wolf_layer.add_child(wolf)
	wolf.position = Vector2(randf_range(left_spawn_limit, right_spawn_limit), distant_spawn_y)
	wolf.setup(randf_range(destination_left, destination_right), distant_spawn_y, danger_y)

func register_normal_defeat() -> void:
	normal_defeats += 1
	if normal_defeats >= normal_defeats_to_boss:
		waiting_for_clear = true

func spawn_boss() -> void:
	boss_active = true
	var boss := wolf_scene.instantiate() as Wolf
	wolf_layer.add_child(boss)
	boss.position = Vector2(540.0, distant_spawn_y)
	boss.setup_boss(540.0, distant_spawn_y, danger_y)
	boss_spawned.emit(boss)
