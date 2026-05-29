# GameState - Autoload singleton
# 全局游戏状态管理：水晶、生命值、波次、纪元

extends Node

# 当前游戏状态
var crystals: int = 200          # 能量水晶（局内货币）
var lives: int = 20              # 生命值
var current_wave: int = 0        # 当前波次
var total_waves: int = 0         # 总波次数
var wave_active: bool = false    # 波次是否进行中
var game_paused: bool = false
var game_over: bool = false

# 纪元信息
var current_era: int = 1         # 当前纪元 (1=量子微观)
var current_level: int = 1       # 当前关卡

# 信号
signal crystals_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal wave_changed(wave: int)
signal game_won()
signal game_lost()
signal era_changed(era: int)

func _ready() -> void:
	reset()

func reset() -> void:
	crystals = 200
	lives = 20
	current_wave = 0
	total_waves = 0
	wave_active = false
	game_paused = false
	game_over = false

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
	lives -= amount
	lives_changed.emit(lives)
	if lives <= 0:
		lives = 0
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
