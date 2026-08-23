class_name GameManager
extends Node

signal defeated_count_changed(count: int)
signal lives_changed(current: int, maximum: int)
signal game_failed

@export var max_lives: int = 3
@export var damage_invulnerability: float = 0.6

var defeated_count: int = 0
var lives: int
var invulnerability_time: float = 0.0
var is_game_over: bool = false

func _ready() -> void:
	lives = max_lives
	lives_changed.emit(lives, max_lives)

func _process(delta: float) -> void:
	invulnerability_time = maxf(0.0, invulnerability_time - delta)

func register_wolf_defeated() -> void:
	defeated_count += 1
	defeated_count_changed.emit(defeated_count)

func take_damage(amount: int = 1) -> bool:
	if is_game_over or invulnerability_time > 0.0:
		return false
	lives = maxi(0, lives - amount)
	invulnerability_time = damage_invulnerability
	lives_changed.emit(lives, max_lives)
	if lives <= 0:
		fail_immediately()
	return true

func fail_immediately() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_failed.emit()

func reset_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		reset_game()
