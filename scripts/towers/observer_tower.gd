# 观测棱镜 - 减速塔
class_name ObserverTower
extends TowerBase

var slow_factor: float = 0.5
var slow_duration: float = 2.0

func _ready() -> void:
	tower_name = "观测棱镜"
	description = "观测并减缓敌人的运动状态"
	build_cost = 18
	attack_damage = 1.0
	attack_speed = 1.0
	attack_range = 180.0
	upgrade_cost = 26
	tower_color = Color(0.7, 0.7, 0.2, 0.8)  # 金色
	super()

func _perform_attack(target) -> void:
	# 继承子弹逻辑
	super(target)
	# 额外减速效果
	if target.has_method("apply_slow"):
		target.apply_slow(slow_factor, slow_duration)

func upgrade() -> bool:
	if not super():
		return false
	match level:
		2:
			attack_damage += 0.5
			attack_range += 18.0
			slow_duration = 2.7
		3:
			attack_damage += 0.5
			attack_range += 22.0
			slow_factor = 0.38
			slow_duration = 3.2
	return true

func get_upgrade_preview() -> String:
	match level:
		1:
			return "下级: 射程 +18，减速延长到 2.7 秒"
		2:
			return "下级: 减速强化到 62%，射程 +22"
		_:
			return "已满级: 深度观测减速已激活"

func get_stats_text() -> String:
	return "伤害 %.1f  攻速 %.1f\n射程 %d  减速 %d%% / %.1fs" % [
		attack_damage,
		attack_speed,
		int(attack_range),
		int(round((1.0 - slow_factor) * 100.0)),
		slow_duration,
	]
