# Tower - 塔基类
# 所有防御塔的父类

class_name TowerBase
extends Node2D

# 塔属性（子类覆盖）
@export var tower_name: String = "基础塔"
@export var description: String = ""
@export var build_cost: int = 100
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0       # 每秒攻击次数
@export var attack_range: float = 150.0     # 攻击范围（像素）
@export var upgrade_cost: int = 80
@export var upgrade_damage_bonus: float = 5.0
@export var upgrade_speed_bonus: float = 0.2

# 运行状态
var level: int = 1              # 1~3
var attack_timer: float = 0.0
var current_target: EnemyBase = null
var placed: bool = false

# 引用
@onready var range_indicator: Area2D = $RangeArea
@onready var range_collision: CollisionShape2D = $RangeArea/CollisionShape2D

func _ready() -> void:
	_setup_range()
	attack_timer = 0.0

func _setup_range() -> void:
	if range_collision:
		var circle = CircleShape2D.new()
		circle.radius = attack_range
		range_collision.shape = circle

func _process(delta: float) -> void:
	if GameState.game_over or GameState.game_paused or not placed:
		return

	attack_timer += delta
	if attack_timer >= 1.0 / attack_speed:
		attack_timer = 0.0
		_try_attack()

func _try_attack() -> void:
	# 寻找范围内最近的敌人
	var target = _find_target()
	if target and not target.is_dead:
		current_target = target
		_perform_attack(target)
	else:
		current_target = null

func _find_target() -> EnemyBase:
	var bodies = range_indicator.get_overlapping_bodies()
	var nearest: EnemyBase = null
	var max_progress: float = -1.0

	for body in bodies:
		var enemy = body as EnemyBase
		if enemy and not enemy.is_dead and enemy.is_visible_target:
			# 优先攻击路程最远的敌人
			if enemy.progress_ratio > max_progress:
				max_progress = enemy.progress_ratio
				nearest = enemy

	return nearest

# 子类覆盖此方法定义攻击行为
func _perform_attack(target: EnemyBase) -> void:
	target.take_damage(attack_damage)

func upgrade() -> bool:
	if level >= 3:
		return false
	if not GameState.spend_crystals(upgrade_cost):
		return false

	level += 1
	attack_damage += upgrade_damage_bonus
	attack_speed += upgrade_speed_bonus
	upgrade_cost = int(upgrade_cost * 1.6)
	upgrade_damage_bonus += 3.0
	upgrade_speed_bonus += 0.15
	return true

func get_upgrade_cost() -> int:
	return upgrade_cost

# 显示攻击范围
func show_range() -> void:
	if range_indicator:
		range_indicator.visible = true

func hide_range() -> void:
	if range_indicator:
		range_indicator.visible = false
