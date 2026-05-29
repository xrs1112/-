# 概率波塔 - 纪元一
# 伤害随机浮动：0.5x ~ 2.0x，期望值 1.25x
class_name ProbabilityTower
extends TowerBase

# 覆盖父类默认值
@export var tower_name_p: String = "概率波塔"
@export var build_cost_p: int = 100
@export var attack_damage_p: float = 12.0
@export var attack_speed_p: float = 1.0
@export var attack_range_p: float = 150.0
@export var upgrade_cost_p: int = 80

var min_damage_mult: float = 0.5
var max_damage_mult: float = 2.0

func _ready() -> void:
	tower_name = "概率波塔"
	description = "伤害随机浮动。波函数坍缩时可能造成巨额伤害，也可能仅造成轻微伤害。"
	build_cost = 100
	attack_damage = 12.0
	attack_speed = 1.0
	attack_range = 150.0
	upgrade_cost = 80
	super()

func _perform_attack(target: EnemyBase) -> void:
	var mult = randf_range(min_damage_mult, max_damage_mult)
	var actual_damage = attack_damage * mult
	target.take_damage(actual_damage)

func upgrade() -> bool:
	if not super():
		return false
	match level:
		2: min_damage_mult = 0.6
		3: min_damage_mult = 0.75; max_damage_mult = 2.25
	return true
