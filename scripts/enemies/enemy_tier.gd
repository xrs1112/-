# EnemyTier - 分等级敌人
# 5 个层级，血量和水晶掉落递增

class_name EnemyTier
extends EnemyBase

@export var tier: int = 1

# 层级配置: [血量, 速度, 护甲, 水晶, 扣血, 颜色]
const TIER_DATA = {
	1: [5,  100, 0.0, 3,  1, Color(0.5, 0.5, 0.5)],
	2: [10, 90,  0.0, 6,  1, Color(0.2, 0.7, 0.3)],
	3: [20, 80,  0.1, 12, 1, Color(0.2, 0.5, 0.9)],
	4: [40, 70,  0.2, 25, 2, Color(0.6, 0.3, 0.9)],
	5: [80, 60,  0.3, 50, 3, Color(1.0, 0.4, 0.2)],
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

func _draw() -> void:
	var cfg = TIER_DATA.get(tier, TIER_DATA[1])
	var color = cfg[5]
	var radius = 5.0 + tier * 1.5

	if not is_visible_target:
		color.a *= 0.25

	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius, Color.WHITE, false, 1.0)

	# 血条（始终显示）
	var bar_width = radius * 2.5
	var bar_height = 2.5
	var bar_y = -radius - 8
	var hp_ratio = current_health / max_health
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width, bar_height), Color(0.3, 0.1, 0.1))
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width * hp_ratio, bar_height), Color.RED if hp_ratio < 0.3 else Color.GREEN)

	# 血量数字
	if GameState.show_hp_numbers:
		var hp_text = "%d" % max(0, ceil(current_health))
		draw_string(ThemeDB.fallback_font, Vector2(-10, bar_y - 3), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
