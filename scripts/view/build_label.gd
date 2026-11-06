extends Label
## Shows which build is running, so Ben can tell he has the latest one.
## CI writes build_info.txt (date + commit) before exporting.

const BUILD_INFO_PATH := "res://build_info.txt"


func _ready() -> void:
	var info := "local build"
	if FileAccess.file_exists(BUILD_INFO_PATH):
		info = FileAccess.get_file_as_string(BUILD_INFO_PATH).strip_edges()
	text = "build " + info
