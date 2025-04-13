@tool
extends EditorPlugin

const ConsoleOptions = preload("res://addons/tiny_console/scripts/console_options.gd")

func _enter_tree() -> void:
	add_autoload_singleton("TinyConsole", "res://addons/tiny_console/scripts/tiny_console.gd")
	
	var console_options := ConsoleOptions.new()
	
	if not ProjectSettings.has_setting("input/tiny_console_toggle"):
		print("TinyConsole: Adding \"tiny_console_toggle\" input action to project settings")
		
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_QUOTELEFT
		
		ProjectSettings.set_setting("input/tiny_console_toggle", {
			"deadzone": 0.5,
			"events": [key_event]
		})
		
		ProjectSettings.save()

func _exit_tree() -> void:
	remove_autoload_singleton("TinyConsole")
