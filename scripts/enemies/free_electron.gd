# 自由电子 - 纪元一
# 极高速、低生命值，考验玩家的火力覆盖密度
class_name FreeElectron
extends EnemyBase

func _ready() -> void:
	enemy_name = "自由电子"
	max_health = 20.0
	speed = 200.0
	armor = 0.0
	reward_crystals = 10
	damage_to_base = 1
	super()
