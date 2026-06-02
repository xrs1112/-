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
@export var upgrade_damage_bonus: float = 5.0
@export var upgrade_speed_bonus: float = 0.2

# 运行状态
var level: int = 1
var attack_timer: float = 0.0
var current_target = null
var placed: bool = false
var grid_cell: Vector2i = Vector2i(-1, -1)
var tower_color: Color = Color.WHITE
var total_invested: int = 0  # 累计投入（建造+升级费用）
var range_visible: bool = false

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
	if GameState.game_over or GameState.game_paused or not placed:
		return

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
	# 发射子弹
	var BulletClass = load("res://scripts/bullet.gd")
	var bullet = Node2D.new()
	bullet.set_script(BulletClass)
	bullet.global_position = global_position
	bullet.setup(target, attack_damage, 300.0, tower_color.lightened(0.4))
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
	
	# 升级变色：越来越亮
	tower_color = tower_color.lightened(0.2)
	tower_color.a = 0.85
	_refresh_visual()
	
	tower_upgraded.emit(self)
	return true

func get_upgrade_cost() -> int:
	return upgrade_cost

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

	# 只在选中塔时绘制攻击范围圆
	if placed and range_visible:
		draw_circle(Vector2.ZERO, attack_range, Color(0.55, 0.85, 1.0, 0.12), false, 1.2)

	# 绘制方向指示
	if current_target and not current_target.is_dead:
		draw_line(Vector2.ZERO, current_target.global_position - global_position, tower_color.lightened(0.6), 1.8)

func _draw_tower_body() -> void:
	var core_color = tower_color
	var glow_color = Color(core_color.r, core_color.g, core_color.b, 0.22)
	draw_circle(Vector2.ZERO, 24.0, glow_color)

	match tower_name:
		"A1":
			_draw_prism_tower(core_color)
		"A2":
			_draw_observer_tower(core_color)
		"A3":
			_draw_trap_tower(core_color)
		_:
			draw_circle(Vector2.ZERO, 16.0, core_color)
			draw_circle(Vector2.ZERO, 16.0, Color.WHITE, false, 1.2)

func _draw_prism_tower(color: Color) -> void:
	var points = PackedVector2Array([
		Vector2(0, -18),
		Vector2(16, 10),
		Vector2(-16, 10),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color(0.85, 0.95, 1.0, 0.85), 1.4)
	draw_circle(Vector2.ZERO, 5.0, Color(0.85, 1.0, 1.0, 0.9))

func _draw_observer_tower(color: Color) -> void:
	draw_circle(Vector2.ZERO, 17.0, Color(color.r, color.g, color.b, 0.24))
	draw_circle(Vector2.ZERO, 17.0, Color(1.0, 0.95, 0.55, 0.7), false, 2.0)
	draw_circle(Vector2.ZERO, 8.0, color.lightened(0.2))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 0.8, 0.95))
	draw_line(Vector2(-18, 0), Vector2(18, 0), Color(1.0, 1.0, 0.7, 0.35), 1.2)

func _draw_trap_tower(color: Color) -> void:
	draw_circle(Vector2.ZERO, 19.0, Color(color.r, color.g, color.b, 0.18))
	draw_circle(Vector2.ZERO, 19.0, color.lightened(0.1), false, 2.4)
	draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.55, 0.25, 0.35), false, 2.0)
	for i in range(6):
		var angle = i * TAU / 6.0
		var p = Vector2(cos(angle), sin(angle)) * 15.0
		draw_circle(p, 2.0, Color(1.0, 0.82, 0.35, 0.75))
