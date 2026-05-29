# WaveManager - 波次管理器
# 管理敌人波次的生成和时机

class_name WaveManager
extends Node

# 波次数据：每个波次是一个数组 [敌人场景路径, 数量, 间隔(秒)]
var wave_data: Array = []
var current_wave_index: int = 0
var enemies_to_spawn: int = 0
var spawn_interval: float = 1.0
var spawn_timer: float = 0.0
var wave_delay: float = 5.0         # 波次间休息时间
var wave_delay_timer: float = 0.0
var is_wave_active: bool = false
var is_spawning: bool = false
var all_waves_complete: bool = false

# 存储当前波次要生成的敌人
var spawn_queue: Array = []   # [{path, count, interval}]
var current_spawn_entry: Dictionary = {}
var current_spawn_count: int = 0

# 引用
@export var enemy_parent: NodePath          # 敌人放置的父节点
@export var enemy_path: Path2D              # 敌人跟随的路径
@export var spawn_to_path_delay: float = 0.1

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal all_waves_finished()

func _ready() -> void:
	wave_delay_timer = wave_delay

func _process(delta: float) -> void:
	if GameState.game_over or GameState.game_paused:
		return
	if all_waves_complete:
		return

	# 波次间等待
	if not is_wave_active:
		wave_delay_timer -= delta
		if wave_delay_timer <= 0:
			_start_next_wave()
		return

	# 生成敌人
	if is_spawning:
		spawn_timer -= delta
		if spawn_timer <= 0:
			_spawn_one_enemy()
			spawn_timer = current_spawn_entry.get("interval", 1.0)

	# 所有波次完成后，检查场上敌人是否清空
	if all_waves_complete and _all_enemies_cleared() and not GameState.game_over:
		GameState.trigger_game_over(true)

func load_wave_data(data: Array) -> void:
	wave_data = data
	GameState.total_waves = wave_data.size()
	current_wave_index = 0
	wave_delay_timer = 3.0  # 第一波前等待较短

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

	# 构建生成队列
	var wave_entry = wave_data[current_wave_index]
	spawn_queue.clear()
	for group in wave_entry:
		spawn_queue.append({
			"path": group[0],
			"count": group[1],
			"interval": group[2]
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
		push_error("无法加载敌人脚本: " + script_path)
		return

	# 程序化创建敌人：PathFollow2D + 脚本
	var enemy = PathFollow2D.new()
	enemy.set_script(enemy_script)
	enemy_path.add_child(enemy)

	current_spawn_count += 1

func _end_current_wave() -> void:
	is_wave_active = false
	GameState.wave_active = false
	wave_completed.emit(current_wave_index)

	current_wave_index += 1
	wave_delay_timer = wave_delay

func _all_enemies_cleared() -> bool:
	if not enemy_path:
		return true
	for child in enemy_path.get_children():
		if child is EnemyBase and not child.is_dead:
			return false
	return true

func get_enemies_remaining() -> int:
	var count = 0
	if not enemy_path:
		return 0
	for child in enemy_path.get_children():
		if child is EnemyBase and not child.is_dead:
			count += 1
	return count
