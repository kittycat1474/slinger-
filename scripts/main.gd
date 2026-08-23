extends Node2D

@onready var game_manager: GameManager = $GameManager
@onready var defeated_label: Label = $UI/Margin/TopBar/Defeated
@onready var camera: Camera2D = $Camera2D
@onready var wolf_spawner: WolfSpawner = $WolfSpawner
@onready var boss_ui: VBoxContainer = $UI/BossUI
@onready var boss_health: ProgressBar = $UI/BossUI/BossHealth
@onready var victory_screen: ColorRect = $UI/VictoryScreen
@onready var defeat_screen: ColorRect = $UI/DefeatScreen
@onready var hearts_label: Label = $UI/Margin/TopBar/Hearts
@onready var chicken: ChickenMama = $ChickenMama

var shake_strength: float = 0.0

func _ready() -> void:
	game_manager.defeated_count_changed.connect(_on_defeated_count_changed)
	game_manager.lives_changed.connect(_on_lives_changed)
	game_manager.game_failed.connect(_on_game_failed)
	wolf_spawner.boss_spawned.connect(_on_boss_spawned)
	$UI/VictoryScreen/Panel/Content/PlayAgain.pressed.connect(game_manager.reset_game)
	$UI/VictoryScreen/Panel/Content/Quit.pressed.connect(get_tree().quit)
	$UI/DefeatScreen/Panel/Content/PlayAgain.pressed.connect(game_manager.reset_game)
	$UI/DefeatScreen/Panel/Content/Quit.pressed.connect(get_tree().quit)
	get_tree().node_added.connect(_on_node_added)
	_on_lives_changed(game_manager.lives, game_manager.max_lives)
	queue_redraw()

func _draw() -> void:
	# Soft portrait arena with converging lane guides for faux depth.
	draw_rect(Rect2(0, 0, 1080, 1920), Color("#9bd7dc"))
	draw_colored_polygon(PackedVector2Array([Vector2(190, 1920), Vector2(400, 150), Vector2(680, 150), Vector2(890, 1920)]), Color("#c9df9b"))
	for x: float in [330.0, 540.0, 750.0]:
		draw_line(Vector2(540, 130), Vector2(x, 1760), Color(1, 1, 1, 0.16), 5.0)
	draw_circle(Vector2(905, 195), 88.0, Color("#fff2a6"))

func _process(delta: float) -> void:
	shake_strength = move_toward(shake_strength, 0.0, 20.0 * delta)
	camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))

func request_shake(strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)

func _on_defeated_count_changed(count: int) -> void:
	defeated_label.text = "WOLVES DEFEATED: %d" % count
	request_shake(9.0)

func _on_node_added(node: Node) -> void:
	if node is Wolf:
		var wolf := node as Wolf
		wolf.defeated.connect(func() -> void: _on_wolf_defeated(wolf))
		(node as Wolf).hit_feedback.connect(func() -> void: request_shake(3.5))
		wolf.attacked_chicken.connect(_on_wolf_attacked_chicken)

func _on_wolf_defeated(wolf: Wolf) -> void:
	if wolf.is_boss:
		boss_ui.hide()
		victory_screen.show()
		get_tree().paused = true
	else:
		game_manager.register_wolf_defeated()
		wolf_spawner.register_normal_defeat()

func _on_boss_spawned(boss: Wolf) -> void:
	boss_ui.show()
	boss_health.max_value = boss.max_hp
	boss_health.value = boss.hp
	boss.health_changed.connect(func(current: int, maximum: int) -> void:
		boss_health.max_value = maximum
		boss_health.value = current
	)
	request_shake(13.0)

func _on_wolf_attacked_chicken(wolf: Wolf) -> void:
	if wolf.is_boss:
		game_manager.fail_immediately()
		return
	if game_manager.take_damage():
		chicken.play_hit_feedback()
		request_shake(8.0)

func _on_lives_changed(current: int, maximum: int) -> void:
	var display := ""
	for i: int in maximum:
		display += "♥" if i < current else "♡"
	hearts_label.text = display

func _on_game_failed() -> void:
	request_shake(16.0)
	defeat_screen.show()
	get_tree().paused = true
