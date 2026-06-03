# EnemyTier - 分等级敌人
# 5 个层级，血量和水晶掉落递增

class_name EnemyTier
extends EnemyBase

@export var tier: int = 1

var visual_time: float = 0.0

# 层级配置: [血量, 速度, 护甲, 水晶, 扣血, 颜色]
const TIER_DATA = {
	1: [8,  100, 0.0, 2,  1, Color(0.42, 0.95, 1.0)],
	2: [16, 90,  0.0, 4,  1, Color(0.55, 1.0, 0.68)],
	3: [26, 80,  0.08, 7, 1, Color(0.5, 0.62, 1.0)],
	4: [44, 70,  0.15, 11, 2, Color(0.76, 0.46, 1.0)],
	5: [76, 60,  0.22, 18, 3, Color(1.0, 0.52, 0.28)],
}

func _ready() -> void:
	var cfg = TIER_DATA.get(tier, TIER_DATA[1])
	enemy_name = "T%d" % tier
	max_health = cfg[0]
	speed = cfg[1]
	armor = cfg[2]
	reward_crystals = cfg[3]
	damage_to_base = cfg[4]
	add_to_group("enemy")
	super()

func _process(delta: float) -> void:
	visual_time += delta
	super(delta)
	if not is_dead:
		queue_redraw()

func _draw() -> void:
	var cfg = TIER_DATA.get(tier, TIER_DATA[1])
	var color = cfg[5]
	var radius = _get_body_radius()

	if not is_visible_target:
		color.a *= 0.25

	match tier:
		1:
			_draw_virtual_spore(color, radius)
		2:
			_draw_proto_cell(color, radius)
		_:
			_draw_dense_cluster(color, radius)

	# 血条（始终显示）
	var bar_width = radius * 2.2
	var bar_height = 2.5
	var bar_y = -radius - 11
	var hp_ratio = current_health / max_health
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width, bar_height), Color(0.3, 0.1, 0.1))
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width * hp_ratio, bar_height), Color.RED if hp_ratio < 0.3 else Color.GREEN)

	# 血量数字
	if GameState.show_hp_numbers:
		var hp_text = "%d" % max(0, int(ceil(current_health)))
		draw_string(ThemeDB.fallback_font, Vector2(-10, bar_y - 3), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)

func _get_body_radius() -> float:
	match tier:
		1:
			return 10.0
		2:
			return 14.0
		_:
			return 7.0 + tier * 1.7

func _draw_virtual_spore(color: Color, radius: float) -> void:
	var pulse = 0.75 + 0.25 * sin(visual_time * 8.0)
	draw_circle(Vector2.ZERO, radius * 1.9 * pulse, Color(color.r, color.g, color.b, 0.08), false, 2.0)
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.32))
	draw_circle(Vector2.ZERO, radius * 0.55, Color(0.88, 1.0, 1.0, 0.82))
	for i in range(3):
		var angle = visual_time * 2.2 + i * TAU / 3.0
		var p = Vector2(cos(angle), sin(angle)) * radius * 1.35
		draw_circle(p, 2.2, Color(0.72, 0.95, 1.0, 0.72))

func _draw_proto_cell(color: Color, radius: float) -> void:
	var wobble = 1.0 + 0.08 * sin(visual_time * 4.0)
	draw_circle(Vector2.ZERO, radius * wobble, Color(color.r, color.g, color.b, 0.30))
	draw_circle(Vector2.ZERO, radius * wobble, Color(0.86, 1.0, 0.9, 0.75), false, 2.0)
	draw_circle(Vector2(-4, -2), radius * 0.42, Color(0.22, 0.75, 0.78, 0.76))
	draw_circle(Vector2(5, 4), radius * 0.28, Color(0.9, 1.0, 0.72, 0.62))
	for i in range(5):
		var angle = visual_time * 1.5 + i * TAU / 5.0
		var p = Vector2(cos(angle), sin(angle)) * radius * 0.85
		draw_circle(p, 1.4, Color(1.0, 1.0, 0.95, 0.65))

func _draw_dense_cluster(color: Color, radius: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.58))
	draw_circle(Vector2.ZERO, radius, Color.WHITE, false, 1.1)
	for i in range(tier):
		var angle = i * TAU / max(1, tier) + visual_time * 0.8
		var p = Vector2(cos(angle), sin(angle)) * radius * 0.46
		draw_circle(p, radius * 0.28, Color(1.0, 1.0, 1.0, 0.18))
