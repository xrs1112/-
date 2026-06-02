# BuildGhost - 建造前预览影子
class_name BuildGhost
extends Control

var tower_type: String = ""
var can_build: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_preview(type: String, valid: bool) -> void:
	tower_type = type
	can_build = valid
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	var ok_color = Color(0.42, 1.0, 0.82, 0.48)
	var bad_color = Color(1.0, 0.2, 0.18, 0.58)
	var color = ok_color if can_build else bad_color

	draw_circle(center, 19.0, Color(color.r, color.g, color.b, 0.16))
	draw_circle(center, 17.0, color, false, 2.0)
	if not can_build:
		draw_line(center + Vector2(-13, -13), center + Vector2(13, 13), Color(1.0, 0.16, 0.12, 0.86), 2.2)
		draw_line(center + Vector2(13, -13), center + Vector2(-13, 13), Color(1.0, 0.16, 0.12, 0.86), 2.2)

	match tower_type:
		"observer":
			_draw_observer(center, color)
		"quark_trap":
			_draw_trap(center, color)
		_:
			_draw_prism(center, color)

func _draw_prism(center: Vector2, color: Color) -> void:
	var points = PackedVector2Array([
		center + Vector2(0, -14),
		center + Vector2(12, 8),
		center + Vector2(-12, 8),
	])
	draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.48))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), color.lightened(0.35), 1.4)
	draw_circle(center, 3.5, color.lightened(0.45))

func _draw_observer(center: Vector2, color: Color) -> void:
	draw_circle(center, 13.5, Color(color.r, color.g, color.b, 0.18))
	draw_circle(center, 13.5, color, false, 1.8)
	draw_circle(center, 6.0, Color(color.r, color.g, color.b, 0.45))
	draw_line(center + Vector2(-15, 0), center + Vector2(15, 0), color, 1.2)
	draw_line(center + Vector2(0, -15), center + Vector2(0, 15), Color(color.r, color.g, color.b, 0.55), 1.0)

func _draw_trap(center: Vector2, color: Color) -> void:
	draw_circle(center, 14.5, Color(color.r, color.g, color.b, 0.18))
	draw_circle(center, 14.5, color, false, 2.0)
	draw_circle(center, 8.5, Color(color.r, color.g, color.b, 0.28), false, 1.5)
	for i in range(6):
		var angle = i * TAU / 6.0
		draw_circle(center + Vector2(cos(angle), sin(angle)) * 11.0, 1.7, color.lightened(0.25))
