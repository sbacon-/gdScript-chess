extends ScrollContainer

@onready var flow_container = $FlowContainer
@onready var move_number = $FlowContainer/MoveNumber
@onready var texture_button = $FlowContainer/TextureButton
@onready var result_readout = $FlowContainer/w1/Label

func add_move(san: String, fen: String):
	var fen_array = fen.split(' ')
	#player turn:
	var active_player = fen_array[1]
	#move number: 
	var move = fen_array[5]
	
	#CHANGING LINES
	var flow_container_children = flow_container.get_children()
	if active_player == "b" && flow_container.find_child("m"+move,false,false) != null:
			for index in range(flow_container_children.find(flow_container.find_child("m"+move,false,false)),flow_container_children.size()):
				flow_container_children[index].free()
	elif flow_container.find_child(active_player+move,false,false) != null:
		for index in range(flow_container_children.find(flow_container.find_child(active_player+move,false,false)),flow_container_children.size()):
				flow_container_children[index].free()
	
	#BUILD MOVE LIST
	if active_player == "b":
		var new_move_number = move_number.duplicate()
		flow_container.add_child(new_move_number)
		new_move_number.find_child("Label",false,false).text=move
		new_move_number.name = "m"+move
	var new_button = texture_button.duplicate()
	flow_container.add_child(new_button)
	#"♜♞♝♛♚♕♔♗♘♖" 
	"""
	var pretty_san = san.replace(
		"K","♚" if active_player == "b" else "♔").replace(
		"Q","♛" if active_player == "b" else "♕").replace(
		"R","♜" if active_player == "b" else "♖").replace(
		"B","♝" if active_player == "b" else "♗").replace(
		"N","♞" if active_player == "b" else "♘")
	new_button.find_child("Label",false, false).text = pretty_san
	"""
	new_button.find_child("Label",false, false).text = san
	new_button.name = active_player+move
	new_button.disabled = false
	new_button.pressed.connect(change_move.bind(fen))

func append_abbreviation(abbr: String):
	#Abbreviations for check and checkmate
	flow_container.get_children()[-1].find_child("Label",false,false).text += abbr

func change_move(fen: String):
	GlobalVars.move_change = fen

func scroll_move(direction: String, fen: String):
	var fen_array = fen.split(' ')
	#player turn:
	var active_player = fen_array[1]
	#move number: 
	var move = fen_array[5]
	var flow_container_children = flow_container.get_children()
	var target_move_button = flow_container_children.find(flow_container.find_child(active_player+move,false, false))
	if direction == "up":
		target_move_button += 1 if active_player == "b" else 2
		if target_move_button < flow_container_children.size():
			flow_container_children[target_move_button].pressed.emit()
	if direction == "down":
		target_move_button -= 2 if active_player == "b" else 1
		if target_move_button > 0:
			flow_container_children[target_move_button].pressed.emit()

func display_result(result: String):
	result_readout.text = result
