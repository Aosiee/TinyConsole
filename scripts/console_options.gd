extends RefCounted

const CONFIG_PATH := "res://addons/tiny_console.cfg"

@export_category("Commands | Aliases")
@export var aliases := {
	"exit": "quit",
	"source": "exec",
	"cls": "clear",
}

@export_category("Commands | Disables")
@export var commands_disabled_in_release: Array = [
	"eval" # enables arbitrary code execution and asset extraction in the running game.
]

@export_category("Toggles")
@export var disable_in_release : bool = true
@export var enable_commandline_override : bool = true
@export var print_to_stdout: bool = true
@export var pause_when_open: bool = true

@export_category("Visuals")
@export var height_ratio : float = 0.5
@export var animation_speed : float = 5.0
@export var opacity : float = 1.0
@export var sparse_mode : bool = false

@export_category("greet")
@export var greet_user : bool = true
@export var greeting_message : String = "Tiny Console" #{project_name}
@export var greet_using_ascii_art : bool = true

@export_category("History")
@export var persistant_history : bool = true
@export var max_lines : int = 200
@export var max_log_storage : int = 15000

@export_category("Auto-Complete")
@export var autocomplete_use_history_with_matches : bool = true

@export_category("Auto Exec")
@export var autoexec_script : String = "user://autoexec.lcs"
@export var autoexec_auto_create : bool = true
