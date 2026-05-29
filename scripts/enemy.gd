# Enemy - 敌人基类
# 所有敌人的父类，定义基础属性与行为

class_name EnemyBase
extends PathFollow2D

# 基础属性（子类在 _ready 中覆盖）
@export var enemy_name: String = "未知敌人"
@export var max_health: float = 100.0
@export var speed: float = 100.0          # 移动速度（像素/秒）
@export var armor: float = 0.0            # 护甲（减伤百分比，0~1）
@export var reward_crystals: int = 10     # 击杀奖励水晶
@export var damage_to_base: int = 1       # 到达终点扣除生命

# 运行状态
var current_health: float
var is_dead: bool = false
var is_visible_target: bool = true        # 是否可被塔锁定（虚粒子闪烁用）

# 特殊状态
var slowed: bool = false
var slow_timer: float = 0.0
var slow_factor: float = 1.0
var dot_damage: float = 0.0               # 持续伤害/秒
var dot_timer: float = 0.0

# 信号
signal enemy_died(enemy: EnemyBase)
signal enemy_reached_end(enemy: EnemyBase)

func _ready() -> void:
	current_health = max_health
	# PathFollow2D 需要在 setup 后才会正确跟随路径
	progress = 0.0

func _process(delta: float) -> void:
	if is_dead or GameState.game_over or GameState.game_paused:
		return

	# 沿路径移动
	progress += speed * slow_factor * delta

	# 处理减速
	if slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			slowed = false
			slow_factor = 1.0

	# 处理 DOT 持续伤害
	if dot_damage > 0:
		dot_timer -= delta
		if dot_timer <= 0:
			take_damage(dot_damage, true)
			dot_timer = 1.0  # 每秒跳一次

	# 到达终点
	if progress_ratio >= 1.0:
		reached_end()

func take_damage(damage: float, is_dot: bool = false) -> void:
	if is_dead:
		return

	# 护甲减伤
	var actual_damage = damage * (1.0 - armor)
	current_health -= actual_damage

	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	GameState.add_crystals(reward_crystals)
	enemy_died.emit(self)
	queue_free()

func reached_end() -> void:
	if is_dead:
		return
	is_dead = true
	GameState.lose_life(damage_to_base)
	enemy_reached_end.emit(self)
	queue_free()

func apply_slow(factor: float, duration: float) -> void:
	slowed = true
	slow_factor = factor
	slow_timer = duration

func apply_dot(damage_per_sec: float, duration: float) -> void:
	dot_damage = damage_per_sec
	dot_timer = 1.0
	# 在 duration 后清除
	get_tree().create_timer(duration).timeout.connect(_clear_dot)

func _clear_dot() -> void:
	dot_damage = 0.0
