# HUD - 游戏内界面
extends Control

@onready var crystal_label: Label = $CrystalLabel
@onready var lives_label: Label = $LivesLabel
@onready var wave_label: Label = $WaveLabel

func _ready() -> void:
	update_crystals(GameState.crystals)
	update_lives(GameState.lives)
	GameState.crystals_changed.connect(update_crystals)
	GameState.lives_changed.connect(update_lives)
	GameState.wave_changed.connect(update_wave)

func update_crystals(amount: int) -> void:
	crystal_label.text = "水晶: " + str(amount)

func update_lives(amount: int) -> void:
	lives_label.text = "生命: " + str(amount)

func update_wave(wave: int) -> void:
	wave_label.text = "波次: " + str(wave) + "/" + str(GameState.total_waves)
