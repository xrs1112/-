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
	# 清除旧的
	for child in get_children():
		if child.name == "Visual":
			child.queue_free()
	
	var visual = ColorRect.new()
	visual.name = "Visual"
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	visual.color = tower_color
	add_child(visual)

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
	# 只在选中塔时绘制攻击范围圆
	if placed and range_visible:
		draw_circle(Vector2.ZERO, attack_range, Color(1.0, 1.0, 1.0, 0.1), false, 1.0)

	# 绘制方向指示
	if current_target and not current_target.is_dead:
		draw_line(Vector2.ZERO, current_target.global_position - global_position, Color.RED, 1.5)
