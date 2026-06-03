# GameManager - 游戏主控制器 v3 (网格版)
# 网格塔防：点击格子造塔，敌人A*寻路绕行

class_name GameManager
extends Node2D

const COMPENDIUM_DATA = preload("res://scripts/compendium_data.gd")
const COMPENDIUM_PREVIEW = preload("res://scripts/compendium_preview.gd")
const BUILD_GHOST = preload("res://scripts/build_ghost.gd")
const TUTORIAL_OVERLAY = preload("res://scripts/tutorial_overlay.gd")

# 塔脚本引用
var tower_scripts: Dictionary = {
	"probability": preload("res://scripts/towers/probability_tower.gd"),
	"observer": preload("res://scripts/towers/observer_tower.gd"),
	"quark_trap": preload("res://scripts/towers/quark_trap.gd"),
}

const TOWER_SELL_DELAY: float = 2.0

# 节点引用
@onready var grid_map = $GameGrid
@onready var wave_manager: WaveManager = $WaveManager
@onready var build_menu: Control = $UI/BuildMenu
@onready var tower_menu: Control = $UI/TowerMenu
@onready var tower_info_label: Label = $UI/TowerMenu/TowerInfoLabel
@onready var crystal_label: Label = $UI/HUD/CrystalLabel
@onready var lives_label: Label = $UI/HUD/LivesLabel
@onready var level_label: Label = $UI/HUD/LevelLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var result_panel: Panel = $UI/ResultPanel
@onready var result_title: Label = $UI/ResultPanel/ResultTitle
@onready var result_body: Label = $UI/ResultPanel/ResultBody
@onready var result_replay_btn: Button = $UI/ResultPanel/ResultReplayBtn
@onready var result_next_btn: Button = $UI/ResultPanel/ResultNextBtn
@onready var result_menu_btn: Button = $UI/ResultPanel/ResultMenuBtn
@onready var victory_label: Label = $UI/VictoryLabel
@onready var defeat_label: Label = $UI/DefeatLabel
@onready var enemy_container: Node2D = $Enemies

# 状态
var selected_tower_type: String = ""
var selected_tower: TowerBase = null
var next_level_btn: Button = null
var current_speed_scale: float = 1.0
var message_token: int = 0
var pause_panel: Panel = null
var pause_resume_btn: Button = null
var pause_compendium_btn: Button = null
var game_compendium_panel: Panel = null
var game_compendium_preview: Control = null
var game_compendium_detail_label: RichTextLabel = null
var game_compendium_list_buttons: Array[Button] = []
var game_compendium_category: String = "towers"
var build_ghost: Control = null
var build_tooltip_panel: Panel = null
var build_tooltip_label: Label = null
var wave_preview_panel: Panel = null
var wave_preview_label: Label = null
var tutorial_panel: Panel = null
var tutorial_label: Label = null
var tutorial_overlay = null
var tutorial_skip_btn: Button = null
var tutorial_step: int = -1
var tutorial_build_cell: Vector2i = Vector2i(-1, -1)
var tutorial_life_notice_shown: bool = false
var tutorial_pressure_wave_closed: bool = false
var tutorial_notice_token: int = 0
var last_lives: int = 0
var current_wave_data: Array = []

# 波次数据（10波，5个层级递进）
var level_1_waves = [
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 8,  "interval": 1.35, "tier": 1}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 9, "interval": 1.10, "tier": 1}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 8,  "interval": 1.00, "tier": 1},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 1.80, "tier": 2}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 9,  "interval": 0.95, "tier": 2}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 8,  "interval": 0.85, "tier": 1, "speed_multiplier": 1.08},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 1.80, "tier": 3}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 7,  "interval": 0.95, "tier": 2},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 4,  "interval": 1.45, "tier": 3}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 5,  "interval": 1.05, "tier": 3},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 2,  "interval": 2.10, "tier": 4}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 9, "interval": 0.82, "tier": 2, "speed_multiplier": 1.1},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 2,  "interval": 1.80, "tier": 4}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 5,  "interval": 0.98, "tier": 3},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 1.55, "tier": 4},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 1,  "interval": 2.30, "tier": 5}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 1.25, "tier": 4},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 2,  "interval": 2.00, "tier": 5}],
]

var tutorial_waves = [
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 3, "interval": 2.0, "tier": 1, "health_multiplier": 0.12, "speed_multiplier": 0.58}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 6, "interval": 1.1, "tier": 1, "health_multiplier": 1.1, "speed_multiplier": 1.05}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 4, "interval": 1.4, "tier": 1, "health_multiplier": 0.8, "speed_multiplier": 0.72},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 1, "interval": 2.2, "tier": 2, "health_multiplier": 0.45, "speed_multiplier": 0.7}],
]

# 5 个关卡地图：blocked_rects 中的矩形格子为封禁区，不可通过、不可建塔。
# 坐标基于 22×13 网格，入口固定 (0,0)，出口固定 (21,12)。
var level_maps = [
	{
		"name": "第1关：裂谷回廊",
		"blocked_rects": [Rect2i(4, 0, 18, 2), Rect2i(2, 2, 5, 4), Rect2i(7, 6, 3, 3), Rect2i(12, 6, 2, 3), Rect2i(14, 3, 6, 4), Rect2i(18, 8, 3, 4), Rect2i(20, 12, 1, 1)],
	},
	{
		"name": "第2关：双门石阵",
		"blocked_rects": [Rect2i(3, 0, 2, 5), Rect2i(7, 3, 3, 7), Rect2i(13, 0, 3, 5), Rect2i(16, 7, 3, 5), Rect2i(1, 8, 5, 2), Rect2i(10, 10, 4, 2), Rect2i(20, 12, 1, 1)],
	},
	{
		"name": "第3关：环形祭坛",
		"blocked_rects": [Rect2i(5, 2, 3, 3), Rect2i(9, 2, 4, 2), Rect2i(14, 2, 3, 3), Rect2i(5, 7, 3, 3), Rect2i(10, 6, 3, 3), Rect2i(15, 7, 3, 3), Rect2i(2, 4, 2, 5), Rect2i(19, 4, 2, 5), Rect2i(20, 12, 1, 1)],
	},
	{
		"name": "第4关：峡谷断层",
		"blocked_rects": [Rect2i(3, 1, 6, 2), Rect2i(6, 4, 6, 2), Rect2i(9, 7, 6, 2), Rect2i(12, 10, 6, 2), Rect2i(15, 2, 2, 5), Rect2i(1, 7, 4, 2), Rect2i(20, 12, 1, 1)],
	},
	{
		"name": "第5关：终末迷阵",
		"blocked_rects": [Rect2i(2, 1, 4, 3), Rect2i(7, 0, 3, 5), Rect2i(11, 2, 5, 2), Rect2i(17, 1, 3, 4), Rect2i(3, 6, 5, 2), Rect2i(9, 5, 3, 5), Rect2i(13, 8, 5, 2), Rect2i(18, 6, 2, 5), Rect2i(5, 10, 3, 2), Rect2i(20, 12, 1, 1)],
	},
]

func _ready() -> void:
	if GameState.current_level < 0 or GameState.current_level > level_maps.size():
		GameState.current_level = 1
	_setup_overlay_ui()
	_setup_build_ghost()
	_setup_ui_connections()
	_setup_visual_style()
	_setup_signals()
	_start_current_level()

func _process(_delta: float) -> void:
	_update_build_ghost()

func _setup_build_ghost() -> void:
	build_ghost = BUILD_GHOST.new()
	build_ghost.name = "BuildGhost"
	build_ghost.size = Vector2(GameGrid.CELL_SIZE, GameGrid.CELL_SIZE)
	build_ghost.visible = false
	$UI.add_child(build_ghost)

func _update_build_ghost() -> void:
	if selected_tower_type == "" or GameState.game_over or GameState.game_paused:
		build_ghost.visible = false
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var cell = grid_map.world_to_cell(mouse_pos)
	var cell_world = grid_map.cell_to_world(cell)
	var can_build = _can_preview_place(cell)
	build_ghost.visible = true
	build_ghost.position = cell_world - build_ghost.size * 0.5
	build_ghost.set_preview(selected_tower_type, can_build)

func _can_preview_place(cell: Vector2i) -> bool:
	if not grid_map.is_cell_empty(cell):
		return false
	if cell == GameGrid.START_CELL or cell == GameGrid.GOAL_CELL:
		return false
	if _is_enemy_in_cell(cell):
		return false
	return grid_map.would_keep_path_if_blocked(cell)

func _setup_ui_connections() -> void:
	_ensure_next_level_button()
	$UI/StartWaveBtn.pressed.connect(_on_start_wave)
	$UI/RestartBtn.pressed.connect(_on_restart)
	$UI/HPBtn.pressed.connect(_on_toggle_hp)
	$UI/PauseBtn.pressed.connect(_on_toggle_pause)
	$UI/Speed2Btn.pressed.connect(func(): _toggle_speed(2.0))
	$UI/Speed4Btn.pressed.connect(func(): _toggle_speed(4.0))
	$UI/MainMenuBtn.pressed.connect(_on_main_menu)
	$UI/BuildMenu/BtnProbability.pressed.connect(func(): _on_tower_selected("probability"))
	$UI/BuildMenu/BtnObserver.pressed.connect(func(): _on_tower_selected("observer"))
	$UI/BuildMenu/BtnQuarkTrap.pressed.connect(func(): _on_tower_selected("quark_trap"))
	$UI/BuildMenu/BtnProbability.mouse_entered.connect(func(): _show_build_tooltip("probability", $UI/BuildMenu/BtnProbability))
	$UI/BuildMenu/BtnObserver.mouse_entered.connect(func(): _show_build_tooltip("observer", $UI/BuildMenu/BtnObserver))
	$UI/BuildMenu/BtnQuarkTrap.mouse_entered.connect(func(): _show_build_tooltip("quark_trap", $UI/BuildMenu/BtnQuarkTrap))
	$UI/BuildMenu/BtnProbability.mouse_exited.connect(_hide_build_tooltip)
	$UI/BuildMenu/BtnObserver.mouse_exited.connect(_hide_build_tooltip)
	$UI/BuildMenu/BtnQuarkTrap.mouse_exited.connect(_hide_build_tooltip)
	$UI/TowerMenu/BtnUpgrade.pressed.connect(_on_upgrade_tower)
	$UI/TowerMenu/BtnSell.pressed.connect(_on_sell_tower)
	result_replay_btn.pressed.connect(_on_restart)
	result_next_btn.pressed.connect(_on_next_level)
	result_menu_btn.pressed.connect(_on_main_menu)
	pause_resume_btn.pressed.connect(func(): _set_pause(false))
	pause_compendium_btn.pressed.connect(_show_game_compendium)
	next_level_btn.pressed.connect(_on_next_level)

func _setup_visual_style() -> void:
	_add_popup_panel(build_menu, Rect2(-8, -8, 146, 126))
	_add_popup_panel(tower_menu, Rect2(0, 0, 260, 226))
	for button in [
		$UI/StartWaveBtn,
		$UI/RestartBtn,
		$UI/HPBtn,
		$UI/PauseBtn,
		$UI/Speed2Btn,
		$UI/Speed4Btn,
		$UI/MainMenuBtn,
		$UI/BuildMenu/BtnProbability,
		$UI/BuildMenu/BtnObserver,
		$UI/BuildMenu/BtnQuarkTrap,
		$UI/TowerMenu/BtnUpgrade,
		$UI/TowerMenu/BtnSell,
		result_replay_btn,
		result_next_btn,
		result_menu_btn,
		pause_resume_btn,
		pause_compendium_btn,
		tutorial_skip_btn,
		next_level_btn,
	] + game_compendium_list_buttons:
		_style_button(button)
	result_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.07, 0.13, 0.93), Color(0.34, 0.95, 1.0, 0.66)))
	pause_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.07, 0.13, 0.95), Color(0.34, 0.95, 1.0, 0.72)))
	game_compendium_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.018, 0.055, 0.1, 0.96), Color(0.34, 0.95, 1.0, 0.72)))
	build_tooltip_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.07, 0.13, 0.94), Color(0.42, 1.0, 0.86, 0.66)))
	wave_preview_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.07, 0.13, 0.76), Color(0.34, 0.95, 1.0, 0.42)))
	tutorial_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.07, 0.13, 0.82), Color(0.62, 1.0, 0.9, 0.56)))
	for button in [$UI/GameCompendiumPanel/CloseBtn, $UI/GameCompendiumPanel/TowersTab, $UI/GameCompendiumPanel/EnemiesTab]:
		_style_button(button)
	for label in [tower_info_label, message_label, result_title, result_body, victory_label, defeat_label, $UI/PausePanel/Title, $UI/GameCompendiumPanel/Title, build_tooltip_label, wave_preview_label, tutorial_label]:
		label.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0, 0.96))
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.15, 0.25, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
	message_label.add_theme_font_size_override("font_size", 18)
	tower_info_label.add_theme_font_size_override("font_size", 14)
	tower_info_label.add_theme_constant_override("line_spacing", 2)
	build_tooltip_label.add_theme_font_size_override("font_size", 13)
	build_tooltip_label.add_theme_constant_override("line_spacing", 2)
	wave_preview_label.add_theme_font_size_override("font_size", 12)
	wave_preview_label.add_theme_constant_override("line_spacing", 2)
	tutorial_label.add_theme_font_size_override("font_size", 15)
	game_compendium_detail_label.add_theme_color_override("default_color", Color(0.88, 0.98, 1.0, 0.96))
	game_compendium_detail_label.add_theme_font_size_override("normal_font_size", 15)
	victory_label.add_theme_font_size_override("font_size", 28)
	defeat_label.add_theme_font_size_override("font_size", 28)

func _add_popup_panel(menu: Control, rect: Rect2) -> void:
	if menu.get_node_or_null("SkinPanel"):
		return
	var panel = Panel.new()
	panel.name = "SkinPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.07, 0.13, 0.88), Color(0.28, 0.9, 1.0, 0.58)))
	menu.add_child(panel)
	menu.move_child(panel, 0)

func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.035, 0.11, 0.18, 0.84), Color(0.24, 0.82, 1.0, 0.45)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.055, 0.19, 0.29, 0.92), Color(0.55, 1.0, 0.88, 0.75)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.025, 0.08, 0.14, 0.95), Color(1.0, 0.86, 0.35, 0.85)))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.035, 0.045, 0.06, 0.62), Color(0.2, 0.28, 0.34, 0.55)))
	button.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.82))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.62, 0.68, 0.85))
	button.add_theme_font_size_override("font_size", 15)

func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = _make_panel_style(bg, border)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

func _setup_overlay_ui() -> void:
	build_tooltip_panel = Panel.new()
	build_tooltip_panel.name = "BuildTooltipPanel"
	build_tooltip_panel.visible = false
	build_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_tooltip_panel.size = Vector2(246, 120)
	$UI.add_child(build_tooltip_panel)

	build_tooltip_label = Label.new()
	build_tooltip_label.name = "TooltipText"
	build_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_tooltip_label.set_position(Vector2(14, 10))
	build_tooltip_label.size = Vector2(218, 98)
	build_tooltip_panel.add_child(build_tooltip_label)

	wave_preview_panel = Panel.new()
	wave_preview_panel.name = "WavePreviewPanel"
	wave_preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave_preview_panel.set_position(Vector2(42, 562))
	wave_preview_panel.size = Vector2(184, 56)
	$UI.add_child(wave_preview_panel)

	wave_preview_label = Label.new()
	wave_preview_label.name = "WavePreviewText"
	wave_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wave_preview_label.set_position(Vector2(12, 6))
	wave_preview_label.size = Vector2(160, 44)
	wave_preview_panel.add_child(wave_preview_label)

	tutorial_panel = Panel.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.visible = false
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.set_position(Vector2(272, 12))
	tutorial_panel.size = Vector2(760, 38)
	$UI.add_child(tutorial_panel)

	tutorial_label = Label.new()
	tutorial_label.name = "TutorialText"
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.set_position(Vector2(14, 7))
	tutorial_label.size = Vector2(732, 24)
	tutorial_panel.add_child(tutorial_label)

	tutorial_overlay = TUTORIAL_OVERLAY.new()
	tutorial_overlay.name = "TutorialOverlay"
	tutorial_overlay.visible = false
	$UI.add_child(tutorial_overlay)
	tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.offset_left = 0
	tutorial_overlay.offset_top = 0
	tutorial_overlay.offset_right = 0
	tutorial_overlay.offset_bottom = 0

	tutorial_skip_btn = Button.new()
	tutorial_skip_btn.name = "TutorialSkipBtn"
	tutorial_skip_btn.visible = false
	tutorial_skip_btn.text = "跳过教学"
	tutorial_skip_btn.set_position(Vector2(1088, 74))
	tutorial_skip_btn.size = Vector2(104, 34)
	tutorial_skip_btn.pressed.connect(_skip_tutorial)
	$UI.add_child(tutorial_skip_btn)

	pause_panel = Panel.new()
	pause_panel.name = "PausePanel"
	pause_panel.visible = false
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -180
	pause_panel.offset_top = -118
	pause_panel.offset_right = 180
	pause_panel.offset_bottom = 118
	$UI.add_child(pause_panel)

	var pause_title = Label.new()
	pause_title.name = "Title"
	pause_title.text = "游戏暂停"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 28)
	pause_title.set_position(Vector2(24, 24))
	pause_title.size = Vector2(312, 40)
	pause_panel.add_child(pause_title)

	pause_resume_btn = Button.new()
	pause_resume_btn.name = "ResumeBtn"
	pause_resume_btn.text = "继续游戏"
	pause_resume_btn.set_position(Vector2(70, 84))
	pause_resume_btn.size = Vector2(220, 42)
	pause_panel.add_child(pause_resume_btn)

	pause_compendium_btn = Button.new()
	pause_compendium_btn.name = "CompendiumBtn"
	pause_compendium_btn.text = "查看图鉴"
	pause_compendium_btn.set_position(Vector2(70, 142))
	pause_compendium_btn.size = Vector2(220, 42)
	pause_panel.add_child(pause_compendium_btn)

	game_compendium_panel = Panel.new()
	game_compendium_panel.name = "GameCompendiumPanel"
	game_compendium_panel.visible = false
	game_compendium_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	game_compendium_panel.set_anchors_preset(Control.PRESET_CENTER)
	game_compendium_panel.offset_left = -390
	game_compendium_panel.offset_top = -260
	game_compendium_panel.offset_right = 390
	game_compendium_panel.offset_bottom = 260
	$UI.add_child(game_compendium_panel)

	var title = Label.new()
	title.name = "Title"
	title.text = "微观图鉴"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.set_position(Vector2(24, 22))
	title.size = Vector2(728, 42)
	game_compendium_panel.add_child(title)

	var close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "返回"
	close_btn.set_position(Vector2(674, 24))
	close_btn.size = Vector2(84, 36)
	close_btn.pressed.connect(_hide_game_compendium)
	game_compendium_panel.add_child(close_btn)

	var towers_tab = Button.new()
	towers_tab.name = "TowersTab"
	towers_tab.text = "防御塔"
	towers_tab.set_position(Vector2(34, 78))
	towers_tab.size = Vector2(112, 36)
	towers_tab.pressed.connect(func(): _populate_game_compendium("towers"))
	game_compendium_panel.add_child(towers_tab)

	var enemies_tab = Button.new()
	enemies_tab.name = "EnemiesTab"
	enemies_tab.text = "敌人"
	enemies_tab.set_position(Vector2(158, 78))
	enemies_tab.size = Vector2(112, 36)
	enemies_tab.pressed.connect(func(): _populate_game_compendium("enemies"))
	game_compendium_panel.add_child(enemies_tab)

	for i in range(6):
		var button = Button.new()
		button.name = "EntryBtn%d" % i
		button.set_position(Vector2(34, 136 + i * 54))
		button.size = Vector2(220, 42)
		button.visible = false
		var index = i
		button.pressed.connect(func(): _select_game_compendium_entry(index))
		game_compendium_panel.add_child(button)
		game_compendium_list_buttons.append(button)

	game_compendium_detail_label = RichTextLabel.new()
	game_compendium_detail_label.name = "Detail"
	game_compendium_detail_label.bbcode_enabled = false
	game_compendium_detail_label.fit_content = false
	game_compendium_detail_label.scroll_active = true
	game_compendium_detail_label.selection_enabled = false
	game_compendium_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_compendium_detail_label.set_position(Vector2(292, 256))
	game_compendium_detail_label.size = Vector2(438, 240)
	game_compendium_panel.add_child(game_compendium_detail_label)

	game_compendium_preview = COMPENDIUM_PREVIEW.new()
	game_compendium_preview.name = "Preview"
	game_compendium_preview.set_position(Vector2(292, 86))
	game_compendium_preview.size = Vector2(438, 150)
	game_compendium_panel.add_child(game_compendium_preview)
	_populate_game_compendium("towers")

func _ensure_next_level_button() -> void:
	next_level_btn = $UI.get_node_or_null("NextLevelBtn") as Button
	if next_level_btn:
		return
	next_level_btn = Button.new()
	next_level_btn.name = "NextLevelBtn"
	next_level_btn.visible = false
	next_level_btn.text = "挑战下一关"
	next_level_btn.offset_left = 42
	next_level_btn.offset_top = 560
	next_level_btn.offset_right = 226
	next_level_btn.offset_bottom = 604
	$UI.add_child(next_level_btn)

func _setup_signals() -> void:
	GameState.game_won.connect(_on_victory)
	GameState.game_lost.connect(_on_defeat)
	GameState.lives_changed.connect(_on_lives_changed)
	wave_manager.all_waves_finished_signal.connect(_on_all_waves_done)
	wave_manager.wave_ready.connect(_on_wave_ready)
	wave_manager.countdown_changed.connect(_on_countdown_changed)
	wave_manager.enemy_spawned.connect(_on_enemy_spawned)

func _start_current_level() -> void:
	GameState.reset()
	last_lives = GameState.lives
	tutorial_life_notice_shown = false
	tutorial_pressure_wave_closed = false
	_clear_level_runtime()
	_setup_map_for_current_level()
	current_wave_data = _get_wave_data_for_current_level()
	wave_manager.load_wave_data(current_wave_data)
	wave_manager.set_countdown_auto_start(not _is_tutorial_level())

	victory_label.visible = false
	defeat_label.visible = false
	message_label.visible = false
	pause_panel.visible = false
	game_compendium_panel.visible = false
	result_panel.visible = false
	next_level_btn.visible = false
	$UI/StartWaveBtn.disabled = false
	$UI/StartWaveBtn.text = "开始波次"
	$UI/HPBtn.text = "血量: " + ("开" if GameState.show_hp_numbers else "关")
	_set_pause(false)
	_set_speed(1.0)
	_update_wave_preview()
	if GameState.current_level == 0:
		_set_tutorial_step(0)
		_show_message("教学：跟着上方提示完成第一条防线。", 3.2)
	elif GameState.current_level == 1:
		_clear_tutorial()
		_show_message("点击微光节点建塔，右键取消，准备好后开始波次", 4.0)
	else:
		_clear_tutorial()

func _setup_map_for_current_level() -> void:
	var map_data = _get_current_map_data()
	grid_map.load_map(map_data["blocked_rects"])
	var progress_text = "教学" if GameState.current_level == 0 else "%d/%d" % [GameState.current_level, level_maps.size()]
	level_label.text = "关卡: %s\n进度: %s" % [map_data["name"], progress_text]
	victory_label.text = "%s 通过！" % map_data["name"]

func _get_current_map_data() -> Dictionary:
	if GameState.current_level == 0:
		return {
			"name": "教学关：微光入门",
			"blocked_rects": [
				Rect2i(5, 0, 6, 2),
				Rect2i(13, 3, 5, 2),
				Rect2i(4, 6, 4, 2),
				Rect2i(12, 8, 5, 2),
				Rect2i(20, 12, 1, 1),
			],
		}
	var map_index = clampi(GameState.current_level - 1, 0, level_maps.size() - 1)
	GameState.current_level = map_index + 1
	return level_maps[map_index]

func _get_wave_data_for_current_level() -> Array:
	return tutorial_waves if GameState.current_level == 0 else level_1_waves

func _clear_level_runtime() -> void:
	_cancel_all()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for bullet in get_tree().get_nodes_in_group("bullet"):
		if is_instance_valid(bullet):
			bullet.queue_free()
	for feedback in get_tree().get_nodes_in_group("feedback_float"):
		if is_instance_valid(feedback):
			feedback.queue_free()
	for tower in grid_map.tower_at_cell.values():
		if is_instance_valid(tower):
			tower.queue_free()

func _input(event: InputEvent) -> void:
	if GameState.game_over:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if game_compendium_panel and game_compendium_panel.visible and not game_compendium_panel.get_global_rect().has_point(event.position):
			_hide_game_compendium()
			return
		# 跳过 UI 区域的点击
		if _is_mouse_over_ui(event.position):
			return
		if GameState.game_paused:
			return
		_handle_click(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if GameState.game_paused:
			return
		_cancel_all()

func _is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	var ui_nodes = [$UI/StartWaveBtn, $UI/RestartBtn, $UI/HPBtn, $UI/PauseBtn, $UI/Speed2Btn, $UI/Speed4Btn, $UI/MainMenuBtn, $UI/BuildMenu, $UI/TowerMenu, pause_panel, game_compendium_panel, result_panel, next_level_btn]
	for node in ui_nodes:
		if node and node is Control:
			if _control_tree_has_point(node, mouse_pos):
				return true
	return false

func _control_tree_has_point(control: Control, mouse_pos: Vector2) -> bool:
	if not control.visible:
		return false
	if control.get_global_rect().has_point(mouse_pos):
		return true
	for child in control.get_children():
		if child is Control and _control_tree_has_point(child, mouse_pos):
			return true
	return false

func _handle_click(click_pos: Vector2) -> void:
	var cell = grid_map.world_to_cell(click_pos)
	if _is_tutorial_level() and not _tutorial_allows_map_click(cell):
		_show_message("请点击教学高亮区域", 1.2)
		grid_map.pulse_route_hint(2.0)
		return
	if _is_tutorial_level() and tutorial_step == 4:
		_set_tutorial_step(5)
		return
	if _is_tutorial_level() and tutorial_step == 6:
		if tutorial_overlay:
			tutorial_overlay.clear()
		_show_message("观察第二波：漏怪后会提示生命变化", 2.0)
		return
	if _is_tutorial_level() and tutorial_step == 10:
		return
	if _is_tutorial_level() and tutorial_step == 11:
		GameState.trigger_game_over(true)
		return

	# 如果正在放置塔
	if selected_tower_type != "":
		_try_place_tower(cell)
		return

	# 检查是否点击了已有塔
	var existing_tower = grid_map.get_tower_at(cell)
	if existing_tower:
		if _is_tower_selling(existing_tower):
			_cancel_all()
		else:
			_select_tower(existing_tower)
		return

	if selected_tower:
		_cancel_all()
		return

	# 点击空地 → 显示建造菜单
	if grid_map.is_cell_empty(cell) and cell != Vector2i(0, 0) and cell != Vector2i(21, 12):
		_show_build_menu_at(grid_map.cell_to_world(cell))
		return

	_cancel_all()

func _show_build_menu_at(world_pos: Vector2) -> void:
	_cancel_all()
	build_menu.visible = true
	build_menu.position = world_pos + Vector2(0, -60)
	if _is_tutorial_level() and tutorial_step == 0:
		tutorial_build_cell = grid_map.world_to_cell(world_pos)
		_set_tutorial_step(1)

func _on_tower_selected(type: String) -> void:
	if _is_tutorial_level() and (tutorial_step != 1 or type != "probability"):
		_show_message("教学中先选择量子棱镜", 1.2)
		return
	selected_tower_type = type
	build_menu.visible = false
	_hide_build_tooltip()
	if _is_tutorial_level() and tutorial_step <= 1:
		_set_tutorial_step(2)

func _try_place_tower(cell: Vector2i) -> void:
	if not grid_map.is_cell_empty(cell):
		_show_message("这里不能建塔")
		return
	if _is_enemy_in_cell(cell):
		_show_message("敌人占据格子")
		return

	var script = tower_scripts.get(selected_tower_type)
	if not script:
		_show_message("未知塔类型")
		return

	# 创建塔节点（先不入树，读取默认值检查）
	var tower = Node2D.new()
	tower.set_script(script)
	if not tower is TowerBase:
		tower.queue_free()
		_show_message("塔脚本无效")
		return

	# 先入树触发 _ready() 让 build_cost 等属性正确初始化
	add_child(tower)
	
	# 现在检查费用
	if not GameState.spend_crystals(tower.build_cost):
		_show_message("水晶不足，需要 %d" % tower.build_cost)
		tower.queue_free()
		return

	# 尝试放置到网格
	if not grid_map.place_tower(cell, tower):
		GameState.add_crystals(tower.build_cost)  # 退款
		tower.queue_free()
		_show_message("不能完全堵死道路")
		return

	tower.position = grid_map.cell_to_world(cell)
	tower.placed = true
	tower.grid_cell = cell

	selected_tower_type = ""
	grid_map.pulse_route_hint(2.4)
	_recalculate_all_enemy_paths()
	if _is_tutorial_level() and tutorial_step <= 2:
		_set_tutorial_step(3)

func _is_enemy_in_cell(cell: Vector2i) -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			if grid_map.world_to_cell(enemy.global_position) == cell:
				return true
	return false

func _select_tower(tower: TowerBase) -> void:
	_cancel_all()
	selected_tower = tower
	tower_menu.visible = true
	tower_menu.position = _fit_popup_to_view(tower.global_position + Vector2(-130, -210), tower_menu.size)
	tower.show_range()
	_update_tower_menu()
	if _is_tutorial_level() and tutorial_step == 7:
		_set_tutorial_step(8)

func _fit_popup_to_view(pos: Vector2, popup_size: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	return Vector2(
		clampf(pos.x, 16.0, viewport_size.x - popup_size.x - 16.0),
		clampf(pos.y, 16.0, viewport_size.y - popup_size.y - 16.0)
	)

func _show_build_tooltip(type: String, button: Button) -> void:
	build_tooltip_label.text = _get_build_tooltip_text(type)
	build_tooltip_panel.visible = true
	var pos = button.get_global_position() + Vector2(button.size.x + 12.0, -10.0)
	build_tooltip_panel.position = _fit_popup_to_view(pos, build_tooltip_panel.size)

func _hide_build_tooltip() -> void:
	build_tooltip_panel.visible = false

func _get_build_tooltip_text(type: String) -> String:
	match type:
		"observer":
			return "观测棱镜 [22]\n伤害 1.6  攻速 1.0\n射程 180  减速 50%\n控制塔，延长输出窗口"
		"quark_trap":
			return "虚粒子阱 [30]\n爆发 4.0  半径 80\n冷却 2.0s\n范围清场，适合拐角"
		_:
			return "量子棱镜 [14]\n伤害 2.0  攻速 1.0\n射程 150\n稳定单体输出"

func _update_wave_preview(prefix: String = "") -> void:
	var next_index = wave_manager.next_spawn_index
	if next_index >= current_wave_data.size():
		wave_preview_label.text = "波次完成\n等待清点"
		return

	var groups: Array = current_wave_data[next_index]
	var parts: Array[String] = []
	for group in groups:
		parts.append("T%d x%d" % [int(group.get("tier", 1)), int(group.get("count", 0))])

	var title = prefix if prefix != "" else "下一波"
	wave_preview_label.text = "%s\n第%d/%d波  %s" % [
		title,
		next_index + 1,
		current_wave_data.size(),
		" / ".join(parts),
	]

func _is_tutorial_level() -> bool:
	return GameState.current_level == 0

func _set_tutorial_step(step: int) -> void:
	if not _is_tutorial_level() or GameState.game_over:
		return
	tutorial_step = max(tutorial_step, step)
	tutorial_panel.visible = false
	tutorial_skip_btn.visible = true
	_update_tutorial_controls()
	_update_tutorial_overlay()
	tutorial_label.text = _get_tutorial_text(tutorial_step)

func _update_tutorial_overlay() -> void:
	if not _is_tutorial_level() or not tutorial_overlay or GameState.game_over or result_panel.visible:
		return
	var rects := _get_tutorial_focus_rects()
	var bubble_pos := _get_tutorial_bubble_position()
	tutorial_overlay.set_tutorial_state(_get_tutorial_text(tutorial_step), rects, bubble_pos)

func _get_tutorial_focus_rects() -> Array[Rect2]:
	match tutorial_step:
		0:
			return [_cell_focus_rect(_tutorial_build_target_cell())]
		1:
			return [_control_focus_rect(build_menu)]
		2:
			return [_cell_focus_rect(tutorial_build_cell)]
		3:
			return [_control_focus_rect($UI/StartWaveBtn)]
		4:
			return [Rect2(GameGrid.GRID_OFFSET, Vector2(GameGrid.GRID_COLS * GameGrid.CELL_SIZE, GameGrid.GRID_ROWS * GameGrid.CELL_SIZE))]
		5:
			return [_control_focus_rect($UI/StartWaveBtn)]
		6:
			return [Rect2(GameGrid.GRID_OFFSET, Vector2(GameGrid.GRID_COLS * GameGrid.CELL_SIZE, GameGrid.GRID_ROWS * GameGrid.CELL_SIZE))]
		7:
			return [_cell_focus_rect(_get_first_tower_cell())]
		8:
			return [_control_focus_rect($UI/TowerMenu/BtnUpgrade)]
		9:
			return [_control_focus_rect($UI/StartWaveBtn)]
		10:
			return [Rect2(GameGrid.GRID_OFFSET, Vector2(GameGrid.GRID_COLS * GameGrid.CELL_SIZE, GameGrid.GRID_ROWS * GameGrid.CELL_SIZE))]
		11:
			return [Rect2(GameGrid.GRID_OFFSET, Vector2(GameGrid.GRID_COLS * GameGrid.CELL_SIZE, GameGrid.GRID_ROWS * GameGrid.CELL_SIZE))]
		_:
			return []

func _get_tutorial_bubble_position() -> Vector2:
	return Vector2(390, 244)

func _tutorial_allows_map_click(cell: Vector2i) -> bool:
	match tutorial_step:
		0:
			return cell == _tutorial_build_target_cell()
		2:
			return cell == tutorial_build_cell
		4:
			return _is_inside_map(cell)
		6:
			return _is_inside_map(cell)
		7:
			return grid_map.get_tower_at(cell) != null
		11:
			return _is_inside_map(cell)
		_:
			return false

func _is_inside_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GameGrid.GRID_COLS and cell.y >= 0 and cell.y < GameGrid.GRID_ROWS

func _tutorial_build_target_cell() -> Vector2i:
	return Vector2i(1, 2)

func _cell_focus_rect(cell: Vector2i) -> Rect2:
	var pos = grid_map.cell_to_world(cell)
	var half := Vector2(GameGrid.CELL_SIZE, GameGrid.CELL_SIZE) * 0.55
	return Rect2(pos - half, half * 2.0)

func _control_focus_rect(control: Control) -> Rect2:
	if not control or not control.visible:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	return control.get_global_rect()

func _get_first_tower_cell() -> Vector2i:
	for cell in grid_map.tower_at_cell.keys():
		return cell
	return tutorial_build_cell

func _update_tutorial_controls() -> void:
	var in_tutorial := _is_tutorial_level()
	$UI/RestartBtn.disabled = in_tutorial
	$UI/HPBtn.disabled = in_tutorial
	$UI/PauseBtn.disabled = in_tutorial
	$UI/Speed2Btn.disabled = in_tutorial
	$UI/Speed4Btn.disabled = in_tutorial
	$UI/MainMenuBtn.disabled = in_tutorial
	$UI/BuildMenu/BtnProbability.disabled = in_tutorial and tutorial_step != 1
	$UI/BuildMenu/BtnObserver.disabled = in_tutorial
	$UI/BuildMenu/BtnQuarkTrap.disabled = in_tutorial
	$UI/StartWaveBtn.disabled = in_tutorial and tutorial_step not in [3, 5, 9]
	$UI/TowerMenu/BtnSell.disabled = in_tutorial
	if selected_tower:
		$UI/TowerMenu/BtnUpgrade.disabled = (selected_tower.level >= 3) or (in_tutorial and tutorial_step != 8)
	if in_tutorial and tutorial_step >= 10:
		$UI/StartWaveBtn.disabled = true

func _clear_tutorial() -> void:
	tutorial_step = -1
	tutorial_build_cell = Vector2i(-1, -1)
	tutorial_panel.visible = false
	if tutorial_overlay:
		tutorial_overlay.clear()
	if tutorial_skip_btn:
		tutorial_skip_btn.visible = false
	_update_tutorial_controls()

func _skip_tutorial() -> void:
	GameState.current_level = 1
	_start_current_level()

func _has_next_wave_to_start() -> bool:
	return wave_manager.next_spawn_index < current_wave_data.size()

func _show_tutorial_notice(text: String, duration: float = 3.2) -> void:
	if not _is_tutorial_level() or GameState.game_over or not tutorial_overlay or not tutorial_overlay.visible:
		return
	tutorial_notice_token += 1
	var token = tutorial_notice_token
	tutorial_overlay.set_tutorial_state(text, _get_tutorial_focus_rects(), _get_tutorial_bubble_position())
	get_tree().create_timer(duration).timeout.connect(func():
		if token == tutorial_notice_token and _is_tutorial_level() and not GameState.game_over and tutorial_overlay:
			_update_tutorial_overlay()
	)

func _show_tutorial_life_notice(text: String, duration: float = 4.2) -> void:
	if not _is_tutorial_level() or GameState.game_over or not tutorial_overlay:
		return
	tutorial_notice_token += 1
	var token = tutorial_notice_token
	var life_rect = _control_focus_rect($UI/HUD/LivesLabel).grow(8.0)
	var focus_rects: Array[Rect2] = [life_rect]
	tutorial_overlay.set_tutorial_state(text, focus_rects, _get_tutorial_bubble_position())
	get_tree().create_timer(duration).timeout.connect(func():
		if token == tutorial_notice_token and _is_tutorial_level() and not GameState.game_over and tutorial_overlay:
			_update_tutorial_overlay()
	)

func _get_tutorial_text(step: int) -> String:
	match step:
		0:
			return "教学 1/10：蓝色流光是敌人路线。点击路线旁的微光节点打开建造菜单。"
		1:
			return "教学 2/10：鼠标放到塔按钮上可看属性。先选择量子棱镜。"
		2:
			return "教学 3/10：移动建造影子，绿色可建造，红色不可建造。左键确认。"
		3:
			return "教学 4/10：第一座塔已就位。点击左侧“开始波次”迎敌。"
		4:
			return "教学 5/10：第一波是演示波，防御塔会击杀脆弱敌人。读完后点击高亮地图。"
		5:
			return "教学 6/10：第一波守住了。第二波敌人会加强，点击“开始波次”。"
		6:
			return "教学 7/10：第二波更强，未升级的塔会漏掉少量敌人。读完点击高亮地图继续观察。"
		7:
			return "教学 8/10：敌人抵达 OUT 会扣生命。点击防御塔准备升级。"
		8:
			return "教学 9/10：点击升级按钮。升级后，防御塔属性会提升。"
		9:
			return "教学 10/10：点击“开始波次”。升级后的塔将守住第三波。"
		10:
			return "教学 10/10：第三波正在处理。清点完成后会结算。"
		11:
			return "教学完成：升级后的防御塔守住了第三波。点击高亮地图进入结算。"
		_:
			return "教学：完成剩余波次，稳定第一条微观防线。"

func _on_upgrade_tower() -> void:
	if not selected_tower or _is_tower_selling(selected_tower):
		_cancel_all()
		return
	if _is_tutorial_level() and tutorial_step != 8:
		_show_message("请按当前教学提示操作", 1.2)
		return
	if selected_tower.level >= 3:
		_update_tower_menu()
		return

	# TowerBase.upgrade() 内部负责扣费，避免重复扣水晶。
	var upgraded := selected_tower.upgrade()
	if not upgraded:
		_show_message("水晶不足，需要 %d" % selected_tower.get_upgrade_cost())
	elif _is_tutorial_level() and tutorial_step <= 8:
		if selected_tower and is_instance_valid(selected_tower):
			selected_tower.hide_range()
		tower_menu.visible = false
		selected_tower = null
		wave_manager.set_countdown_paused(false)
		_set_tutorial_step(9)
	if selected_tower:
		_update_tower_menu()

func _on_sell_tower() -> void:
	if selected_tower and not _is_tower_selling(selected_tower):
		_start_sell_tower(selected_tower)
	_cancel_all()

func _start_sell_tower(tower: TowerBase) -> void:
	var sell_value = tower.get_sell_value()
	tower.set_meta("selling", true)
	tower.placed = false  # 拆除中停止攻击，但仍占用 grid_map，继续阻挡道路。
	tower.hide_range()
	tower.modulate.a = 0.45
	get_tree().create_timer(TOWER_SELL_DELAY).timeout.connect(func(): _finish_sell_tower(tower, sell_value))

func _finish_sell_tower(tower: TowerBase, sell_value: int) -> void:
	if not is_instance_valid(tower):
		return
	if grid_map.get_tower_at(tower.grid_cell) != tower:
		return
	GameState.add_crystals(sell_value)
	grid_map.remove_tower(tower.grid_cell)
	tower.queue_free()
	grid_map.pulse_route_hint(2.4)
	_recalculate_all_enemy_paths()

func _is_tower_selling(tower: TowerBase) -> bool:
	return tower.get_meta("selling", false)

func _update_tower_menu() -> void:
	if not selected_tower:
		return
	var upgrade_text = "满级" if selected_tower.level >= 3 else "升级 %d" % selected_tower.get_upgrade_cost()
	$UI/TowerMenu/BtnUpgrade.text = upgrade_text
	$UI/TowerMenu/BtnUpgrade.disabled = selected_tower.level >= 3
	$UI/TowerMenu/BtnSell.text = "出售 %d" % selected_tower.get_sell_value()
	tower_info_label.text = selected_tower.get_tower_info_text()

func _show_message(text: String, duration: float = 1.4) -> void:
	message_token += 1
	var token = message_token
	message_label.text = text
	message_label.visible = true
	get_tree().create_timer(duration).timeout.connect(func():
		if token == message_token:
			message_label.visible = false
	)

func _on_enemy_spawned(enemy: EnemyBase) -> void:
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.enemy_reached_end.connect(_on_enemy_reached_end)

func _on_enemy_died(enemy: EnemyBase) -> void:
	_show_float_text("+%d 水晶" % enemy.reward_crystals, enemy.global_position + Vector2(-20, -24), Color(0.65, 1.0, 0.86, 0.96))
	_pulse_control(crystal_label, Color(0.72, 1.0, 0.88, 1.0))

func _on_enemy_reached_end(enemy: EnemyBase) -> void:
	_show_float_text("生命 -%d" % enemy.damage_to_base, enemy.global_position + Vector2(-26, -24), Color(1.0, 0.42, 0.56, 0.98))

func _show_float_text(text: String, screen_pos: Vector2, color: Color) -> void:
	var label = Label.new()
	label.add_to_group("feedback_float")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.position = screen_pos
	label.size = Vector2(120, 30)
	label.modulate = Color(1, 1, 1, 1)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.04, 0.08, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	$UI.add_child(label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", screen_pos + Vector2(0, -30), 0.85)
	tween.tween_property(label, "modulate:a", 0.0, 0.85)
	tween.finished.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)

func _pulse_control(control: Control, color: Color) -> void:
	if not is_instance_valid(control):
		return
	var original_modulate = control.modulate
	var tween = create_tween()
	tween.tween_property(control, "modulate", color, 0.08)
	tween.tween_property(control, "modulate", original_modulate, 0.38)

func _cancel_all() -> void:
	selected_tower_type = ""
	build_menu.visible = false
	tower_menu.visible = false
	_hide_build_tooltip()
	if build_ghost:
		build_ghost.visible = false
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.hide_range()
	selected_tower = null

func _recalculate_all_enemy_paths() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			enemy.recalculate_path()

func _on_start_wave() -> void:
	if GameState.game_over:
		return
	if _is_tutorial_level() and grid_map.tower_at_cell.is_empty() and wave_manager.next_spawn_index == 0:
		_show_message("先在路线旁建造一座塔", 1.8)
		_set_tutorial_step(0)
		grid_map.pulse_route_hint(2.4)
		return
	wave_manager.start_wave()
	$UI/StartWaveBtn.text = "提前开始下一波"
	grid_map.pulse_route_hint(2.0)
	_update_wave_preview()
	if _is_tutorial_level() and tutorial_step == 3:
		_set_tutorial_step(4)
	elif _is_tutorial_level() and tutorial_step == 5:
		wave_manager.set_countdown_paused(false)
		_set_tutorial_step(6)
	elif _is_tutorial_level() and tutorial_step == 9:
		_set_tutorial_step(10)
	elif _is_tutorial_level() and tutorial_step >= 10:
		_update_tutorial_controls()
		_update_tutorial_overlay()

func _on_restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_toggle_hp() -> void:
	GameState.show_hp_numbers = not GameState.show_hp_numbers
	$UI/HPBtn.text = "血量: " + ("开" if GameState.show_hp_numbers else "关")
	# 刷新所有敌人显示
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_redraw()

func _on_toggle_pause() -> void:
	_set_pause(not GameState.game_paused)

func _set_pause(paused: bool) -> void:
	GameState.game_paused = paused
	$UI/PauseBtn.text = "继续" if paused else "暂停"
	pause_panel.visible = paused and not GameState.game_over
	game_compendium_panel.visible = false
	if paused:
		_cancel_all()

func _toggle_speed(speed: float) -> void:
	if is_equal_approx(current_speed_scale, speed):
		_set_speed(1.0)
	else:
		_set_speed(speed)

func _set_speed(speed: float) -> void:
	current_speed_scale = speed
	Engine.time_scale = speed
	$UI/Speed2Btn.text = "2倍速*" if is_equal_approx(speed, 2.0) else "2倍速"
	$UI/Speed4Btn.text = "4倍速*" if is_equal_approx(speed, 4.0) else "4倍速"

func _show_game_compendium() -> void:
	pause_panel.visible = false
	game_compendium_panel.visible = true
	_populate_game_compendium(game_compendium_category)

func _hide_game_compendium() -> void:
	game_compendium_panel.visible = false
	if GameState.game_paused and not GameState.game_over:
		pause_panel.visible = true

func _populate_game_compendium(category: String) -> void:
	game_compendium_category = category
	var entries = _get_game_compendium_entries()
	for i in range(game_compendium_list_buttons.size()):
		var button = game_compendium_list_buttons[i]
		if i < entries.size():
			button.visible = true
			button.text = entries[i]["name"]
		else:
			button.visible = false
	if entries.size() > 0:
		_select_game_compendium_entry(0)

func _select_game_compendium_entry(index: int) -> void:
	var entries = _get_game_compendium_entries()
	if index < 0 or index >= entries.size():
		return
	var entry = entries[index]
	game_compendium_preview.set_entry(game_compendium_category, entry)
	game_compendium_detail_label.text = "%s\n%s\n\n%s\n\n%s" % [
		entry["name"],
		entry["role"],
		entry["stats"],
		entry["detail"],
	]

func _get_game_compendium_entries() -> Array[Dictionary]:
	return COMPENDIUM_DATA.get_enemies() if game_compendium_category == "enemies" else COMPENDIUM_DATA.get_towers()

func _on_all_waves_done() -> void:
	$UI/StartWaveBtn.disabled = true
	GameState.unlock_next_level(GameState.current_level)
	wave_preview_label.text = "本关波次完成\n清点防线状态"
	if _is_tutorial_level():
		$UI/StartWaveBtn.text = "教学完成"
		wave_preview_label.text = "教学完成\n点击地图结算"
		_set_tutorial_step(11)
		return
	if GameState.current_level < level_maps.size():
		$UI/StartWaveBtn.text = "本关完成"
		next_level_btn.text = "挑战第%d关" % (GameState.current_level + 1)
		next_level_btn.visible = false
	else:
		$UI/StartWaveBtn.text = "全部完成"
		next_level_btn.visible = false
	GameState.trigger_game_over(true)

func _on_next_level() -> void:
	if GameState.current_level >= level_maps.size():
		return
	GameState.current_level += 1
	_start_current_level()

func _on_wave_ready() -> void:
	$UI/StartWaveBtn.disabled = false
	$UI/StartWaveBtn.text = "开始波次"
	_update_wave_preview()
	if _is_tutorial_level() and wave_manager.completed_waves == 1:
		wave_manager.set_countdown_paused(true)
		if tutorial_step < 5:
			_set_tutorial_step(4)
		else:
			_update_tutorial_controls()
			_update_tutorial_overlay()
	elif _is_tutorial_level() and wave_manager.completed_waves == 2:
		wave_manager.set_countdown_paused(true)
		tutorial_pressure_wave_closed = true
		_set_tutorial_step(7)
	elif _is_tutorial_level() and tutorial_step >= 10:
		_update_tutorial_controls()
		_update_tutorial_overlay()

func _on_countdown_changed(remaining: float) -> void:
	if _is_tutorial_level() and wave_manager.countdown_paused:
		$UI/StartWaveBtn.text = "倒计时暂停"
		_update_wave_preview("学习模式暂停")
		return
	$UI/StartWaveBtn.text = "下波 %ds" % int(ceil(max(remaining, 0.0)))
	_update_wave_preview("倒计时 %ds" % int(ceil(max(remaining, 0.0))))

func _on_lives_changed(new_amount: int) -> void:
	if new_amount < last_lives:
		_pulse_control(lives_label, Color(1.0, 0.42, 0.56, 1.0))
	if _is_tutorial_level() and new_amount < last_lives and not tutorial_life_notice_shown:
		tutorial_life_notice_shown = true
		_show_tutorial_life_notice("生命值减少了：有敌人抵达 OUT。第二波结束后，我们会升级防御塔来解决它。", 4.2)
		if GameState.current_wave == 2 and not tutorial_pressure_wave_closed:
			tutorial_pressure_wave_closed = true
			get_tree().create_timer(1.8).timeout.connect(_finish_tutorial_pressure_wave)
	last_lives = new_amount

func _finish_tutorial_pressure_wave() -> void:
	if not _is_tutorial_level() or GameState.game_over or GameState.current_wave != 2:
		return
	wave_manager.active_spawns.clear()
	wave_manager.completed_waves = max(wave_manager.completed_waves, 2)
	wave_manager.next_spawn_index = max(wave_manager.next_spawn_index, 2)
	wave_manager.is_countdown = true
	wave_manager.countdown_timer = wave_manager.wave_delay
	wave_manager.set_countdown_paused(true)
	GameState.wave_active = false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for bullet in get_tree().get_nodes_in_group("bullet"):
		if is_instance_valid(bullet):
			bullet.queue_free()
	_update_wave_preview("学习模式暂停")
	_set_tutorial_step(7)

func _on_victory() -> void:
	_show_result(true)

func _on_defeat() -> void:
	_show_result(false)

func _show_result(won: bool) -> void:
	_cancel_all()
	if _is_tutorial_level():
		tutorial_notice_token += 1
		tutorial_step = -1
		tutorial_panel.visible = false
		if tutorial_overlay:
			tutorial_overlay.clear()
		if tutorial_skip_btn:
			tutorial_skip_btn.visible = false
	result_panel.visible = true
	result_next_btn.visible = won and GameState.current_level < level_maps.size()
	result_next_btn.disabled = not result_next_btn.visible
	result_next_btn.text = "下一关"
	result_replay_btn.text = "重玩本关"
	result_menu_btn.text = "返回菜单"

	var level_name := _get_current_level_name()
	var summary := "关卡: %s\n波次: %d/%d\n生命: %d    水晶: %d" % [
		level_name,
		GameState.current_wave,
		GameState.total_waves,
		GameState.lives,
		GameState.crystals,
	]
	if won:
		result_title.add_theme_color_override("font_color", Color(0.78, 1.0, 0.9))
		if GameState.current_level == 0:
			result_title.text = "教学完成"
			result_body.text = "你已经掌握建塔、路线提示与波次预告。接下来可以进入第1关。\n\n%s" % summary
		elif GameState.current_level >= level_maps.size():
			result_title.text = "微观纪元完成"
			result_body.text = "5 个裂谷节点全部稳定。这个试玩切片已经通关。\n\n%s" % summary
		else:
			result_title.text = "关卡完成"
			result_body.text = "防线稳定，下一处微观裂谷已开放。\n\n%s" % summary
	else:
		result_title.add_theme_color_override("font_color", Color(1.0, 0.62, 0.72))
		result_title.text = "防线崩溃"
		result_body.text = "奇迹之塔受损。调整塔位与波次节奏，再试一次。\n\n%s" % summary

func _get_current_level_name() -> String:
	if GameState.current_level == 0:
		return "教学关：微光入门"
	var map_index := clampi(GameState.current_level - 1, 0, level_maps.size() - 1)
	return str(level_maps[map_index].get("name", "第%d关" % GameState.current_level))
