# MainMenu - 主菜单
extends Control

const COMPENDIUM_DATA = preload("res://scripts/compendium_data.gd")
const COMPENDIUM_PREVIEW = preload("res://scripts/compendium_preview.gd")

@onready var level_buttons: Array[Button] = [
	$LevelPanel/Level1Btn,
	$LevelPanel/Level2Btn,
	$LevelPanel/Level3Btn,
	$LevelPanel/Level4Btn,
	$LevelPanel/Level5Btn,
]
@onready var compendium_button: Button = $BtnCompendium

var compendium_panel: Panel = null
var compendium_preview: Control = null
var compendium_detail_label: RichTextLabel = null
var compendium_list_buttons: Array[Button] = []
var compendium_category: String = "towers"

func _ready() -> void:
	_setup_compendium_ui()
	_apply_style()
	_setup_level_buttons()
	$BtnStart.pressed.connect(_on_start_pressed)
	compendium_button.pressed.connect(_show_compendium)
	$BtnQuit.pressed.connect(_on_quit_pressed)

func _apply_style() -> void:
	$LevelPanel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.07, 0.13, 0.76), Color(0.25, 0.86, 1.0, 0.52)))
	for button in [$BtnStart, compendium_button, $BtnQuit] + level_buttons + compendium_list_buttons:
		_style_button(button, 18)
	if compendium_panel:
		compendium_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.018, 0.055, 0.1, 0.95), Color(0.34, 0.95, 1.0, 0.72)))
		for button in [$CompendiumPanel/CloseBtn, $CompendiumPanel/TowersTab, $CompendiumPanel/EnemiesTab]:
			_style_button(button, 15)
		for label in [$CompendiumPanel/Title]:
			label.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
			label.add_theme_color_override("font_shadow_color", Color(0.0, 0.12, 0.22, 0.9))
			label.add_theme_constant_override("shadow_offset_x", 1)
			label.add_theme_constant_override("shadow_offset_y", 1)
		compendium_detail_label.add_theme_color_override("default_color", Color(0.88, 0.98, 1.0))
		compendium_detail_label.add_theme_font_size_override("normal_font_size", 15)

func _style_button(button: Button, font_size: int = 18) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.05, 0.13, 0.22, 0.86), Color(0.2, 0.85, 1.0, 0.62)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.07, 0.22, 0.34, 0.92), Color(0.45, 1.0, 0.92, 0.86)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.03, 0.1, 0.18, 0.95), Color(0.9, 1.0, 0.75, 0.9)))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.03, 0.04, 0.06, 0.72), Color(0.18, 0.24, 0.3, 0.8)))
	button.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.82))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.58, 0.64, 0.9))
	button.add_theme_font_size_override("font_size", font_size)

func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = _make_panel_style(bg, border)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

func _setup_level_buttons() -> void:
	for i in range(level_buttons.size()):
		var level = i + 1
		var button = level_buttons[i]
		var unlocked = GameState.is_level_unlocked(level)
		button.disabled = not unlocked
		button.text = "第%d关" % level if unlocked else "第%d关 锁定" % level
		button.pressed.connect(func(): _start_level(level))

func _setup_compendium_ui() -> void:
	compendium_panel = Panel.new()
	compendium_panel.name = "CompendiumPanel"
	compendium_panel.visible = false
	compendium_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	compendium_panel.set_anchors_preset(Control.PRESET_CENTER)
	compendium_panel.offset_left = -390
	compendium_panel.offset_top = -260
	compendium_panel.offset_right = 390
	compendium_panel.offset_bottom = 260
	add_child(compendium_panel)

	var title = Label.new()
	title.name = "Title"
	title.text = "微观图鉴"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.set_position(Vector2(24, 22))
	title.size = Vector2(728, 42)
	compendium_panel.add_child(title)

	var close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "关闭"
	close_btn.set_position(Vector2(674, 24))
	close_btn.size = Vector2(84, 36)
	close_btn.pressed.connect(_hide_compendium)
	compendium_panel.add_child(close_btn)

	var towers_tab = Button.new()
	towers_tab.name = "TowersTab"
	towers_tab.text = "防御塔"
	towers_tab.set_position(Vector2(34, 78))
	towers_tab.size = Vector2(112, 36)
	towers_tab.pressed.connect(func(): _populate_compendium("towers"))
	compendium_panel.add_child(towers_tab)

	var enemies_tab = Button.new()
	enemies_tab.name = "EnemiesTab"
	enemies_tab.text = "敌人"
	enemies_tab.set_position(Vector2(158, 78))
	enemies_tab.size = Vector2(112, 36)
	enemies_tab.pressed.connect(func(): _populate_compendium("enemies"))
	compendium_panel.add_child(enemies_tab)

	for i in range(6):
		var button = Button.new()
		button.name = "EntryBtn%d" % i
		button.set_position(Vector2(34, 136 + i * 54))
		button.size = Vector2(220, 42)
		button.visible = false
		var index = i
		button.pressed.connect(func(): _select_compendium_entry(index))
		compendium_panel.add_child(button)
		compendium_list_buttons.append(button)

	compendium_detail_label = RichTextLabel.new()
	compendium_detail_label.name = "Detail"
	compendium_detail_label.bbcode_enabled = false
	compendium_detail_label.fit_content = false
	compendium_detail_label.scroll_active = true
	compendium_detail_label.selection_enabled = false
	compendium_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	compendium_detail_label.set_position(Vector2(292, 256))
	compendium_detail_label.size = Vector2(438, 240)
	compendium_panel.add_child(compendium_detail_label)

	compendium_preview = COMPENDIUM_PREVIEW.new()
	compendium_preview.name = "Preview"
	compendium_preview.set_position(Vector2(292, 86))
	compendium_preview.size = Vector2(438, 150)
	compendium_panel.add_child(compendium_preview)
	_populate_compendium("towers")

func _show_compendium() -> void:
	compendium_panel.visible = true
	_populate_compendium(compendium_category)

func _hide_compendium() -> void:
	compendium_panel.visible = false

func _input(event: InputEvent) -> void:
	if compendium_panel and compendium_panel.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not compendium_panel.get_global_rect().has_point(event.position):
				_hide_compendium()

func _populate_compendium(category: String) -> void:
	compendium_category = category
	var entries = _get_compendium_entries()
	for i in range(compendium_list_buttons.size()):
		var button = compendium_list_buttons[i]
		if i < entries.size():
			button.visible = true
			button.text = entries[i]["name"]
		else:
			button.visible = false
	if entries.size() > 0:
		_select_compendium_entry(0)

func _select_compendium_entry(index: int) -> void:
	var entries = _get_compendium_entries()
	if index < 0 or index >= entries.size():
		return
	var entry = entries[index]
	compendium_preview.set_entry(compendium_category, entry)
	compendium_detail_label.text = "%s\n%s\n\n%s\n\n%s" % [
		entry["name"],
		entry["role"],
		entry["stats"],
		entry["detail"],
	]

func _get_compendium_entries() -> Array[Dictionary]:
	return COMPENDIUM_DATA.get_enemies() if compendium_category == "enemies" else COMPENDIUM_DATA.get_towers()

func _on_start_pressed() -> void:
	_start_level(0)

func _start_level(level: int) -> void:
	if not GameState.is_level_unlocked(level):
		return
	GameState.select_level(level)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
