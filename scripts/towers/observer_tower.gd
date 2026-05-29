# 观测者塔 - 纪元一
# 锁定敌人使其坍缩——消除虚粒子的闪烁无敌，并造成额外伤害
class_name ObserverTower
extends TowerBase

var mark_damage_mult: float = 1.3

func _ready() -> void:
	tower_name = "观测者塔"
	description = "锁定敌人使其坍缩，消除特殊能力，被标记目标受到额外伤害。"
	build_cost = 120
	attack_damage = 8.0
	attack_speed = 1.2
	attack_range = 180.0
	upgrade_cost = 100
	super()

func _perform_attack(target: EnemyBase) -> void:
	target.take_damage(attack_damage)
	target.is_visible_target = true
	# 额外坍缩伤害
	target.take_damage(attack_damage * (mark_damage_mult - 1.0))

func upgrade() -> bool:
	if not super():
		return false
	match level:
		2: mark_damage_mult = 1.4
		3: mark_damage_mult = 1.5; attack_speed += 0.2
	return true
