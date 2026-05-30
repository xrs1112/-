# A2 - 减速塔（原观测者塔）
class_name ObserverTower
extends TowerBase

func _ready() -> void:
	tower_name = "A2"
	description = "攻击附带减速效果"
	build_cost = 15
	attack_damage = 1.0
	attack_speed = 1.0
	attack_range = 180.0
	upgrade_cost = 20
	tower_color = Color(0.7, 0.7, 0.2, 0.8)  # 金色
	super()

func _perform_attack(target) -> void:
	# 继承子弹逻辑
	super(target)
	# 额外减速效果
	if target.has_method("apply_slow"):
		target.apply_slow(0.5, 2.0)

func upgrade() -> bool:
	if not super():
		return false
	attack_damage += 0.5
	return true
