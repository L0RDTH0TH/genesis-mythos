# ╔═══════════════════════════════════════════════════════════
# ║ ParameterRow.gd
# ║ Desc: Reusable parameter row component for WorldBuilderUI (object pooling)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name ParameterRow
extends HBoxContainer

## Signal emitted when parameter value changes
signal parameter_changed(azgaar_key: String, value: Variant)

## Parameter metadata
var param_data: Dictionary = {}
var azgaar_key: String = ""

## UI references
@onready var name_label: Label = %NameLabel
@onready var control_container: HBoxContainer = %ControlContainer
@onready var value_label: Label = %ValueLabel

## Current control instance
var current_control: Control = null


func _ready() -> void:
	"""Initialize the parameter row."""
	_apply_ui_constants()


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
	if name_label:
		name_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
	if value_label:
		value_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_NARROW, 0)


func setup(param: Dictionary) -> void:
	"""Setup the row with parameter data."""
	param_data = param
	azgaar_key = param.get("azgaar_key", param.get("name", ""))
	
	# Update label
	if name_label:
		var param_name: String = param.get("name", "")
		name_label.text = param_name.capitalize() + ":"
	
	# Clear existing control
	_clear_control()
	
	# Create appropriate control based on type
	var param_type: String = param.get("type", param.get("ui_type", "HSlider"))
	match param_type:
		"OptionButton":
			_create_option_button(param)
		"HSlider":
			_create_slider(param)
		"CheckBox":
			_create_checkbox(param)
		"SpinBox":
			_create_spinbox(param)
		_:
			_create_label(param)
	
	# Show the row
	visible = true


func _clear_control() -> void:
	"""Clear existing control from container."""
	if current_control:
		current_control.queue_free()
		current_control = null
	
	if value_label:
		value_label.visible = false


func _create_option_button(param: Dictionary) -> void:
	"""Create OptionButton control."""
	var control: OptionButton = OptionButton.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_WIDE, UIConstants.BUTTON_HEIGHT_SMALL)
	
	if param.has("options"):
		for opt in param.options:
			control.add_item(str(opt))
		var default_val = param.get("default", "")
		var default_idx: int = param.options.find(default_val)
		if default_idx >= 0:
			control.selected = default_idx
	
	control.item_selected.connect(func(idx: int): 
		var value = control.get_item_text(idx)
		parameter_changed.emit(azgaar_key, value)
	)
	
	control_container.add_child(control)
	current_control = control


func _create_slider(param: Dictionary) -> void:
	"""Create HSlider control with value label."""
	var control: HSlider = HSlider.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if param.has("min"):
		control.min_value = param.min
	if param.has("max"):
		control.max_value = param.max
	if param.has("step"):
		control.step = param.step
	
	var default_val: float = param.get("default", 0.0)
	control.value = default_val
	
	if value_label:
		value_label.text = str(control.value)
		value_label.visible = true
	
	control.value_changed.connect(func(val: float): 
		if value_label:
			value_label.text = str(val)
		parameter_changed.emit(azgaar_key, val)
	)
	
	control_container.add_child(control)
	current_control = control


func _create_checkbox(param: Dictionary) -> void:
	"""Create CheckBox control."""
	var control: CheckBox = CheckBox.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_WIDE, UIConstants.BUTTON_HEIGHT_SMALL)
	
	var default_val: bool = param.get("default", false)
	control.button_pressed = default_val
	
	control.toggled.connect(func(on: bool): 
		parameter_changed.emit(azgaar_key, on)
	)
	
	control_container.add_child(control)
	current_control = control


func _create_spinbox(param: Dictionary) -> void:
	"""Create SpinBox control."""
	var control: SpinBox = SpinBox.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_WIDE, UIConstants.BUTTON_HEIGHT_SMALL)
	
	if param.has("min"):
		control.min_value = param.min
	if param.has("max"):
		control.max_value = param.max
	if param.has("step"):
		control.step = param.step
	
	var default_val = param.get("default", 0)
	control.value = default_val
	
	control.value_changed.connect(func(val: float): 
		parameter_changed.emit(azgaar_key, int(val))
	)
	
	control_container.add_child(control)
	current_control = control


func _create_label(param: Dictionary) -> void:
	"""Create Label control (fallback)."""
	var control: Label = Label.new()
	control.text = "Unsupported type: " + param.get("type", "unknown")
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control_container.add_child(control)
	current_control = control


func update_value(value: Variant) -> void:
	"""Update the control value without emitting signal."""
	if not current_control:
		return
	
	match current_control.get_class():
		"OptionButton":
			var opt: OptionButton = current_control as OptionButton
			for i in range(opt.get_item_count()):
				if opt.get_item_text(i) == str(value):
					opt.selected = i
					break
		"HSlider":
			var slider: HSlider = current_control as HSlider
			slider.value = float(value)
			if value_label:
				value_label.text = str(value)
		"CheckBox":
			var checkbox: CheckBox = current_control as CheckBox
			checkbox.button_pressed = bool(value)
		"SpinBox":
			var spinbox: SpinBox = current_control as SpinBox
			spinbox.value = float(value)


func hide_row() -> void:
	"""Hide the row (for object pooling)."""
	visible = false
	set_active(false)  # Disable processing when hidden
	_clear_control()
	param_data = {}
	azgaar_key = ""


func set_active(active: bool) -> void:
	"""Enable/disable processing for this row based on visibility (GUI Performance Fix)."""
	if active:
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		process_mode = Node.PROCESS_MODE_DISABLED

