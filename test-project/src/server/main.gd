extends Node


func _ready() -> void:
	host_game()


func host_game():
	Networking.new().start_server()
	start_game()


func start_game():
	get_tree().paused = false
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	change_level.call_deferred(load("res://src/shared/levels/test.tscn"))


# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	# Add new level.
	level.add_child(scene.instantiate())


# The server can restart the level by pressing HOME.
func _input(event):
	if event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
		print("Level restart")
		change_level.call_deferred(load("res://src/shared/levels/test.tscn"))

	if event.is_action_pressed("ui_cancel"):
		print("Server closed")
		get_tree().quit()
