extends Node

var logger: ConsoleLoggerBackend

class ConsoleLoggerBackend extends Logger:
	
	var console: RichTextLabel:
		set(cons):
			console = cons
			for message in messages:
				console.append_text(message)
	
	var messages: Array[String]
	
	# Note that this method is not called for messages that use
	# `push_error()` and `push_warning()`, even though these are printed to stderr.
	func _log_message(message: String, error: bool) -> void:
		# Do something with `message`.
		# `error` is `true` for messages printed to the standard error stream (stderr) with `print_error()`.
		var to_print = message if not error else "[color=c45959][b]ERROR[/b]: {0}[/color]".format([message])
		messages.append(to_print)
		if console:
			console.append_text(to_print + "\n")
		# Note that this method will be called from threads other than the main thread, possibly at the same
		# time, so you will need to have some kind of thread-safety as part of it, like a Mutex.
		pass

	#func _log_error(
			#function: String,
			#file: String,
			#line: int,
			#code: String,
			#rationale: String,
			#editor_notify: bool,
			#error_type: int,
			#script_backtraces: Array[ScriptBacktrace]
	#) -> void:
		## Do something with the error. The error text is in `rationale`.
		## See the Logger class reference for details on other parameters.
		#pass

# Use `_init()` to initialize the logger as early as possible, which ensures that messages
# printed early are taken into account. However, even when using `_init()`, the engine's own
# initialization messages are not accessible.
func _init() -> void:
	logger = ConsoleLoggerBackend.new()
	OS.add_logger(logger)


func set_console(console: RichTextLabel):
	logger.console = console
