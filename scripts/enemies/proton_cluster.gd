# 质子团 - 纪元一
# 高血量、低速、自带物理减伤——早期小坦克
class_name ProtonCluster
extends EnemyBase

func _ready() -> void:
	enemy_name = "质子团"
	max_health = 100.0
	speed = 50.0
	armor = 0.5
	reward_crystals = 40
	damage_to_base = 3
	super()
