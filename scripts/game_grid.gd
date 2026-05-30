# GridMap - 网格地图系统
# 管理地图网格、A*寻路、塔占位
class_name GameGrid
extends Node2D

# 网格参数
const CELL_SIZE: int = 48
const GRID_COLS: int = 22
const GRID_ROWS: int = 13
const GRID_OFFSET: Vector2 = Vector2(112, 48)  # 居中偏移

# 起点和终点（网格坐标）
static var START_CELL = Vector2i(0, 0)
static var GOAL_CELL = Vector2i(21, 12)

# 网格数据：0=空, 1=塔, 2=起点, 3=终点
var grid: Array = []

# 塔引用
var tower_at_cell: Dictionary = {}   # Vector2i → TowerBase

# A* 方向（四方向移动）
const DIRS = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

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
	# 标记起点和终点
	grid[START_CELL.y][START_CELL.x] = 2
	grid[GOAL_CELL.y][GOAL_CELL.x] = 3

func _draw() -> void:
	# 绘制网格线
	for row in range(GRID_ROWS + 1):
		var y = GRID_OFFSET.y + row * CELL_SIZE
		draw_line(Vector2(GRID_OFFSET.x, y), Vector2(GRID_OFFSET.x + GRID_COLS * CELL_SIZE, y), Color(0.2, 0.2, 0.3, 0.4), 1.0)
	for col in range(GRID_COLS + 1):
		var x = GRID_OFFSET.x + col * CELL_SIZE
		draw_line(Vector2(x, GRID_OFFSET.y), Vector2(x, GRID_OFFSET.y + GRID_ROWS * CELL_SIZE), Color(0.2, 0.2, 0.3, 0.4), 1.0)

	# 绘制起点和终点
	var start_pos = cell_to_world(START_CELL)
	var goal_pos = cell_to_world(GOAL_CELL)
	draw_rect(Rect2(start_pos - Vector2(20, 20), Vector2(40, 40)), Color.GREEN, false, 2.0)
	draw_rect(Rect2(goal_pos - Vector2(20, 20), Vector2(40, 40)), Color.RED, false, 2.0)

	# 绘制已放置的塔
	for cell in tower_at_cell:
		var pos = cell_to_world(cell)
		draw_rect(Rect2(pos - Vector2(20, 20), Vector2(40, 40)), Color(0.4, 0.4, 0.8, 0.6))
		draw_rect(Rect2(pos - Vector2(20, 20), Vector2(40, 40)), Color(0.6, 0.6, 1.0, 0.4), false, 1.5)

# === 坐标转换 ===

func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local = world_pos - GRID_OFFSET
	var col = int(local.x / CELL_SIZE)
	var row = int(local.y / CELL_SIZE)
	return Vector2i(clampi(col, 0, GRID_COLS - 1), clampi(row, 0, GRID_ROWS - 1))

func cell_to_world(cell: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2, cell.y * CELL_SIZE + CELL_SIZE / 2)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_COLS and cell.y >= 0 and cell.y < GRID_ROWS

func is_cell_empty(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		return false
	return grid[cell.y][cell.x] == 0

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

			var tentative_g = g_score[current] + 1
			if tentative_g < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, to_cell)
				if neighbor not in open_set:
					open_set.append(neighbor)

	# 无路径
	return []

func has_path(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	return not find_path(from_cell, to_cell).is_empty()

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
