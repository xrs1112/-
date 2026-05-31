# WaveManager v3 - 支持多波同时进行
class_name WaveManager
extends Node

var wave_data: Array = []
var next_spawn_index: int = 0     # 下一波要生成的索引
var completed_waves: int = 0      # 已完成的波次
var active_spawns: Array = []     # 活跃的生成队列

var wave_delay: float = 60.0
var countdown_timer: float = 0.0
var is_countdown: bool = false
var all_waves_finished: bool = false

@export var enemy_container: NodePath
@export var spawn_world_pos: Vector2 = Vector2(136, 72)

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal all_waves_finished_signal()
signal wave_ready()
signal countdown_changed(remaining: float)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if GameState.game_over or GameState.game_paused:
		return
	if all_waves_finished:
		return

	# 处理倒计时
	if is_countdown:
		countdown_timer -= delta
		countdown_changed.emit(max(countdown_timer, 0.0))
		if countdown_timer <= 0:
			is_countdown = false
			start_wave()
		return

	# 处理活跃生成队列
	for spawn in active_spawns:
		spawn["timer"] -= delta
		if spawn["timer"] <= 0 and spawn["remaining"] > 0:
			_spawn_one(spawn)
			spawn["timer"] = spawn["interval"]

	# 清理已完成的队列
	active_spawns = active_spawns.filter(func(s): return s["remaining"] > 0)

	# 所有队列空 + 场上无敌方 → 已启动波次完成
	if active_spawns.is_empty() and _all_enemies_cleared():
		if completed_waves < next_spawn_index:
			while completed_waves < next_spawn_index:
				completed_waves += 1
				wave_completed.emit(completed_waves)
			_check_done()

func load_wave_data(data: Array) -> void:
	wave_data = data
	GameState.total_waves = wave_data.size()
	GameState.current_wave = 0
	GameState.wave_active = false
	next_spawn_index = 0
	completed_waves = 0
	active_spawns.clear()
	is_countdown = false
	all_waves_finished = false
	GameState.wave_changed.emit(GameState.current_wave)

func start_wave() -> void:
	if next_spawn_index >= wave_data.size():
		return

	is_countdown = false
	countdown_timer = 0

	var groups = wave_data[next_spawn_index]
	for g in groups:
		active_spawns.append({
			"script": g["path"],
			"interval": g["interval"],
			"timer": 0.0,
			"remaining": g["count"],
			"tier": g.get("tier", 1),
		})

	GameState.current_wave = next_spawn_index + 1
	GameState.wave_active = true
	GameState.wave_changed.emit(GameState.current_wave)
	wave_started.emit(next_spawn_index)
	next_spawn_index += 1

func _spawn_one(spawn: Dictionary) -> void:
	var script = load(spawn["script"])
	if not script:
		push_error("无法加载敌人脚本: " + str(spawn["script"]))
		spawn["remaining"] = 0
		return

	var enemy = Node2D.new()
	enemy.set_script(script)
	if not enemy is EnemyBase:
		push_error("敌人脚本不是 EnemyBase: " + str(spawn["script"]))
		enemy.queue_free()
		spawn["remaining"] = 0
		return

	if "tier" in spawn:
		enemy.set("tier", spawn["tier"])

	enemy.global_position = spawn_world_pos
	enemy.add_to_group("enemy")

	var grid_map = get_tree().get_first_node_in_group("grid_map")
	if grid_map and grid_map.has_method("find_path"):
		enemy.setup(grid_map, randi())

	var parent = get_node_or_null(enemy_container) if not enemy_container.is_empty() else get_parent()
	if parent == null:
		parent = get_parent()
	parent.add_child(enemy)

	spawn["remaining"] -= 1

func _all_enemies_cleared() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			return false
	return true

func _check_done() -> void:
	GameState.wave_active = false
	if next_spawn_index >= wave_data.size() and completed_waves >= wave_data.size():
		all_waves_finished = true
		all_waves_finished_signal.emit()
	elif completed_waves >= next_spawn_index - 1 and active_spawns.is_empty():
		# 当前波完成，开始倒计时；玩家可点击按钮提前开始下一波。
		is_countdown = true
		countdown_timer = wave_delay
		countdown_changed.emit(countdown_timer)
		wave_ready.emit()
