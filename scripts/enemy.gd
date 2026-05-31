# Enemy - 敌人基类 v2 (网格版)
# 沿 A* 寻路路径移动，不再使用 PathFollow2D

class_name EnemyBase
extends Node2D

# 基础属性
@export var enemy_name: String = "未知敌人"
@export var max_health: float = 100.0
@export var speed: float = 120.0           # 像素/秒
@export var armor: float = 0.0
@export var reward_crystals: int = 10
@export var damage_to_base: int = 1

# 运行状态
var current_health: float
var is_dead: bool = false
var is_visible_target: bool = true

# 寻路
var path: Array[Vector2i] = []             # 当前路径（网格坐标列表）
var path_index: int = 0
var target_world_pos: Vector2
var grid_map = null

# 减速/DOT 状态
var slowed: bool = false
var slow_timer: float = 0.0
var slow_factor: float = 1.0
var dot_damage: float = 0.0
var dot_timer: float = 0.0

# 信号
signal enemy_died(enemy: EnemyBase)
signal enemy_reached_end(enemy: EnemyBase)

func _ready() -> void:
	current_health = max_health
	# 基础视觉大小
	queue_redraw()

func setup(grid) -> void:
	grid_map = grid
	_recalculate_path()

func _process(delta: float) -> void:
	if is_dead or GameState.game_over or GameState.game_paused:
		return

	# 处理减速
	if slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			slowed = false
			slow_factor = 1.0

	# 处理 DOT
	if dot_damage > 0:
		dot_timer -= delta
		if dot_timer <= 0:
			take_damage(dot_damage, true)
			dot_timer = 1.0

	# 沿路径移动
	_move_along_path(delta)

func _move_along_path(delta: float) -> void:
	if path_index >= path.size():
		# 到达终点
		reached_end()
		return

	target_world_pos = grid_map.cell_to_world(path[path_index])
	var dist = global_position.distance_to(target_world_pos)
	var step = speed * slow_factor * delta

	if dist <= step:
		# 到达当前节点，前进到下一个
		global_position = target_world_pos
		path_index += 1
		if path_index >= path.size():
			reached_end()
	else:
		# 向目标移动
		global_position = global_position.move_toward(target_world_pos, step)

func _recalculate_path() -> void:
	if not grid_map:
		return
	# 找到当前最近的网格位置
	var current_cell = grid_map.world_to_cell(global_position)
	path = grid_map.find_path(current_cell, Vector2i(21, 12))
	path_index = 0
	# 跳过第一个节点（当前位置）
	if path.size() > 0:
		path_index = 1

func recalculate_path() -> void:
	_recalculate_path()

func take_damage(damage: float, is_dot: bool = false) -> void:
	if is_dead:
		return
	var actual_damage = damage * (1.0 - armor)
	current_health -= actual_damage
	queue_redraw()
	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	GameState.add_crystals(reward_crystals)
	enemy_died.emit(self)
	queue_free()

func reached_end() -> void:
	if is_dead:
		return
	is_dead = true
	GameState.lose_life(damage_to_base)
	enemy_reached_end.emit(self)
	queue_free()

func apply_slow(factor: float, duration: float) -> void:
	slowed = true
	slow_factor = factor
	slow_timer = duration

func apply_dot(damage_per_sec: float, duration: float) -> void:
	dot_damage = damage_per_sec
	dot_timer = 1.0
	get_tree().create_timer(duration).timeout.connect(_clear_dot)

func _clear_dot() -> void:
	dot_damage = 0.0

func _draw() -> void:
	var color = Color.RED
	var radius = 8.0
	match enemy_name:
		"虚粒子":
			color = Color(0.6, 0.3, 1.0, 0.8)
			radius = 7.0
		"自由电子":
			color = Color(0.3, 0.8, 1.0, 0.9)
			radius = 5.0
		"质子团":
			color = Color(1.0, 0.6, 0.2, 0.8)
			radius = 11.0
		"量子纠缠对":
			color = Color(1.0, 0.2, 0.2, 0.9)
			radius = 14.0

	if not is_visible_target:
		color.a *= 0.25

	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius, Color.WHITE, false, 1.0)

	# 血条（始终显示）
	var bar_width = radius * 2.5
	var bar_height = 3.0
	var bar_y = -radius - 10
	var hp_ratio = current_health / max_health
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width, bar_height), Color(0.3, 0.1, 0.1))
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width * hp_ratio, bar_height), Color.RED if hp_ratio < 0.3 else Color.GREEN)

	# 血量数字
	if GameState.show_hp_numbers:
		var hp_text = "%d/%d" % [max(0, int(ceil(current_health))), int(max_health)]
		draw_string(ThemeDB.fallback_font, Vector2(-16, bar_y - 4), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
