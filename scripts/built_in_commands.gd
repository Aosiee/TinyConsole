extends RefCounted
## BuiltinCommands

const TinyUtil := preload("res://addons/tiny_console/scripts/tiny_utils.gd")

const COMMAND_INDENT := 4
const SUBCATEGORY_OFFSET := 2

static func register_commands() -> void:
	TinyConsole.register_command(cmd_commands, "commands", "list all commands", "Built In")
	TinyConsole.register_command(cmd_help, "help", "show command info", "Built In")
	TinyConsole.register_command(cmd_alias, "alias", "add command alias", "Built In")
	TinyConsole.register_command(cmd_aliases, "aliases", "list all aliases", "Built In")
	TinyConsole.register_command(TinyConsole.clear_console, "clear", "clear console screen", "Built In")
	TinyConsole.register_command(TinyConsole.info, "echo", "display a line of text", "Built In")
	TinyConsole.register_command(cmd_eval, "eval", "evaluate an expression", "Built In")
	TinyConsole.register_command(cmd_exec, "exec", "execute commands from file", "Built In")
	TinyConsole.register_command(cmd_fullscreen, "fullscreen", "toggle fullscreen mode", "Built In")
	TinyConsole.register_command(cmd_log, "log", "show recent log entries", "Built In")
	TinyConsole.register_command(cmd_quit, "quit", "exit the application", "Built In")
	TinyConsole.register_command(cmd_unalias, "unalias", "remove command alias", "Built In")
	
	TinyConsole.register_command(cmd_fps_max, "fps_max", "limit framerate", "Built In|Performance")
	TinyConsole.register_command(cmd_vsync, "vsync", "adjust V-Sync", "Built In|Performance")

	TinyConsole.add_argument_autocomplete_source("help", 1, TinyConsole.get_command_names.bind(true))

static func _alias_usage() -> void:
	TinyConsole.info("Usage: %s alias_name command_to_run [args...]" % [TinyConsole.format_name("alias")])

static func cmd_alias(p_alias_expression: String = "") -> void:
	if p_alias_expression.is_empty():
		_alias_usage()
		return

	var sz: int = p_alias_expression.length()
	var idx: int = 0

	while idx < sz and p_alias_expression[idx] == ' ':
		idx += 1
	var end: int = idx

	while end < sz and p_alias_expression[end] != ' ':
		end += 1

	var alias: String = p_alias_expression.substr(idx, end - idx)
	if not alias.is_valid_identifier():
		TinyConsole.error("Invalid alias identifier '%s'" % [alias])
		_alias_usage()
		return

	idx = end
	while idx < sz and p_alias_expression[idx] == ' ':
		idx += 1

	end = idx
	while end < sz and p_alias_expression[end] != ' ':
		end += 1
	var command: String = p_alias_expression.substr(idx, end - idx).strip_edges()

	if not command.is_valid_identifier():
		TinyConsole.error("Invalid command identifier.")
		_alias_usage()
		return

	# Note: It should be possible to create aliases for commands that are not yet registered.

	idx = end
	var args: String = p_alias_expression.substr(idx).strip_edges()
	TinyConsole.remove_alias(alias)
	TinyConsole.add_alias(alias, command + ' ' + args)
	TinyConsole.info("Added %s: %s %s" % [TinyConsole.format_name(alias), command, args])


static func cmd_aliases() -> void:
	var aliases: Array = TinyConsole.get_aliases()
	aliases.sort()
	for alias in aliases:
		var alias_argv: PackedStringArray = TinyConsole.get_alias_argv(alias)
		var cmd_name: String = alias_argv[0]
		var desc: String = TinyConsole.get_command_description(cmd_name)
		alias_argv[0] = TinyConsole.format_name(cmd_name)
		if desc.is_empty():
			TinyConsole.info(TinyConsole.format_name(alias))
		else:
			TinyConsole.info("%s is alias of: %s %s" % [
				TinyConsole.format_name(alias),
				' '.join(alias_argv),
				TinyConsole.format_tip(" // " + desc)
			])


static func cmd_commands() -> void:
	TinyConsole.info("Available commands:", false)

	var category_tree := {}

	for data in TinyConsole._commands:
		var cat_str: String = data.get("Category", "")
		var path := cat_str.split("|") if cat_str != "" else []

		var target_dict := ensure_category_path(category_tree, path)
		if not target_dict.has("_commands"):
			target_dict["_commands"] = []
		target_dict["_commands"].append(data)

	# Recursively print categorized commands
	print_category_tree(category_tree)

# Helper to ensure a category path exists in the tree
static func ensure_category_path(tree: Dictionary, path: Array) -> Dictionary:
	var current = tree
	var node = tree
	for part in path:
		if not current.has(part):
			current[part] = {
				"_commands": [],
				"_subcategories": {}
			}
		node = current[part]
		current = node["_subcategories"]
	return node

# Recursive printer
static func print_category_tree(tree: Dictionary, depth: int = 0) -> void:
	var keys := []
	for key in tree.keys():
		if key != "_commands" and key != "_subcategories":
			keys.append(key)
	keys.sort()

	for key in keys:
		var sub = tree[key]

		# CATEGORY: 0 spaces at depth 0, else 2 spaces per level (subcategories)
		var cat_indent = 0 if depth == 0 else (COMMAND_INDENT - SUBCATEGORY_OFFSET) * depth
		var cat_indent_str = " ".repeat(cat_indent)
		TinyConsole.info("%s%s" % [cat_indent_str, key], false)

		# COMMANDS: category indent + 4 spaces
		var cmd_indent = cat_indent + COMMAND_INDENT
		var cmd_indent_str = " ".repeat(cmd_indent)

		var commands = sub.get("_commands", [])
		for cmd_data in commands:
			var name = TinyConsole.format_name(cmd_data["Name"])
			var desc = TinyConsole.get_command_description(cmd_data["Name"])
			var cmd_str = name if desc.is_empty() else "%s -- %s" % [name, desc]
			TinyConsole.info("%s%s" % [cmd_indent_str, cmd_str], false)

		# Recurse
		var subcats = sub.get("_subcategories", {})
		print_category_tree(subcats, depth + 1)

static func cmd_eval(p_expression: String) -> Error:
	var exp := Expression.new()
	var err: int = exp.parse(p_expression, TinyConsole.get_eval_input_names())
	if err != OK:
		TinyConsole.error(exp.get_error_text())
		return err
	var result = exp.execute(TinyConsole.get_eval_inputs(),
		TinyConsole.get_eval_base_instance())
	if not exp.has_execute_failed():
		if result != null:
			TinyConsole.info(str(result))
		return OK
	else:
		TinyConsole.error(exp.get_error_text())
		return ERR_SCRIPT_FAILED


static func cmd_exec(p_file: String, p_silent: bool = true) -> void:
	if not p_file.ends_with(".lcs"):
		# Prevent users from reading other game assets.
		p_file += ".lcs"
	if not FileAccess.file_exists(p_file):
		p_file = "user://" + p_file
	TinyConsole.execute_script(p_file, p_silent)


static func cmd_fps_max(p_limit: int = -1) -> void:
	if p_limit < 0:
		if Engine.max_fps == 0:
			TinyConsole.info("Framerate is unlimited.")
		else:
			TinyConsole.info("Framerate is limited to %d FPS." % [Engine.max_fps])
		return

	Engine.max_fps = p_limit
	if p_limit > 0:
		TinyConsole.info("Limiting framerate to %d FPS." % [p_limit])
	elif p_limit == 0:
		TinyConsole.info("Removing framerate limits.")


static func cmd_fullscreen() -> void:
	if TinyConsole.get_viewport().mode == Window.MODE_WINDOWED:
		# get_viewport().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		TinyConsole.get_viewport().mode = Window.MODE_FULLSCREEN
		TinyConsole.info("Window switched to fullscreen mode.")
	else:
		TinyConsole.get_viewport().mode = Window.MODE_WINDOWED
		TinyConsole.info("Window switched to windowed mode.")


static func cmd_help(p_command_name: String = "") -> Error:
	if p_command_name.is_empty():
		TinyConsole.print_line(TinyConsole.format_tip("Type %s to list all available commands." %
				[TinyConsole.format_name("commands")]), false)
		TinyConsole.print_line(TinyConsole.format_tip("Type %s to get more info about the command." %
				[TinyConsole.format_name("help command")]), false)
		return OK
	else:
		return TinyConsole.usage(p_command_name)


static func cmd_log(p_num_lines: int = 10) -> Error:
	var fn: String = ProjectSettings.get_setting("debug/file_logging/log_path")
	var file = FileAccess.open(fn, FileAccess.READ)
	if not file:
		TinyConsole.error("Can't open file: " + fn)
		return ERR_CANT_OPEN
	var contents := file.get_as_text()
	var lines := contents.split('\n')
	if lines.size() and lines[lines.size() - 1].strip_edges() == "":
		lines.remove_at(lines.size() - 1)
	lines = lines.slice(maxi(lines.size() - p_num_lines, 0))
	for line in lines:
		TinyConsole.print_line(TinyUtil.bbcode_escape(line))
	return OK


static func cmd_quit() -> void:
	TinyConsole.get_tree().quit()


static func cmd_unalias(p_alias: String) -> void:
	if TinyConsole.has_alias(p_alias):
		TinyConsole.remove_alias(p_alias)
		TinyConsole.info("Alias removed.")
	else:
		TinyConsole.warn("Alias not found.")


static func cmd_vsync(p_mode: int = -1) -> void:
	if p_mode < 0:
		var current: int = DisplayServer.window_get_vsync_mode()
		if current == 0:
			TinyConsole.info("V-Sync: disabled.")
		elif current == 1:
			TinyConsole.info('V-Sync: enabled.')
		elif current == 2:
			TinyConsole.info('Current V-Sync mode: adaptive.')
		TinyConsole.info("Adjust V-Sync mode with an argument: 0 - disabled, 1 - enabled, 2 - adaptive.")
	elif p_mode == DisplayServer.VSYNC_DISABLED:
		TinyConsole.info("Changing to disabled.")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	elif p_mode == DisplayServer.VSYNC_ENABLED:
		TinyConsole.info("Changing to default V-Sync.")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif p_mode == DisplayServer.VSYNC_ADAPTIVE:
		TinyConsole.info("Changing to adaptive V-Sync.")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	else:
		TinyConsole.error("Invalid mode.")
		TinyConsole.info("Acceptable modes: 0 - disabled, 1 - enabled, 2 - adaptive.")
