# GameManager - 游戏主控制器 v3 (网格版)
# 网格塔防：点击格子造塔，敌人A*寻路绕行

class_name GameManager
extends Node2D

# 塔脚本引用
var tower_scripts: Dictionary = {
	"probability": preload("res://scripts/towers/probability_tower.gd"),
	"observer": preload("res://scripts/towers/observer_tower.gd"),
	"quark_trap": preload("res://scripts/towers/quark_trap.gd"),
}

# 节点引用
@onready var grid_map = $GameGrid
@onready var wave_manager: WaveManager = $WaveManager
@onready var build_menu: Control = $UI/BuildMenu
@onready var tower_menu: Control = $UI/TowerMenu
@onready var victory_label: Label = $UI/VictoryLabel
@onready var defeat_label: Label = $UI/DefeatLabel
@onready var enemy_container: Node2D = $Enemies

# 状态
var selected_tower_type: String = ""
var selected_tower: TowerBase = null

# 波次数据（15波，5个层级递进）
var level_1_waves = [
	# 波 1-3: T1 基础
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 6,  "interval": 1.5, "tier": 1}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 8,  "interval": 1.3, "tier": 1}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 10, "interval": 1.2, "tier": 1}],
	# 波 4-6: T1+T2 混搭
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 6,  "interval": 1.2, "tier": 1},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 2.0, "tier": 2}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 5,  "interval": 1.0, "tier": 1},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 5,  "interval": 1.5, "tier": 2}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 8,  "interval": 1.0, "tier": 2}],
	# 波 7-9: T2+T3 混搭
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 5,  "interval": 1.2, "tier": 2},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 2.0, "tier": 3}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 4,  "interval": 1.0, "tier": 2},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 4,  "interval": 1.5, "tier": 3}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 6,  "interval": 1.3, "tier": 3}],
	# 波 10-12: T3+T4 混搭
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 4,  "interval": 1.2, "tier": 3},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 2,  "interval": 2.5, "tier": 4}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 1.0, "tier": 3},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 1.5, "tier": 4}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 4,  "interval": 1.3, "tier": 4}],
	# 波 13-14: T4+T5 混搭
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 1.2, "tier": 4},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 2,  "interval": 2.5, "tier": 5}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 2,  "interval": 1.0, "tier": 4},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 2.0, "tier": 5}],
	# 波 15: T5 Boss 波
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 5,  "interval": 2.0, "tier": 5}],
]

func _ready() -> void:
	GameState.reset()
	_setup_ui_connections()
	_setup_signals()
	wave_manager.load_wave_data(level_1_waves)

func _setup_ui_connections() -> void:
	$UI/StartWaveBtn.pressed.connect(_on_start_wave)
	$UI/RestartBtn.pressed.connect(_on_restart)
	$UI/HPBtn.pressed.connect(_on_toggle_hp)
	$UI/BuildMenu/BtnProbability.pressed.connect(func(): _on_tower_selected("probability"))
	$UI/BuildMenu/BtnObserver.pressed.connect(func(): _on_tower_selected("observer"))
	$UI/BuildMenu/BtnQuarkTrap.pressed.connect(func(): _on_tower_selected("quark_trap"))
	$UI/TowerMenu/BtnUpgrade.pressed.connect(_on_upgrade_tower)
	$UI/TowerMenu/BtnSell.pressed.connect(_on_sell_tower)

func _setup_signals() -> void:
	GameState.game_won.connect(_on_victory)
	GameState.game_lost.connect(_on_defeat)
	wave_manager.all_waves_finished.connect(_on_all_waves_done)
	wave_manager.wave_ready.connect(_on_wave_ready)

func _input(event: InputEvent) -> void:
	if GameState.game_over:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 跳过 UI 区域的点击
		if _is_mouse_over_ui(event.position):
			return
		_handle_click(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel_all()

func _is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	var ui_nodes = [$UI/StartWaveBtn, $UI/BuildMenu, $UI/TowerMenu]
	for node in ui_nodes:
		if node and node is Control and node.visible:
			if node.get_global_rect().has_point(mouse_pos):
				return true
	return false

func _handle_click(click_pos: Vector2) -> void:
	var cell = grid_map.world_to_cell(click_pos)

	# 如果正在放置塔
	if selected_tower_type != "":
		_try_place_tower(cell)
		return

	# 检查是否点击了已有塔
	var existing_tower = grid_map.get_tower_at(cell)
	if existing_tower:
		_select_tower(existing_tower)
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

func _on_tower_selected(type: String) -> void:
	selected_tower_type = type
	build_menu.visible = false

func _try_place_tower(cell: Vector2i) -> void:
	if not grid_map.is_cell_empty(cell):
		return

	var script = tower_scripts.get(selected_tower_type)
	if not script:
		return

	# 创建塔节点（先不入树，读取默认值检查）
	var tower = Node2D.new()
	tower.set_script(script)
	if not tower is TowerBase:
		tower.queue_free()
		return

	# 先入树触发 _ready() 让 build_cost 等属性正确初始化
	add_child(tower)
	
	# 现在检查费用
	if not GameState.spend_crystals(tower.build_cost):
		tower.queue_free()
		return

	# 尝试放置到网格
	if not grid_map.place_tower(cell, tower):
		GameState.add_crystals(tower.build_cost)  # 退款
		tower.queue_free()
		return

	tower.position = grid_map.cell_to_world(cell)
	tower.placed = true
	tower.grid_cell = cell

	selected_tower_type = ""
	_recalculate_all_enemy_paths()

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
		GameState.add_crystals(selected_tower.get_sell_value())
		grid_map.remove_tower(selected_tower.grid_cell)
		selected_tower.queue_free()
		_recalculate_all_enemy_paths()
	_cancel_all()

func _cancel_all() -> void:
	selected_tower_type = ""
	build_menu.visible = false
	tower_menu.visible = false
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.hide_range()
	selected_tower = null

func _recalculate_all_enemy_paths() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			enemy.recalculate_path()

func _on_start_wave() -> void:
	if GameState.wave_active or GameState.game_over:
		return
	$UI/StartWaveBtn.disabled = true
	wave_manager.start_wave()

func _on_restart() -> void:
	get_tree().reload_current_scene()

func _on_toggle_hp() -> void:
	GameState.show_hp_numbers = not GameState.show_hp_numbers
	$UI/HPBtn.text = "血量: " + ("开" if GameState.show_hp_numbers else "关")
	# 刷新所有敌人显示
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_redraw()

func _on_all_waves_done() -> void:
	$UI/StartWaveBtn.text = "全部完成"
	$UI/StartWaveBtn.text = "全部完成"

func _on_wave_ready() -> void:
	$UI/StartWaveBtn.disabled = false
	$UI/StartWaveBtn.text = "开始波次"

func _on_victory() -> void:
	victory_label.visible = true

func _on_defeat() -> void:
	defeat_label.visible = true
