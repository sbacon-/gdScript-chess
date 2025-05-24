extends Container

@onready var board_color = $MarginContainer/VFlowContainer/HBoxContainer/BoardColor
@onready var mute_toggle = $MarginContainer/VFlowContainer/Mute

signal reset_button_pressed
signal flip_button_pressed
signal auto_flip_toggled(toggled_on: bool)
signal auto_submit_toggled(toggled_on: bool)
signal board_color_selected(index: int)

func _ready() -> void:
	board_color.select(GlobalVars.board_color)
	mute_toggle.button_pressed = GlobalVars.mute
	

func _on_reset_button_pressed() -> void:
	reset_button_pressed.emit()

func _on_flip_button_pressed() -> void:
	flip_button_pressed.emit()

func _on_auto_flip_toggled(toggled_on: bool) -> void:
	auto_flip_toggled.emit(toggled_on)

func _on_auto_submit_toggled(toggled_on: bool) -> void:
	auto_submit_toggled.emit(toggled_on)

func _on_board_color_item_selected(index: int) -> void:
	board_color_selected.emit(index)

func _on_mute_toggled(toggled_on: bool) -> void:
	GlobalVars.mute = toggled_on
