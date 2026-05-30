# A1 - 基础攻击塔
class_name ProbabilityTower
extends TowerBase

func _ready() -> void:
	tower_name = "A1"
	description = "基础攻击塔"
	build_cost = 10
	attack_damage = 1.0
	attack_speed = 1.0
	attack_range = 150.0
	upgrade_cost = 15
	tower_color = Color(0.3, 0.3, 0.7, 0.8)  # 深蓝紫
	super()

func upgrade() -> bool:
	if not super():
		return false
	attack_damage += 1.0
	return true
