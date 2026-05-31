# WaveManager v2 - 波次管理器 (网格版)
# 敌人在起点生成，不再使用 Path2D

class_name WaveManager
extends Node

var wave_data: Array = []
var current_wave_index: int = 0
var enemies_to_spawn: int = 0
var spawn_interval: float = 1.0
var spawn_timer: float = 0.0
var wave_delay: float = 5.0
var wave_delay_timer: float = 0.0
var is_wave_active: bool = false
var is_spawning: bool = false
var all_waves_complete: bool = false

var spawn_queue: Array = []
var current_spawn_entry: Dictionary = {}
var current_spawn_count: int = 0

@export var enemy_container: NodePath
@export var spawn_world_pos: Vector2 = Vector2(136, 72)  # 起点世界坐标

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal all_waves_finished()
signal wave_ready()

func _ready() -> void:
	wave_delay_timer = wave_delay

func _process(delta: float) -> void:
	if GameState.game_over or GameState.game_paused:
		return
	if all_waves_complete:
		return

	if not is_wave_active:
		return  # 等待手动点击「开始波次」

	if is_spawning:
		spawn_timer -= delta
		if spawn_timer <= 0:
			_spawn_one_enemy()
			spawn_timer = current_spawn_entry.get("interval", 1.0)

	# 当前波次生成完毕 + 场上敌人清空 → 波次结束
	if not is_spawning and current_wave_index > 0 and _all_enemies_cleared():
		_end_current_wave()

func _end_current_wave() -> void:
	is_wave_active = false
	GameState.wave_active = false
	wave_completed.emit(current_wave_index - 1)
	
	# 检查是否所有波次完成
	if current_wave_index >= wave_data.size():
		all_waves_complete = true
		all_waves_finished.emit()
	else:
		# 恢复按钮，等待下一波
		wave_ready.emit()

func load_wave_data(data: Array) -> void:
	wave_data = data
	GameState.total_waves = wave_data.size()
	current_wave_index = 0
	wave_delay_timer = 3.0

func start_wave() -> void:
	_start_next_wave()

func _start_next_wave() -> void:
	if current_wave_index >= wave_data.size():
		all_waves_complete = true
		all_waves_finished.emit()
		return

	is_wave_active = true
	GameState.current_wave = current_wave_index + 1
	GameState.wave_active = true
	wave_started.emit(current_wave_index)

	var wave_entry = wave_data[current_wave_index]
	spawn_queue.clear()
	for group in wave_entry:
		spawn_queue.append({
			"path": group["path"],
			"count": group["count"],
			"interval": group["interval"],
			"tier": group.get("tier", 1)
		})
	_advance_spawn_queue()

func _advance_spawn_queue() -> void:
	if spawn_queue.is_empty():
		is_spawning = false
		return
	current_spawn_entry = spawn_queue.pop_front()
	current_spawn_count = 0
	spawn_timer = 0.0
	is_spawning = true

func _spawn_one_enemy() -> void:
	if current_spawn_count >= current_spawn_entry.get("count", 0):
		_advance_spawn_queue()
		if not is_spawning:
			return
		spawn_timer = current_spawn_entry.get("interval", 1.0)
		return

	var script_path = current_spawn_entry["path"]
	var enemy_script = load(script_path)
	if not enemy_script:
		push_error("无法加载: " + script_path)
		return

	var enemy = Node2D.new()
	enemy.set_script(enemy_script)
	if not enemy is EnemyBase:
		enemy.queue_free()
		return

	# 设置层级
	if "tier" in current_spawn_entry:
		enemy.set("tier", current_spawn_entry["tier"])

	# 设置位置到起点
	enemy.global_position = spawn_world_pos
	enemy.add_to_group("enemy")

	# 获取 GameGrid 并初始化寻路
	var grid_map = get_tree().get_first_node_in_group("grid_map")
	if grid_map and "find_path" in grid_map:
		enemy.setup(grid_map)

	var parent = get_node(enemy_container) if enemy_container else get_parent()
	parent.add_child(enemy)

	current_spawn_count += 1

func _all_enemies_cleared() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			return false
	return true

func get_enemies_remaining() -> int:
	var count = 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			count += 1
	return count
