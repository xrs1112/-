# 量子纠缠Boss - 纪元一Boss
# 两个纠缠粒子同步出现，共享血量，必须同时击杀
class_name BossEntanglement
extends EnemyBase

var linked_boss: BossEntanglement = null
var shared_health: float
var resurrecting: bool = false

func _ready() -> void:
	enemy_name = "量子纠缠对"
	max_health = 300.0
	speed = 80.0
	armor = 0.2
	reward_crystals = 200
	damage_to_base = 5
	shared_health = max_health
	super()

func take_damage(damage: float, is_dot: bool = false) -> void:
	if is_dead:
		return

	var actual_damage = damage * (1.0 - armor)
	shared_health -= actual_damage

	if linked_boss and not linked_boss.is_dead:
		linked_boss.shared_health = shared_health
		if shared_health <= 0:
			linked_boss._check_death()

	_check_death()

func _check_death() -> void:
	if shared_health <= 0:
		if linked_boss == null or linked_boss.is_dead or linked_boss.shared_health <= 0:
			die_boss()
		else:
			resurrecting = true
			modulate.a = 0.3
			get_tree().create_timer(3.0).timeout.connect(_try_resurrect)

func _try_resurrect() -> void:
	if linked_boss and not linked_boss.is_dead and linked_boss.shared_health > 0:
		resurrecting = false
		shared_health = max_health
		linked_boss.shared_health = shared_health
		modulate.a = 1.0
	else:
		die_boss()

func die_boss() -> void:
	if is_dead:
		return
	is_dead = true
	GameState.add_crystals(reward_crystals)
	enemy_died.emit(self)
	queue_free()
