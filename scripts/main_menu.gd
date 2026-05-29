# MainMenu - 主菜单
extends Control

func _ready() -> void:
	$BtnStart.pressed.connect(_on_start_pressed)
	$BtnQuit.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
