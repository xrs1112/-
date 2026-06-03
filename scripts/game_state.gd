# GameState - Autoload singleton
# 全局游戏状态管理：水晶、生命值、波次、纪元

extends Node

const TOTAL_LEVELS: int = 5

# 当前游戏状态
var crystals: int = 70            # 能量水晶（局内货币）
var lives: int = 20              # 生命值
var current_wave: int = 0        # 当前波次
var total_waves: int = 0         # 总波次数
var wave_active: bool = false    # 波次是否进行中
var game_paused: bool = false
var game_over: bool = false
var show_hp_numbers: bool = true  # 血条数字显示

# 纪元信息
var current_era: int = 1         # 当前纪元 (1=量子微观)
var current_level: int = 1       # 当前关卡
var unlocked_level: int = TOTAL_LEVELS  # 试玩阶段先全部开放；后续可改为 1 并接本地存档。

# 信号
signal crystals_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal wave_changed(wave: int)
signal game_won()
signal game_lost()
signal era_changed(era: int)
signal level_unlocked(level: int)

func _ready() -> void:
	reset()

func reset() -> void:
	crystals = 70
	lives = 20
	current_wave = 0
	total_waves = 0
	wave_active = false
	game_paused = false
	game_over = false
	show_hp_numbers = true

	# 场景重载时 HUD 子节点会先于 GameManager _ready，重置后必须主动刷新 UI。
	crystals_changed.emit(crystals)
	lives_changed.emit(lives)
	wave_changed.emit(current_wave)

func add_crystals(amount: int) -> void:
	crystals += amount
	crystals_changed.emit(crystals)

func spend_crystals(amount: int) -> bool:
	if crystals >= amount:
		crystals -= amount
		crystals_changed.emit(crystals)
		return true
	return false

func lose_life(amount: int = 1) -> void:
	lives = max(0, lives - amount)
	lives_changed.emit(lives)
	if lives <= 0:
		trigger_game_over(false)

func trigger_game_over(won: bool) -> void:
	if game_over:
		return
	game_over = true
	wave_active = false
	if won:
		game_won.emit()
	else:
		game_lost.emit()

func select_level(level: int) -> void:
	current_level = clampi(level, 0, TOTAL_LEVELS)

func is_level_unlocked(level: int) -> bool:
	if level == 0:
		return true
	return level >= 1 and level <= unlocked_level

func unlock_next_level(completed_level: int) -> void:
	var next_level = clampi(completed_level + 1, 1, TOTAL_LEVELS)
	if next_level > unlocked_level:
		unlocked_level = next_level
		level_unlocked.emit(unlocked_level)
