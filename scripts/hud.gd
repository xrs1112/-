# HUD - 游戏内界面
extends Control

@onready var crystal_label: Label = $CrystalLabel
@onready var lives_label: Label = $LivesLabel
@onready var wave_label: Label = $WaveLabel

func _ready() -> void:
	# 让 HUD 不拦截鼠标事件，只子控件（按钮）响应
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_label_style()
	
	update_crystals(GameState.crystals)
	update_lives(GameState.lives)
	update_wave(GameState.current_wave)
	GameState.crystals_changed.connect(update_crystals)
	GameState.lives_changed.connect(update_lives)
	GameState.wave_changed.connect(update_wave)

func update_crystals(amount: int) -> void:
	crystal_label.text = "水晶: " + str(amount)

func update_lives(amount: int) -> void:
	lives_label.text = "生命: " + str(amount)

func update_wave(wave: int) -> void:
	wave_label.text = "波次: " + str(wave) + "/" + str(GameState.total_waves)

func _apply_label_style() -> void:
	for label in [crystal_label, lives_label, wave_label, $LevelLabel]:
		label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0, 0.96))
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.18, 0.32, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_font_size_override("font_size", 15)
	$LevelLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _draw() -> void:
	var panel_rect = Rect2(24, 72, 224, 546)
	_draw_panel(panel_rect, Color(0.025, 0.075, 0.13, 0.78), Color(0.22, 0.84, 1.0, 0.46))
	draw_line(Vector2(42, 280), Vector2(226, 280), Color(0.25, 0.82, 1.0, 0.24), 1.0)
	draw_line(Vector2(42, 412), Vector2(226, 412), Color(0.25, 0.82, 1.0, 0.24), 1.0)
	draw_circle(Vector2(216, 94), 10, Color(0.2, 0.9, 1.0, 0.1), false, 1.2)
	draw_circle(Vector2(216, 94), 4, Color(0.7, 1.0, 0.95, 0.45))

func _draw_panel(rect: Rect2, bg: Color, border: Color) -> void:
	draw_rect(rect, bg)
	draw_rect(rect, border, false, 1.2)
	draw_line(rect.position + Vector2(8, 0), rect.position + Vector2(rect.size.x - 8, 0), Color(0.65, 1.0, 0.92, 0.22), 2.0)
