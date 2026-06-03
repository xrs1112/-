class_name TutorialOverlay
extends Control

var focus_rects: Array[Rect2] = []
var bubble_text: String = ""
var bubble_position: Vector2 = Vector2(320, 112)
var pulse_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	pulse_time += delta
	if visible:
		queue_redraw()

func set_tutorial_state(text: String, rects: Array[Rect2], text_position: Vector2) -> void:
	bubble_text = text
	focus_rects = rects
	bubble_position = text_position
	visible = true
	queue_redraw()

func clear() -> void:
	visible = false
	focus_rects.clear()
	bubble_text = ""
	queue_redraw()

func _draw() -> void:
	if not visible:
		return

	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.0, 0.0, 0.0, 0.52))

	var pulse := 0.5 + 0.5 * sin(pulse_time * TAU * 1.6)
	for rect in focus_rects:
		var grown := rect.grow(8.0)
		draw_rect(grown, Color(0.18, 0.8, 1.0, 0.08 + pulse * 0.05))
		draw_rect(grown, Color(0.64, 1.0, 0.88, 0.72 + pulse * 0.2), false, 2.0)
		draw_rect(grown.grow(5.0), Color(0.34, 0.95, 1.0, 0.22), false, 1.0)

	var bubble_size := Vector2(520, 78)
	var bubble_rect := Rect2(bubble_position, bubble_size)
	draw_rect(bubble_rect, Color(0.018, 0.055, 0.1, 0.94))
	draw_rect(bubble_rect, Color(0.62, 1.0, 0.9, 0.72), false, 1.4)
	draw_line(bubble_rect.position + Vector2(12, 0), bubble_rect.position + Vector2(bubble_size.x - 12, 0), Color(0.75, 1.0, 0.9, 0.3), 2.0)
	draw_multiline_string(ThemeDB.fallback_font, bubble_rect.position + Vector2(18, 28), bubble_text, HORIZONTAL_ALIGNMENT_LEFT, bubble_size.x - 36.0, 16, 3, Color(0.9, 0.99, 1.0, 0.98))
