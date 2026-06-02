# GridMap - 网格地图系统
# 管理地图网格、A*寻路、塔占位
class_name GameGrid
extends Node2D

# 网格参数
const CELL_SIZE: int = 42
const GRID_COLS: int = 22
const GRID_ROWS: int = 13
const GRID_OFFSET: Vector2 = Vector2(272, 72)  # 右侧主舞台，左侧留给信息舱

# 起点和终点（网格坐标）
static var START_CELL = Vector2i(0, 0)
static var GOAL_CELL = Vector2i(21, 12)

# 网格数据：0=空, 1=塔, 2=起点, 3=终点, 4=封禁区
var grid: Array = []
var blocked_rects: Array = []

# 塔引用
var tower_at_cell: Dictionary = {}   # Vector2i → TowerBase

# A* 方向（四方向移动）
const DIRS = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
const MAP_RECT := Rect2(GRID_OFFSET, Vector2(GRID_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE))

# 信号
signal tower_placed(cell: Vector2i, tower: TowerBase)
signal grid_changed()

func _ready() -> void:
	_init_grid()

func _init_grid() -> void:
	grid = []
	for row in range(GRID_ROWS):
		var row_data = []
		for col in range(GRID_COLS):
			row_data.append(0)
		grid.append(row_data)

	# 应用当前关卡封禁区：不可通过，也不可建塔。
	for rect in blocked_rects:
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			for x in range(rect.position.x, rect.position.x + rect.size.x):
				var cell = Vector2i(x, y)
				if is_valid_cell(cell):
					grid[y][x] = 4

	# 标记起点和终点。即使设计失误覆盖到封禁区，也保证入口/出口可用。
	grid[START_CELL.y][START_CELL.x] = 2
	grid[GOAL_CELL.y][GOAL_CELL.x] = 3

func load_map(new_blocked_rects: Array) -> void:
	blocked_rects = new_blocked_rects
	tower_at_cell.clear()
	_init_grid()
	grid_changed.emit()
	queue_redraw()

func _draw() -> void:
	if grid.is_empty():
		return

	_draw_microcosm_backdrop()
	_draw_walkable_field()

	# 绘制封禁区
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			if grid[row][col] == 4:
				var pos = cell_to_world(Vector2i(col, row))
				_draw_blocked_cell(pos, Vector2i(col, row))

	# 绘制起点和终点
	var start_pos = cell_to_world(START_CELL)
	var goal_pos = cell_to_world(GOAL_CELL)
	_draw_gate(start_pos, Color(0.25, 1.0, 0.75, 0.9), "IN")
	_draw_gate(goal_pos, Color(1.0, 0.35, 0.5, 0.9), "OUT")

	# 绘制已放置的塔
	for cell in tower_at_cell:
		var pos = cell_to_world(cell)
		draw_circle(pos, CELL_SIZE * 0.42, Color(0.26, 0.35, 0.8, 0.18))
		draw_circle(pos, CELL_SIZE * 0.38, Color(0.7, 0.85, 1.0, 0.38), false, 1.5)

func _draw_microcosm_backdrop() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.015, 0.018, 0.035, 1.0))
	draw_rect(MAP_RECT.grow(18), Color(0.025, 0.03, 0.08, 0.96))
	draw_rect(MAP_RECT.grow(18), Color(0.08, 0.18, 0.26, 0.65), false, 2.0)

	for i in range(16):
		var t = float(i) / 15.0
		var x = GRID_OFFSET.x + t * GRID_COLS * CELL_SIZE
		var y = GRID_OFFSET.y + 40.0 + sin(t * TAU * 2.0) * 18.0
		var next_x = GRID_OFFSET.x + min(1.0, t + 0.07) * GRID_COLS * CELL_SIZE
		var next_y = GRID_OFFSET.y + 40.0 + sin((t + 0.07) * TAU * 2.0) * 18.0
		draw_line(Vector2(x, y), Vector2(next_x, next_y), Color(0.18, 0.75, 1.0, 0.18), 2.0)

	for i in range(28):
		var col = (i * 7) % GRID_COLS
		var row = (i * 5 + 3) % GRID_ROWS
		var pos = cell_to_world(Vector2i(col, row)) + Vector2(sin(i) * 10.0, cos(i * 1.7) * 8.0)
		draw_circle(pos, 2.0 + float(i % 3), Color(0.55, 0.9, 1.0, 0.16))

func _draw_walkable_field() -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell = Vector2i(col, row)
			if not is_cell_walkable(cell):
				continue
			var pos = cell_to_world(cell)
			draw_circle(pos, 3.0, Color(0.28, 0.75, 0.95, 0.18))
			if (row + col) % 3 == 0:
				draw_circle(pos, CELL_SIZE * 0.34, Color(0.15, 0.5, 0.7, 0.055), false, 1.0)

func _draw_blocked_cell(pos: Vector2, cell: Vector2i) -> void:
	var phase = float((cell.x * 13 + cell.y * 17) % 11) / 11.0
	var radius = CELL_SIZE * (0.34 + phase * 0.08)
	draw_circle(pos, radius, Color(0.05, 0.045, 0.09, 0.86))
	draw_circle(pos + Vector2(-5, -4), radius * 0.42, Color(0.18, 0.12, 0.28, 0.58))
	draw_circle(pos, radius, Color(0.55, 0.38, 0.8, 0.42), false, 1.2)

func _draw_gate(pos: Vector2, color: Color, label: String) -> void:
	draw_circle(pos, CELL_SIZE * 0.42, Color(color.r, color.g, color.b, 0.14))
	draw_circle(pos, CELL_SIZE * 0.32, color, false, 2.4)
	draw_circle(pos, 6.0, Color(color.r, color.g, color.b, 0.6))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-12, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

# === 坐标转换 ===

func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local = world_pos - GRID_OFFSET
	var col = floori(local.x / CELL_SIZE)
	var row = floori(local.y / CELL_SIZE)
	return Vector2i(col, row)

func cell_to_world(cell: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2, cell.y * CELL_SIZE + CELL_SIZE / 2)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_COLS and cell.y >= 0 and cell.y < GRID_ROWS

func is_cell_empty(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		return false
	return grid[cell.y][cell.x] == 0

func would_keep_path_if_blocked(cell: Vector2i) -> bool:
	if not is_cell_empty(cell):
		return false
	grid[cell.y][cell.x] = 1
	var path_exists = has_path(START_CELL, GOAL_CELL)
	grid[cell.y][cell.x] = 0
	return path_exists

func is_cell_walkable(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		return false
	var v = grid[cell.y][cell.x]
	return v == 0 or v == 2 or v == 3  # 空地、起点、终点都可行走

# === 塔管理 ===

func place_tower(cell: Vector2i, tower: TowerBase) -> bool:
	if not is_cell_empty(cell):
		# 不能放在起点或终点
		if cell == START_CELL or cell == GOAL_CELL:
			return false
		return false

	# 放置塔前检查：是否仍然存在到达终点的路径？
	grid[cell.y][cell.x] = 1
	if not has_path(START_CELL, GOAL_CELL):
		# 会堵死路径，不允许
		grid[cell.y][cell.x] = 0
		return false

	tower_at_cell[cell] = tower
	tower_placed.emit(cell, tower)
	grid_changed.emit()
	queue_redraw()
	return true

func remove_tower(cell: Vector2i) -> void:
	if tower_at_cell.has(cell):
		tower_at_cell.erase(cell)
		grid[cell.y][cell.x] = 0
		grid_changed.emit()
		queue_redraw()

func get_tower_at(cell: Vector2i) -> TowerBase:
	return tower_at_cell.get(cell, null)

# === A* 寻路 ===

func find_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	return _find_path_internal(from_cell, to_cell)

func find_varied_path(from_cell: Vector2i, to_cell: Vector2i, random_seed: int, random_strength: float = 0.35, max_length_factor: float = 1.2) -> Array[Vector2i]:
	# 先计算标准最短路，作为长度上限和兜底路径。
	var shortest_path = find_path(from_cell, to_cell)
	if shortest_path.is_empty():
		return []

	# 给每个可通行格子分配一个很小的随机附加代价。
	# A* 仍然偏向最短路，但在多条近似最短路线中会出现个体差异。
	var noise = _build_route_noise(random_seed, random_strength)
	var varied_path = _find_path_internal(from_cell, to_cell, noise)
	if varied_path.is_empty():
		return shortest_path

	# 严格限制随机路线长度，避免敌人因为随机性绕过远路破坏平衡。
	var max_cells = int(ceil(shortest_path.size() * max_length_factor))
	if varied_path.size() <= max_cells:
		return varied_path
	return shortest_path

func has_path(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	return not find_path(from_cell, to_cell).is_empty()

func _find_path_internal(from_cell: Vector2i, to_cell: Vector2i, extra_cost: Dictionary = {}) -> Array[Vector2i]:
	if not is_valid_cell(from_cell) or not is_valid_cell(to_cell):
		return []
	# 终点必须可走；起点允许临时处于不可走格，避免敌人脚下建塔等边界情况导致空路径。
	if not is_cell_walkable(to_cell):
		return []

	# A* 算法
	var open_set = [from_cell]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}

	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var c = Vector2i(col, row)
			g_score[c] = INF
			f_score[c] = INF

	g_score[from_cell] = 0
	f_score[from_cell] = _heuristic(from_cell, to_cell)

	while not open_set.is_empty():
		# 找 f_score 最小的节点
		var current = _find_lowest_f(open_set, f_score)
		if current == to_cell:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for dir in DIRS:
			var neighbor = current + dir
			if not is_cell_walkable(neighbor):
				continue

			var step_cost = 1.0 + float(extra_cost.get(neighbor, 0.0))
			var tentative_g = g_score[current] + step_cost
			if tentative_g < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, to_cell)
				if neighbor not in open_set:
					open_set.append(neighbor)

	# 无路径
	return []

func _build_route_noise(random_seed: int, random_strength: float) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	var noise: Dictionary = {}
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell = Vector2i(col, row)
			if is_cell_walkable(cell):
				noise[cell] = rng.randf_range(0.0, random_strength)
	return noise

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return absi(a.x - b.x) + absi(a.y - b.y)  # 曼哈顿距离

func _find_lowest_f(open_set: Array, f_score: Dictionary) -> Vector2i:
	var lowest = open_set[0]
	var lowest_f = f_score[lowest]
	for cell in open_set:
		if f_score[cell] < lowest_f:
			lowest_f = f_score[cell]
			lowest = cell
	return lowest

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while current in came_from:
		current = came_from[current]
		path.insert(0, current)
	return path
