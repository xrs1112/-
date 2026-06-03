# Tower - 塔基类 v2
# 网格版：放在格子里，范围检测遍历所有敌人

class_name TowerBase
extends Node2D

# 塔属性
@export var tower_name: String = "基础塔"
@export var description: String = ""
@export var build_cost: int = 100
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 150.0      # 像素范围
@export var upgrade_cost: int = 80
@export var upgrade_damage_bonus: float = 1.4
@export var upgrade_speed_bonus: float = 0.15

# 运行状态
var level: int = 1
var attack_timer: float = 0.0
var current_target = null
var placed: bool = false
var grid_cell: Vector2i = Vector2i(-1, -1)
var tower_color: Color = Color.WHITE
var total_invested: int = 0  # 累计投入（建造+升级费用）
var range_visible: bool = false
var upgrade_flash_timer: float = 0.0
var upgrade_flash_duration: float = 0.45

# 信号
signal tower_upgraded(tower: TowerBase)
signal tower_sold(tower: TowerBase)

func _ready() -> void:
	attack_timer = 0.0
	total_invested = build_cost  # 初始投入 = 建造费用
	_setup_visual()

func _setup_visual() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if upgrade_flash_timer > 0.0:
		upgrade_flash_timer -= delta
		queue_redraw()

	if GameState.game_over or GameState.game_paused or not placed:
		return

	if level >= 3:
		queue_redraw()

	attack_timer += delta
	if attack_timer >= 1.0 / attack_speed:
		attack_timer = 0.0
		_try_attack()

func _try_attack() -> void:
	var target = _find_target()
	if target and not target.is_dead:
		current_target = target
		_perform_attack(target)
	else:
		current_target = null

func _find_target():
	# 遍历场景中所有敌人，找范围内最近的
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if enemy is EnemyBase and not enemy.is_dead and enemy.is_visible_target:
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= attack_range and dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy

	return nearest

func _perform_attack(target) -> void:
	_fire_bullet(target, attack_damage, 300.0, tower_color.lightened(0.4))

func _fire_bullet(target, damage: float, speed: float, color: Color) -> void:
	var BulletClass = load("res://scripts/bullet.gd")
	var bullet = Node2D.new()
	bullet.set_script(BulletClass)
	bullet.global_position = global_position
	bullet.setup(target, damage, speed, color)
	get_parent().add_child(bullet)

func upgrade() -> bool:
	if level >= 3:
		return false
	if not GameState.spend_crystals(upgrade_cost):
		return false

	total_invested += upgrade_cost
	level += 1
	attack_damage += upgrade_damage_bonus
	attack_speed += upgrade_speed_bonus
	upgrade_cost = int(upgrade_cost * 1.6)
	
	# 升级时仍稍微提亮核心色，主要差异由额外结构层表现。
	tower_color = tower_color.lightened(0.2)
	tower_color.a = 0.85
	upgrade_flash_timer = upgrade_flash_duration
	_refresh_visual()
	
	tower_upgraded.emit(self)
	return true

func get_upgrade_cost() -> int:
	return upgrade_cost

func get_stats_text() -> String:
	return "伤害 %.1f  攻速 %.1f\n射程 %d" % [
		attack_damage,
		attack_speed,
		int(attack_range),
	]

func get_upgrade_preview() -> String:
	if level >= 3:
		return "已满级"
	return "下级: 伤害 +%.1f / 攻速 +%.1f" % [
		upgrade_damage_bonus,
		upgrade_speed_bonus,
	]

func get_tower_info_text() -> String:
	return "%s Lv.%d\n%s\n%s" % [
		tower_name,
		level,
		get_stats_text(),
		get_upgrade_preview(),
	]

# 出售价值：总投入的 50% + 每级 +5%
func get_sell_value() -> int:
	var pct = 0.5 + (level - 1) * 0.05  # Lv1=50%, Lv2=55%, Lv3=60%
	return int(total_invested * pct)

func show_range() -> void:
	range_visible = true
	queue_redraw()

func hide_range() -> void:
	range_visible = false
	queue_redraw()

func _refresh_visual() -> void:
	_setup_visual()

func _draw() -> void:
	_draw_tower_body()
	_draw_upgrade_flash()

	# 只在选中塔时绘制攻击范围圆
	if placed and range_visible:
		draw_circle(Vector2.ZERO, attack_range, Color(0.55, 0.85, 1.0, 0.12), false, 1.2)

	# 绘制方向指示
	if current_target and not current_target.is_dead:
		draw_line(Vector2.ZERO, current_target.global_position - global_position, tower_color.lightened(0.6), 1.8)

func _draw_upgrade_flash() -> void:
	if upgrade_flash_timer <= 0.0:
		return
	var progress := 1.0 - upgrade_flash_timer / upgrade_flash_duration
	var radius := lerpf(20.0, 44.0, progress)
	var alpha := 1.0 - progress
	draw_circle(Vector2.ZERO, radius, Color(0.72, 1.0, 0.9, 0.4 * alpha), false, 3.0)
	draw_circle(Vector2.ZERO, radius * 0.72, Color(1.0, 0.92, 0.55, 0.28 * alpha), false, 1.5)

func _draw_tower_body() -> void:
	var core_color = tower_color
	var glow_color = Color(core_color.r, core_color.g, core_color.b, 0.22)
	draw_circle(Vector2.ZERO, 22.0 + level * 3.0, glow_color)
	_draw_upgrade_base(core_color)

	match tower_name:
		"量子棱镜":
			_draw_prism_tower(core_color)
		"观测棱镜":
			_draw_observer_tower(core_color)
		"虚粒子阱":
			_draw_trap_tower(core_color)
		_:
			draw_circle(Vector2.ZERO, 16.0, core_color)
			draw_circle(Vector2.ZERO, 16.0, Color.WHITE, false, 1.2)
			_draw_generic_upgrade(core_color)

func _draw_prism_tower(color: Color) -> void:
	var points = PackedVector2Array([
		Vector2(0, -18),
		Vector2(16, 10),
		Vector2(-16, 10),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color(0.85, 0.95, 1.0, 0.85), 1.4)
	draw_circle(Vector2.ZERO, 5.0, Color(0.85, 1.0, 1.0, 0.9))
	if level >= 2:
		var rail_color = Color(0.75, 0.95, 1.0, 0.78)
		draw_polyline(PackedVector2Array([Vector2(-21, 14), Vector2(0, 24), Vector2(21, 14)]), rail_color, 1.7)
		draw_line(Vector2(-22, -2), Vector2(-10, -10), rail_color, 1.5)
		draw_line(Vector2(22, -2), Vector2(10, -10), rail_color, 1.5)
		draw_circle(Vector2(-19, 12), 2.2, rail_color)
		draw_circle(Vector2(19, 12), 2.2, rail_color)
	if level >= 3:
		var phase := float(Time.get_ticks_msec()) / 1000.0
		var beam_color = Color(0.6, 1.0, 0.95, 0.55)
		for i in range(3):
			var angle := phase * 0.9 + i * TAU / 3.0
			var from_pos := Vector2(cos(angle), sin(angle)) * 10.0
			var to_pos := Vector2(cos(angle), sin(angle)) * 30.0
			draw_line(from_pos, to_pos, beam_color, 1.4)
		_draw_orbit_nodes(29.0, 3, Color(0.85, 1.0, 1.0, 0.9), phase, 2.5)

func _draw_observer_tower(color: Color) -> void:
	draw_circle(Vector2.ZERO, 17.0, Color(color.r, color.g, color.b, 0.24))
	draw_circle(Vector2.ZERO, 17.0, Color(1.0, 0.95, 0.55, 0.7), false, 2.0)
	draw_circle(Vector2.ZERO, 8.0, color.lightened(0.2))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 0.8, 0.95))
	draw_line(Vector2(-18, 0), Vector2(18, 0), Color(1.0, 1.0, 0.7, 0.35), 1.2)
	if level >= 2:
		var scan_color = Color(1.0, 0.98, 0.55, 0.72)
		draw_circle(Vector2.ZERO, 23.0, scan_color, false, 1.5)
		draw_line(Vector2(0, -25), Vector2(0, -12), scan_color, 1.2)
		draw_line(Vector2(0, 12), Vector2(0, 25), scan_color, 1.2)
		draw_circle(Vector2(-23, 0), 2.0, scan_color)
		draw_circle(Vector2(23, 0), 2.0, scan_color)
	if level >= 3:
		var phase := float(Time.get_ticks_msec()) / 1000.0
		var sweep_color = Color(1.0, 1.0, 0.72, 0.7)
		var start_angle := phase * 1.6
		draw_arc(Vector2.ZERO, 29.0, start_angle, start_angle + PI * 0.72, 18, sweep_color, 2.0)
		draw_arc(Vector2.ZERO, 29.0, start_angle + PI, start_angle + PI * 1.72, 18, Color(0.75, 1.0, 1.0, 0.52), 1.5)
		_draw_orbit_nodes(28.0, 4, Color(1.0, 0.95, 0.52, 0.88), -phase * 0.75, 2.1)

func _draw_trap_tower(color: Color) -> void:
	draw_circle(Vector2.ZERO, 19.0, Color(color.r, color.g, color.b, 0.18))
	draw_circle(Vector2.ZERO, 19.0, color.lightened(0.1), false, 2.4)
	draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.55, 0.25, 0.35), false, 2.0)
	for i in range(6):
		var angle = i * TAU / 6.0
		var p = Vector2(cos(angle), sin(angle)) * 15.0
		draw_circle(p, 2.0, Color(1.0, 0.82, 0.35, 0.75))
	if level >= 2:
		var anchor_color = Color(1.0, 0.65, 0.28, 0.75)
		for i in range(3):
			var angle := -PI / 2.0 + i * TAU / 3.0
			var outer := Vector2(cos(angle), sin(angle)) * 27.0
			var inner := Vector2(cos(angle), sin(angle)) * 19.0
			draw_line(inner, outer, anchor_color, 2.0)
			draw_circle(outer, 3.0, anchor_color)
		draw_arc(Vector2.ZERO, 24.0, PI * 0.1, PI * 1.72, 24, Color(1.0, 0.38, 0.18, 0.5), 1.8)
	if level >= 3:
		var phase := float(Time.get_ticks_msec()) / 1000.0
		var crack_color = Color(1.0, 0.28, 0.15, 0.8)
		for i in range(8):
			var angle := phase * 0.55 + i * TAU / 8.0
			var p1 := Vector2(cos(angle), sin(angle)) * 22.0
			var p2 := Vector2(cos(angle + 0.16), sin(angle + 0.16)) * 31.0
			draw_line(p1, p2, crack_color, 1.4)
		_draw_orbit_nodes(30.0, 5, Color(1.0, 0.82, 0.35, 0.82), phase * 1.15, 2.2)

func _draw_upgrade_base(color: Color) -> void:
	if level >= 2:
		draw_circle(Vector2.ZERO, 27.0, Color(color.r, color.g, color.b, 0.26), false, 1.4)
	if level >= 3:
		draw_circle(Vector2.ZERO, 32.0, Color(0.86, 0.98, 1.0, 0.28), false, 1.2)

func _draw_generic_upgrade(color: Color) -> void:
	if level >= 2:
		_draw_orbit_nodes(25.0, 4, color.lightened(0.35), 0.0, 2.0)
	if level >= 3:
		var phase := float(Time.get_ticks_msec()) / 1000.0
		_draw_orbit_nodes(31.0, 6, Color(0.9, 1.0, 1.0, 0.8), phase, 2.0)

func _draw_orbit_nodes(radius: float, count: int, color: Color, phase: float, node_radius: float) -> void:
	for i in range(count):
		var angle := phase + i * TAU / float(count)
		var p := Vector2(cos(angle), sin(angle)) * radius
		draw_circle(p, node_radius, color)
