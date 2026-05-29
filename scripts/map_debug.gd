# MapDebug - 地图调试可视化
# 绘制路径线、建造位标记、敌人移动轨迹
extends Node2D

var enemy_path: Path2D
var build_positions: Array[Vector2] = []

func _ready() -> void:
	# 延迟一帧确保曲线已生成
	await get_tree().process_frame
	_setup_references()
	queue_redraw()

func _setup_references() -> void:
	enemy_path = get_node_or_null("../EnemyPath")
	var markers = get_tree().get_nodes_in_group("build_position")
	for marker in markers:
		if marker is Node2D:
			build_positions.append(marker.position)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_path()
	_draw_build_positions()
	_draw_enemies()

func _draw_path() -> void:
	if not enemy_path or not enemy_path.curve:
		return
	var curve = enemy_path.curve
	if curve.point_count < 2:
		return

	# 绘制路径线（灰色虚线）
	var points = curve.get_baked_points()
	if points.size() < 2:
		return

	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(0.5, 0.5, 0.5, 0.6), 2.0, true)

	# 绘制路径节点（小圆点）
	for i in range(curve.point_count):
		var pt = curve.get_point_position(i)
		draw_circle(pt, 5, Color(0.3, 0.8, 1.0, 0.8))

	# 起点和终点标记
	if curve.point_count >= 2:
		var start = curve.get_point_position(0)
		var end = curve.get_point_position(curve.point_count - 1)
		draw_circle(start, 10, Color.GREEN, false, 2.0)
		draw_circle(end, 10, Color.RED, false, 2.0)
		draw_string(ThemeDB.fallback_font, start + Vector2(12, -4), "起点")
		draw_string(ThemeDB.fallback_font, end + Vector2(12, -4), "终点")

func _draw_build_positions() -> void:
	for pos in build_positions:
		draw_circle(pos, 18, Color(0.2, 0.7, 0.2, 0.3))
		draw_circle(pos, 18, Color(0.3, 0.9, 0.3, 0.6), false, 1.5)
		draw_circle(pos, 3, Color.WHITE, false, 1.0)

func _draw_enemies() -> void:
	if not enemy_path:
		return
	for child in enemy_path.get_children():
		if child is EnemyBase and not child.is_dead:
			var pos = child.global_position
			var color = Color.RED
			if child.enemy_name == "虚粒子":
				color = Color(0.6, 0.3, 1.0, 0.8)
			elif child.enemy_name == "自由电子":
				color = Color(0.3, 0.8, 1.0, 0.9)
			elif child.enemy_name == "质子团":
				color = Color(1.0, 0.6, 0.2, 0.8)
			elif child.enemy_name == "量子纠缠对":
				color = Color(1.0, 0.2, 0.2, 0.9)
			draw_circle(pos, 10, color)
			draw_circle(pos, 10, color, false, 2.0)
