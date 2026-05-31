# MapDebug - 网格地图调试可视化
# 兼容当前 GameGrid/A* 系统：绘制敌人当前路径和可建造格。
extends Node2D

@export var draw_enemy_paths: bool = true
@export var draw_buildable_cells: bool = false

var grid_map: GameGrid = null

func _ready() -> void:
	await get_tree().process_frame
	grid_map = get_tree().get_first_node_in_group("grid_map") as GameGrid
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not grid_map:
		return
	if draw_buildable_cells:
		_draw_buildable_cells()
	if draw_enemy_paths:
		_draw_enemy_paths()

func _draw_buildable_cells() -> void:
	for row in range(GameGrid.GRID_ROWS):
		for col in range(GameGrid.GRID_COLS):
			var cell = Vector2i(col, row)
			if grid_map.is_cell_empty(cell):
				var pos = to_local(grid_map.cell_to_world(cell))
				draw_rect(Rect2(pos - Vector2(20, 20), Vector2(40, 40)), Color(0.2, 0.8, 0.2, 0.12))

func _draw_enemy_paths() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			_draw_single_enemy_path(enemy)

func _draw_single_enemy_path(enemy: EnemyBase) -> void:
	if enemy.path.is_empty() or enemy.path_index >= enemy.path.size():
		return

	var prev = to_local(enemy.global_position)
	for i in range(enemy.path_index, enemy.path.size()):
		var next = to_local(grid_map.cell_to_world(enemy.path[i]))
		draw_line(prev, next, Color(0.1, 0.8, 1.0, 0.55), 2.0)
		draw_circle(next, 3.0, Color(0.1, 0.8, 1.0, 0.75))
		prev = next
