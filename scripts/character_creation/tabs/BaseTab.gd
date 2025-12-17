# ╔═══════════════════════════════════════════════════════════
# ║ BaseTab.gd
# ║ Desc: Base class for character creation tabs
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name BaseTab
extends Control

## Signal emitted when tab data changes
signal data_changed(data: Dictionary)

## Tab name
var tab_name: String = ""

## Tab data
var tab_data: Dictionary = {}


func _ready() -> void:
	"""Initialize the tab."""
	_apply_ui_constants()
	_setup_tab()


func _apply_ui_constants() -> void:
	"""Apply UIConstants to tab UI elements."""
	# Override in subclasses
	pass


func _setup_tab() -> void:
	"""Setup tab-specific UI elements."""
	# Override in subclasses
	pass


func get_tab_data() -> Dictionary:
	"""Get current tab data."""
	return tab_data.duplicate()


func set_tab_data(data: Dictionary) -> void:
	"""Set tab data from external source."""
	tab_data = data.duplicate()
	_load_data()
	_emit_data_changed()


func _load_data() -> void:
	"""Load data into UI elements."""
	# Override in subclasses
	pass


func _emit_data_changed() -> void:
	"""Emit data changed signal."""
	data_changed.emit(tab_data)


func is_valid() -> bool:
	"""Check if tab data is valid."""
	# Override in subclasses
	return true
