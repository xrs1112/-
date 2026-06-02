# CompendiumPreview - 图鉴预览画布
class_name CompendiumPreview
extends Control

var category: String = "towers"
var entry: Dictionary = {}
var visual_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_entry(new_category: String, new_entry: Dictionary) -> void:
	category = new_category
	entry = new_entry
	queue_redraw()

func _process(delta: float) -> void:
	visual_time += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.04, 0.075, 0.72), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.28, 0.9, 1.0, 0.34), false, 1.0)
	if entry.is_empty():
		return

	if category == "enemies":
		_draw_enemy_preview()
	else:
		_draw_tower_preview()

func _draw_tower_preview() -> void:
	var tower_type = str(entry.get("type", "probability"))
	var centers = [
		Vector2(size.x * 0.22, size.y * 0.52),
		Vector2(size.x * 0.50, size.y * 0.52),
		Vector2(size.x * 0.78, size.y * 0.52),
	]
	for i in range(3):
		var level = i + 1
		draw_string(ThemeDB.fallback_font, centers[i] + Vector2(-19, 50), "Lv.%d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.82, 0.96, 1.0, 0.9))
		_draw_tower_icon(tower_type, level, centers[i])

func _draw_enemy_preview() -> void:
	var tier = int(entry.get("tier", 1))
	var center = Vector2(size.x * 0.34, size.y * 0.52)
	_draw_enemy_icon(tier, center, 2.2)
	draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.56, 44), str(entry.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.88, 0.98, 1.0, 0.96))
	draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.56, 76), str(entry.get("role", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.68, 1.0, 0.9, 0.84))

func _draw_tower_icon(tower_type: String, level: int, center: Vector2) -> void:
	var base_color := _tower_color(tower_type).lightened(0.12 * float(level - 1))
	base_color.a = 0.86
	draw_circle(center, 22.0 + level * 4.0, Color(base_color.r, base_color.g, base_color.b, 0.20))
	if level >= 2:
		draw_circle(center, 27.0, Color(base_color.r, base_color.g, base_color.b, 0.26), false, 1.4)
	if level >= 3:
		draw_circle(center, 32.0, Color(0.86, 0.98, 1.0, 0.28), false, 1.2)

	match tower_type:
		"observer":
			_draw_observer_icon(center, level, base_color)
		"quark_trap":
			_draw_trap_icon(center, level, base_color)
		_:
			_draw_prism_icon(center, level, base_color)

func _draw_prism_icon(center: Vector2, level: int, color: Color) -> void:
	var points = PackedVector2Array([
		center + Vector2(0, -18),
		center + Vector2(16, 10),
		center + Vector2(-16, 10),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color(0.85, 0.95, 1.0, 0.85), 1.4)
	draw_circle(center, 5.0, Color(0.85, 1.0, 1.0, 0.9))
	if level >= 2:
		var rail_color = Color(0.75, 0.95, 1.0, 0.78)
		draw_polyline(PackedVector2Array([center + Vector2(-21, 14), center + Vector2(0, 24), center + Vector2(21, 14)]), rail_color, 1.7)
		draw_line(center + Vector2(-22, -2), center + Vector2(-10, -10), rail_color, 1.5)
		draw_line(center + Vector2(22, -2), center + Vector2(10, -10), rail_color, 1.5)
	if level >= 3:
		for i in range(3):
			var angle := visual_time * 0.9 + i * TAU / 3.0
			draw_line(center + Vector2(cos(angle), sin(angle)) * 10.0, center + Vector2(cos(angle), sin(angle)) * 30.0, Color(0.6, 1.0, 0.95, 0.55), 1.4)
		_draw_orbit_nodes(center, 29.0, 3, Color(0.85, 1.0, 1.0, 0.9), visual_time, 2.5)

func _draw_observer_icon(center: Vector2, level: int, color: Color) -> void:
	draw_circle(center, 17.0, Color(color.r, color.g, color.b, 0.24))
	draw_circle(center, 17.0, Color(1.0, 0.95, 0.55, 0.7), false, 2.0)
	draw_circle(center, 8.0, color.lightened(0.2))
	draw_circle(center, 3.0, Color(1.0, 1.0, 0.8, 0.95))
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), Color(1.0, 1.0, 0.7, 0.35), 1.2)
	if level >= 2:
		var scan_color = Color(1.0, 0.98, 0.55, 0.72)
		draw_circle(center, 23.0, scan_color, false, 1.5)
		draw_line(center + Vector2(0, -25), center + Vector2(0, -12), scan_color, 1.2)
		draw_line(center + Vector2(0, 12), center + Vector2(0, 25), scan_color, 1.2)
	if level >= 3:
		var start_angle := visual_time * 1.6
		draw_arc(center, 29.0, start_angle, start_angle + PI * 0.72, 18, Color(1.0, 1.0, 0.72, 0.7), 2.0)
		draw_arc(center, 29.0, start_angle + PI, start_angle + PI * 1.72, 18, Color(0.75, 1.0, 1.0, 0.52), 1.5)
		_draw_orbit_nodes(center, 28.0, 4, Color(1.0, 0.95, 0.52, 0.88), -visual_time * 0.75, 2.1)

func _draw_trap_icon(center: Vector2, level: int, color: Color) -> void:
	draw_circle(center, 19.0, Color(color.r, color.g, color.b, 0.18))
	draw_circle(center, 19.0, color.lightened(0.1), false, 2.4)
	draw_circle(center, 11.0, Color(1.0, 0.55, 0.25, 0.35), false, 2.0)
	for i in range(6):
		var angle = i * TAU / 6.0
		draw_circle(center + Vector2(cos(angle), sin(angle)) * 15.0, 2.0, Color(1.0, 0.82, 0.35, 0.75))
	if level >= 2:
		for i in range(3):
			var angle := -PI / 2.0 + i * TAU / 3.0
			var outer := center + Vector2(cos(angle), sin(angle)) * 27.0
			var inner := center + Vector2(cos(angle), sin(angle)) * 19.0
			draw_line(inner, outer, Color(1.0, 0.65, 0.28, 0.75), 2.0)
			draw_circle(outer, 3.0, Color(1.0, 0.65, 0.28, 0.75))
	if level >= 3:
		for i in range(8):
			var angle := visual_time * 0.55 + i * TAU / 8.0
			var p1 := center + Vector2(cos(angle), sin(angle)) * 22.0
			var p2 := center + Vector2(cos(angle + 0.16), sin(angle + 0.16)) * 31.0
			draw_line(p1, p2, Color(1.0, 0.28, 0.15, 0.8), 1.4)
		_draw_orbit_nodes(center, 30.0, 5, Color(1.0, 0.82, 0.35, 0.82), visual_time * 1.15, 2.2)

func _draw_enemy_icon(tier: int, center: Vector2, scale: float) -> void:
	var cfg = _enemy_config(tier)
	var color: Color = cfg["color"]
	var radius: float = cfg["radius"] * scale
	match tier:
		1:
			var pulse = 0.75 + 0.25 * sin(visual_time * 8.0)
			draw_circle(center, radius * 1.9 * pulse, Color(color.r, color.g, color.b, 0.08), false, 3.0)
			draw_circle(center, radius, Color(color.r, color.g, color.b, 0.32))
			draw_circle(center, radius * 0.55, Color(0.88, 1.0, 1.0, 0.82))
			_draw_orbit_nodes(center, radius * 1.35, 3, Color(0.72, 0.95, 1.0, 0.72), visual_time * 2.2, 3.0)
		2:
			var wobble = 1.0 + 0.08 * sin(visual_time * 4.0)
			draw_circle(center, radius * wobble, Color(color.r, color.g, color.b, 0.30))
			draw_circle(center, radius * wobble, Color(0.86, 1.0, 0.9, 0.75), false, 2.0)
			draw_circle(center + Vector2(-8, -4), radius * 0.42, Color(0.22, 0.75, 0.78, 0.76))
			draw_circle(center + Vector2(10, 8), radius * 0.28, Color(0.9, 1.0, 0.72, 0.62))
			_draw_orbit_nodes(center, radius * 0.85, 5, Color(1.0, 1.0, 0.95, 0.65), visual_time * 1.5, 2.2)
		_:
			draw_circle(center, radius, Color(color.r, color.g, color.b, 0.58))
			draw_circle(center, radius, Color.WHITE, false, 1.2)
			for i in range(tier):
				var angle = i * TAU / max(1, tier) + visual_time * 0.8
				var p = center + Vector2(cos(angle), sin(angle)) * radius * 0.46
				draw_circle(p, radius * 0.28, Color(1.0, 1.0, 1.0, 0.18))

func _draw_orbit_nodes(center: Vector2, radius: float, count: int, color: Color, phase: float, node_radius: float) -> void:
	for i in range(count):
		var angle := phase + i * TAU / float(count)
		draw_circle(center + Vector2(cos(angle), sin(angle)) * radius, node_radius, color)

func _tower_color(tower_type: String) -> Color:
	match tower_type:
		"observer":
			return Color(0.7, 0.7, 0.2, 0.8)
		"quark_trap":
			return Color(0.7, 0.25, 0.15, 0.8)
		_:
			return Color(0.3, 0.3, 0.7, 0.8)

func _enemy_config(tier: int) -> Dictionary:
	match tier:
		1:
			return {"radius": 10.0, "color": Color(0.42, 0.95, 1.0)}
		2:
			return {"radius": 14.0, "color": Color(0.55, 1.0, 0.68)}
		3:
			return {"radius": 12.1, "color": Color(0.5, 0.62, 1.0)}
		4:
			return {"radius": 13.8, "color": Color(0.76, 0.46, 1.0)}
		_:
			return {"radius": 15.5, "color": Color(1.0, 0.52, 0.28)}
