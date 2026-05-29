# GameManager - 游戏主控制器 v2
# 处理塔建造、升级、出售、波次控制、游戏流程

class_name GameManager
extends Node2D

# 塔场景引用
var tower_scenes: Dictionary = {
	"probability": preload("res://scripts/towers/probability_tower.gd"),
	"observer": preload("res://scripts/towers/observer_tower.gd"),
	"quark_trap": preload("res://scripts/towers/quark_trap.gd"),
}

# 可建造位置
var buildable_positions: Array[Vector2] = []
var occupied_positions: Dictionary = {}

# 放置状态
var selected_tower_type: String = ""
var placing_tower: bool = false

# 选中塔
var selected_tower: TowerBase = null

# 节点引用
@onready var enemy_path: Path2D = $Map/EnemyPath
@onready var wave_manager: WaveManager = $WaveManager
@onready var hud_script: Node = $UI/HUD
@onready var build_menu: Control = $UI/BuildMenu
@onready var tower_menu: Control = $UI/TowerMenu
@onready var victory_label: Label = $UI/VictoryLabel
@onready var defeat_label: Label = $UI/DefeatLabel

# 第一关波次数据
var level_1_waves = [
	[["res://scripts/enemies/virtual_particle.gd", 8, 1.5]],
	[["res://scripts/enemies/virtual_particle.gd", 6, 1.2], ["res://scripts/enemies/free_electron.gd", 4, 1.2]],
	[["res://scripts/enemies/proton_cluster.gd", 3, 3.0]],
	[["res://scripts/enemies/virtual_particle.gd", 4, 1.0], ["res://scripts/enemies/free_electron.gd", 3, 1.0], ["res://scripts/enemies/proton_cluster.gd", 2, 2.0]],
	[["res://scripts/enemies/free_electron.gd", 15, 0.5]],
]

func _ready() -> void:
	GameState.reset()
	_setup_buildable_positions()
	_setup_ui_connections()
	_setup_signals()
	wave_manager.load_wave_data(level_1_waves)

func _setup_buildable_positions() -> void:
	var markers = get_tree().get_nodes_in_group("build_position")
	for marker in markers:
		if marker is Node2D:
			buildable_positions.append(marker.global_position)

func _setup_ui_connections() -> void:
	$UI/StartWaveBtn.pressed.connect(_on_start_wave)
	$UI/BuildMenu/BtnProbability.pressed.connect(func(): _on_tower_selected("probability"))
	$UI/BuildMenu/BtnObserver.pressed.connect(func(): _on_tower_selected("observer"))
	$UI/BuildMenu/BtnQuarkTrap.pressed.connect(func(): _on_tower_selected("quark_trap"))
	$UI/TowerMenu/BtnUpgrade.pressed.connect(_on_upgrade_tower)
	$UI/TowerMenu/BtnSell.pressed.connect(_on_sell_tower)

func _setup_signals() -> void:
	GameState.game_won.connect(_on_victory)
	GameState.game_lost.connect(_on_defeat)
	wave_manager.all_waves_finished.connect(_on_all_waves_done)

func _input(event: InputEvent) -> void:
	if GameState.game_over:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_all()

func _handle_left_click(click_pos: Vector2) -> void:
	# 如果正在放置塔
	if placing_tower and selected_tower_type != "":
		_try_place_tower(click_pos)
		return

	# 检查是否点击了已放置的塔
	var tower = _find_tower_at(click_pos)
	if tower:
		_select_tower(tower)
		return

	# 检查是否点击了建造位
	var build_pos = _find_build_position(click_pos)
	if build_pos != Vector2.INF and not occupied_positions.has(build_pos):
		_show_build_menu_at(build_pos)
		return

	_cancel_all()

func _find_tower_at(pos: Vector2) -> TowerBase:
	for bp in occupied_positions:
		var tower = occupied_positions[bp] as TowerBase
		if tower and is_instance_valid(tower):
			if pos.distance_to(tower.global_position) < 32:
				return tower
	return null

func _find_build_position(pos: Vector2) -> Vector2:
	for bp in buildable_positions:
		if pos.distance_to(bp) < 35:
			return bp
	return Vector2.INF

func _show_build_menu_at(pos: Vector2) -> void:
	_cancel_all()
	build_menu.visible = true
	build_menu.position = pos + Vector2(0, -60)

func _on_tower_selected(type: String) -> void:
	selected_tower_type = type
	placing_tower = true
	build_menu.visible = false

func _try_place_tower(click_pos: Vector2) -> void:
	var build_pos = _find_build_position(click_pos)
	if build_pos == Vector2.INF or occupied_positions.has(build_pos):
		return

	var tower_script = tower_scenes.get(selected_tower_type)
	if not tower_script:
		return

	var tower = _instantiate_tower(tower_script)
	if not tower:
		return

	if not GameState.spend_crystals(tower.build_cost):
		tower.queue_free()
		return

	tower.position = build_pos
	tower.placed = true
	tower._setup_range()
	add_child(tower)
	occupied_positions[build_pos] = tower

	placing_tower = false
	selected_tower_type = ""

func _instantiate_tower(script: Script) -> TowerBase:
	var node = Node2D.new()
	node.set_script(script)

	var area = Area2D.new()
	area.name = "RangeArea"
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	area.add_child(collision)
	node.add_child(area)

	# 占位视觉
	var visual = ColorRect.new()
	visual.name = "Visual"
	visual.size = Vector2(32, 32)
	visual.position = Vector2(-16, -16)
	visual.color = Color(randf(), randf(), randf(), 0.8)
	node.add_child(visual)

	return node as TowerBase

func _select_tower(tower: TowerBase) -> void:
	_cancel_all()
	selected_tower = tower
	tower_menu.visible = true
	tower_menu.position = tower.global_position + Vector2(0, -60)
	tower.show_range()

func _on_upgrade_tower() -> void:
	if selected_tower and selected_tower.level < 3:
		var cost = selected_tower.get_upgrade_cost()
		if GameState.spend_crystals(cost):
			selected_tower.upgrade()
	_cancel_all()

func _on_sell_tower() -> void:
	if selected_tower:
		var pos = selected_tower.global_position
		GameState.add_crystals(selected_tower.build_cost / 2)
		for bp in occupied_positions:
			if occupied_positions[bp] == selected_tower:
				occupied_positions.erase(bp)
				break
		selected_tower.queue_free()
	_cancel_all()

func _cancel_all() -> void:
	placing_tower = false
	selected_tower_type = ""
	build_menu.visible = false
	tower_menu.visible = false
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.hide_range()
	selected_tower = null

func _on_start_wave() -> void:
	if GameState.wave_active or GameState.game_over:
		return
	$UI/StartWaveBtn.disabled = true
	wave_manager.start_wave()

func _on_all_waves_done() -> void:
	# 所有波次已生成，等场上敌人清空后自动胜利
	pass

func _on_victory() -> void:
	victory_label.visible = true

func _on_defeat() -> void:
	defeat_label.visible = true
