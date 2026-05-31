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

const TOWER_SELL_DELAY: float = 2.0

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
var next_level_btn: Button = null
var current_speed_scale: float = 1.0

# 波次数据（10波，5个层级递进）
var level_1_waves = [
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 6,  "interval": 1.5, "tier": 1}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 8,  "interval": 1.3, "tier": 1}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 5,  "interval": 1.2, "tier": 1},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 2.0, "tier": 2}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 8,  "interval": 1.0, "tier": 2}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 5,  "interval": 1.2, "tier": 2},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 2.0, "tier": 3}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 6,  "interval": 1.3, "tier": 3}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 4,  "interval": 1.2, "tier": 3},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 2,  "interval": 2.5, "tier": 4}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 4,  "interval": 1.3, "tier": 4}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 3,  "interval": 1.2, "tier": 4},
	 {"path": "res://scripts/enemies/enemy_tier.gd", "count": 2,  "interval": 2.5, "tier": 5}],
	[{"path": "res://scripts/enemies/enemy_tier.gd", "count": 4,  "interval": 2.0, "tier": 5}],
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
	if GameState.current_level < 1 or GameState.current_level > level_maps.size():
		GameState.current_level = 1
	_setup_ui_connections()
	_setup_signals()
	_start_current_level()

func _setup_ui_connections() -> void:
	_ensure_next_level_button()
	$UI/StartWaveBtn.pressed.connect(_on_start_wave)
	$UI/RestartBtn.pressed.connect(_on_restart)
	$UI/HPBtn.pressed.connect(_on_toggle_hp)
	$UI/PauseBtn.pressed.connect(_on_toggle_pause)
	$UI/Speed2Btn.pressed.connect(func(): _toggle_speed(2.0))
	$UI/Speed4Btn.pressed.connect(func(): _toggle_speed(4.0))
	$UI/BuildMenu/BtnProbability.pressed.connect(func(): _on_tower_selected("probability"))
	$UI/BuildMenu/BtnObserver.pressed.connect(func(): _on_tower_selected("observer"))
	$UI/BuildMenu/BtnQuarkTrap.pressed.connect(func(): _on_tower_selected("quark_trap"))
	$UI/TowerMenu/BtnUpgrade.pressed.connect(_on_upgrade_tower)
	$UI/TowerMenu/BtnSell.pressed.connect(_on_sell_tower)
	next_level_btn.pressed.connect(_on_next_level)

func _ensure_next_level_button() -> void:
	next_level_btn = $UI.get_node_or_null("NextLevelBtn") as Button
	if next_level_btn:
		return
	next_level_btn = Button.new()
	next_level_btn.name = "NextLevelBtn"
	next_level_btn.visible = false
	next_level_btn.text = "挑战下一关"
	next_level_btn.offset_left = 560
	next_level_btn.offset_top = 430
	next_level_btn.offset_right = 720
	next_level_btn.offset_bottom = 475
	$UI.add_child(next_level_btn)

func _setup_signals() -> void:
	GameState.game_won.connect(_on_victory)
	GameState.game_lost.connect(_on_defeat)
	wave_manager.all_waves_finished_signal.connect(_on_all_waves_done)
	wave_manager.wave_ready.connect(_on_wave_ready)
	wave_manager.countdown_changed.connect(_on_countdown_changed)

func _start_current_level() -> void:
	GameState.reset()
	_clear_level_runtime()
	_setup_map_for_current_level()
	wave_manager.load_wave_data(level_1_waves)

	victory_label.visible = false
	defeat_label.visible = false
	next_level_btn.visible = false
	$UI/StartWaveBtn.disabled = false
	$UI/StartWaveBtn.text = "开始波次"
	$UI/HPBtn.text = "血量: " + ("开" if GameState.show_hp_numbers else "关")
	_set_pause(false)
	_set_speed(1.0)

func _setup_map_for_current_level() -> void:
	var map_index = clampi(GameState.current_level - 1, 0, level_maps.size() - 1)
	GameState.current_level = map_index + 1
	var map_data = level_maps[map_index]
	grid_map.load_map(map_data["blocked_rects"])
	victory_label.text = "%s 通过！" % map_data["name"]

func _clear_level_runtime() -> void:
	_cancel_all()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for bullet in get_tree().get_nodes_in_group("bullet"):
		if is_instance_valid(bullet):
			bullet.queue_free()
	for tower in grid_map.tower_at_cell.values():
		if is_instance_valid(tower):
			tower.queue_free()

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
	var ui_nodes = [$UI/StartWaveBtn, $UI/RestartBtn, $UI/HPBtn, $UI/PauseBtn, $UI/Speed2Btn, $UI/Speed4Btn, $UI/BuildMenu, $UI/TowerMenu, next_level_btn]
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
		if _is_tower_selling(existing_tower):
			_cancel_all()
		else:
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
	if _is_enemy_in_cell(cell):
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
	tower_menu.position = tower.global_position + Vector2(0, -60)
	tower.show_range()

func _on_upgrade_tower() -> void:
	if selected_tower and selected_tower.level < 3 and not _is_tower_selling(selected_tower):
		# TowerBase.upgrade() 内部负责扣费，避免重复扣水晶。
		selected_tower.upgrade()
	_cancel_all()

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
	_recalculate_all_enemy_paths()

func _is_tower_selling(tower: TowerBase) -> bool:
	return tower.get_meta("selling", false)

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
	if GameState.game_over:
		return
	wave_manager.start_wave()
	$UI/StartWaveBtn.text = "提前开始下一波"

func _on_restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

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

func _on_all_waves_done() -> void:
	$UI/StartWaveBtn.disabled = true
	if GameState.current_level < level_maps.size():
		$UI/StartWaveBtn.text = "本关完成"
		next_level_btn.text = "挑战第%d关" % (GameState.current_level + 1)
		next_level_btn.visible = true
	else:
		$UI/StartWaveBtn.text = "全部完成"
		victory_label.text = "5个关卡全部完成！"
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

func _on_countdown_changed(remaining: float) -> void:
	$UI/StartWaveBtn.text = "下波 %ds" % int(ceil(max(remaining, 0.0)))

func _on_victory() -> void:
	victory_label.visible = true

func _on_defeat() -> void:
	defeat_label.visible = true
