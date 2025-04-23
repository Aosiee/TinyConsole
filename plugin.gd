@tool
extends EditorPlugin

const ConsoleOptions := preload("res://addons/tiny_console/scripts/console_options.gd")
const ConfigMapper := preload("res://addons/tiny_console/scripts/config_mapper.gd")

func _enter_tree() -> void:
	add_autoload_singleton("TinyConsole", "res://addons/tiny_console/scripts/tiny_console.gd")
	
	var console_options := ConsoleOptions.new()
	var do_project_setting_save: bool = false
	ConfigMapper.load_from_config(console_options)
	ConfigMapper.save_to_config(console_options)
	
	if not ProjectSettings.has_setting("input/tiny_console_toggle"):
		print("TinyConsole: Adding \"tiny_console_toggle\" input action to project settings")

		var key_event := InputEventKey.new()
		key_event.keycode = KEY_QUOTELEFT

		ProjectSettings.set_setting("input/tiny_console_toggle", {
			"deadzone": 0.5,
			"events": [key_event]
		})
		do_project_setting_save = true

	if not ProjectSettings.has_setting("input/tiny_console_search_history"):
		print("TinyConsole: Adding \"tiny_console_search_history\" input action to project settings...")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_R
		key_event.ctrl_pressed = true

		ProjectSettings.set_setting("input/tiny_console_search_history", {
			"deadzone": 0.5,
			"events": [key_event],
		})
		do_project_setting_save = true

	if do_project_setting_save:
		ProjectSettings.save()


func _exit_tree() -> void:
	remove_autoload_singleton("TinyConsole")
