extends Control

@export var board_color: Array[Color] = [Color("#dddddd"),Color("#222222")]
@onready var coordinates = $Coordinates
@onready var hints = $Hints
@onready var coordinate_labels = $CoordinateLabels
@onready var move_line_edit = $MoveLineEdit
@onready var black_captures_container = $Material/BlackCaptures
@onready var white_captures_container = $Material/WhiteCaptures
@onready var coordinate_label_font = preload("res://assets/Tomorrow-Regular.ttf")
@onready var move_hint = preload("res://assets/hints/move.png")
@onready var capture_hint = preload("res://assets/hints/capture.png")
@export var piece_hint: Array[Resource]


var hover_square
var board_flipped: bool = false

var piece_hint_color: Array[Color] = [Color("#ffffffa1"),Color("#000000a1")]
var magenta_mask: Array[Color] = [Color("#ff00e5"),Color("#e500ff")]
var hint_color = Color("3b961da1")
var check_hint_color = Color("d91721a1")

var move_hint_image: ImageTexture
var capture_hint_image: ImageTexture
var check_hint_image: ImageTexture

signal clicked_square(coord)

func _ready() -> void:
	generate_board(GlobalVars.tile_scale)
	move_line_edit.position += Vector2(GlobalVars.tile_scale*3.5, GlobalVars.tile_scale*8.5)
	move_line_edit.size = Vector2(GlobalVars.tile_scale, GlobalVars.tile_scale/2)
	coordinates.size = GlobalVars.tile_scalev * 8
	#TILE COLORS
	var image: Image = move_hint.get_image()
	for x in range(0,16):
		for y in range(0,16):
			var mask_index = magenta_mask.find(image.get_pixel(x,y))
			if mask_index != -1:
				image.set_pixel(x,y,hint_color)
	move_hint_image = ImageTexture.create_from_image(image)
	#CAPTURE HINT COLOR
	image = capture_hint.get_image()
	for x in range(0,16):
		for y in range(0,16):
			var mask_index = magenta_mask.find(image.get_pixel(x,y))
			if mask_index != -1:
				image.set_pixel(x,y,hint_color)
	capture_hint_image = ImageTexture.create_from_image(image)
	#CHECK HINT COLOR
	image = piece_hint[GlobalVars.Piece_Type.KING].get_image()
	for x in range(0,16):
		for y in range(0,16):
			var mask_index = magenta_mask.find(image.get_pixel(x,y))
			if mask_index != -1:
				image.set_pixel(x,y,check_hint_color)
	check_hint_image = ImageTexture.create_from_image(image)
	black_captures_container.position += Vector2(GlobalVars.tile_scale*8, -16)
	white_captures_container.position += Vector2(GlobalVars.tile_scale*8, GlobalVars.tile_scale*8 + 16)

func generate_board(tile_size: int) -> void:
	#(2.1) The chessboard is composed of an 8 x 8 grid of 64 equal squares alternately light (the ‘white’ squares) and dark (the ‘black’ squares).
	# The chessboard is placed between the players in such a way that the near corner square to the right of the player is white.
	position -= Vector2(tile_size*4,tile_size*4)
	for rank in range(0,8):
		for file in range(0,8):
			var tile_position = Vector2(file*tile_size,rank*tile_size)
			var color_index =  (0 if file%2==0 else 1) if rank%2==0 else (1 if file%2==0 else 0)
			var tile = ColorRect.new()
			coordinates.add_child(tile)
			tile.name = GlobalVars.file_str[file] + GlobalVars.rank_str.reverse()[rank]
			tile.position = tile_position
			tile.size = GlobalVars.tile_scalev
			tile.color = board_color[color_index]
			tile.mouse_entered.connect(_on_color_rect_mouse_entered.bind(tile))
			tile.mouse_exited.connect(_on_color_rect_mouse_exited)
			tile.gui_input.connect(_on_color_rect_gui_input)
	for file in range(0,8):
		var label_instance = Label.new()
		coordinate_labels.add_child(label_instance)
		label_instance.add_theme_font_override("font",coordinate_label_font)
		label_instance.text = " "+GlobalVars.file_str[file]
		label_instance.position += Vector2(file*GlobalVars.tile_scale,8*GlobalVars.tile_scale - label_instance.get_line_height())
		label_instance.add_theme_color_override("font_color",board_color[file%2])
		label_instance.name = "file"+str(file)
	for rank in range(0,8):
		var label_instance = Label.new()
		coordinate_labels.add_child(label_instance)
		label_instance.add_theme_font_override("font",coordinate_label_font)
		label_instance.text = GlobalVars.rank_str.reverse()[rank]
		label_instance.position += Vector2(8*GlobalVars.tile_scale - label_instance.get_minimum_size().x * 1.2,rank*GlobalVars.tile_scale)
		label_instance.add_theme_color_override("font_color",board_color[rank%2])
		label_instance.name = "rank"+str(rank)

func flip_board() -> void:
	var tile_size = GlobalVars.tile_scale
	for rank in range(0,8):
		var current_rank_label = coordinate_labels.find_child("rank"+str(rank),false,false)
		var current_file_label = coordinate_labels.find_child("file"+str(rank),false,false)
		if board_flipped:
			current_rank_label.text = GlobalVars.rank_str.reverse()[rank]
			current_file_label.text = " "+GlobalVars.file_str[rank]
		for file in range(0,8):
			var tile_position = Vector2(file*tile_size,rank*tile_size)
			var current_tile
			if board_flipped:
				current_tile = coordinates.find_child(GlobalVars.file_str[file] + GlobalVars.rank_str.reverse()[rank], false, false)
			else:
				current_tile = coordinates.find_child(GlobalVars.file_str.reverse()[file] + GlobalVars.rank_str[rank], false, false)
			current_tile.position = tile_position
	for index in range(0,8):
		var current_rank_label = coordinate_labels.find_child("rank"+str(index),false,false)
		var current_file_label = coordinate_labels.find_child("file"+str(index),false,false)
		if board_flipped:
			current_rank_label.text = GlobalVars.rank_str.reverse()[index]
			current_file_label.text = " "+GlobalVars.file_str[index]
		else: 
			current_rank_label.text = GlobalVars.rank_str[index]
			current_file_label.text = " "+GlobalVars.file_str.reverse()[index]
	for hint in hints.get_children():
		var coordinate_position = coordinates.find_child(hint.name.substr(0,2),false,false).position
		hint.position = coordinate_position 
		if hint.name.ends_with("piece"):
			hint.position += Vector2(8,8)
	var temp_white_position = white_captures_container.position.y
	white_captures_container.position.y = black_captures_container.position.y
	black_captures_container.position.y = temp_white_position
	
	board_flipped = !board_flipped

func generate_move_hints(piece: Node, coords: Array[String], captures: Array[String]) -> void:
	for coord in coords:
		var coordinate_position = coordinates.find_child(coord,false,false).position
		var hint_instance = TextureRect.new()
		hints.add_child(hint_instance)
		hint_instance.name = coord + " move"
		hint_instance.position = coordinate_position
		hint_instance.scale = GlobalVars.tile_scalev/16
		hint_instance.texture = move_hint_image if captures.find(coord) == -1 else capture_hint_image
		hint_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image: Image = piece_hint[piece.type].get_image()
	var magenta_mask_copy = magenta_mask.duplicate()
	if piece.color!= GlobalVars.Player_Color.WHITE:
		magenta_mask_copy.reverse()
	for x in range(0,16):
		for y in range(0,16):
			var mask_index = magenta_mask_copy.find(image.get_pixel(x,y))
			if mask_index != -1:
				image.set_pixel(x,y,piece_hint_color[mask_index])
	var piece_hint_instance = TextureRect.new()
	hints.add_child(piece_hint_instance)
	piece_hint_instance.name = piece.square + " piece"
	piece_hint_instance.position = coordinates.find_child(piece.square,false,false).position + Vector2(8,8)
	piece_hint_instance.scale = GlobalVars.piece_scale
	piece_hint_instance.texture = ImageTexture.create_from_image(image)
	piece_hint_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE

func clear_move_hints() -> void:
	var hints_children = hints.get_children()
	for hint in hints_children:
		if hint.name.ends_with("check"):
			continue
		hint.free()

func generate_check_hint(king: Node) -> void:
	var hint_instance = TextureRect.new()
	hints.add_child(hint_instance)
	hint_instance.name = king.square + " check"
	hint_instance.position = coordinates.find_child(king.square,false,false).position
	hint_instance.scale = GlobalVars.tile_scalev/16
	hint_instance.texture = check_hint_image
	hint_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE

func clear_check_hint() -> void:
	var hints_children = hints.get_children()
	for hint in hints_children:
		if hint.name.ends_with("check"):
			hint.free()

func calculate_material(fen: String) -> void:
	clear_material()
	var pawn_count = 0
	var bishop_count = 0
	var knight_count = 0
	var rook_count = 0
	var queen_count = 0
	var fen_array = fen.split(' ')
	for square in fen_array[0]:
		match square:
			"P":
				pawn_count += 1
			"p":
				pawn_count -= 1
			"B":
				bishop_count += 1
			"b":
				bishop_count -= 1
			"N":
				knight_count += 1
			"n":
				knight_count -= 1
			"R":
				rook_count += 1
			"r":
				rook_count -= 1
			"Q":
				queen_count += 1
			"q":
				queen_count -= 1
	for pawn in range(pawn_count, 0, 1 if pawn_count < 0 else -1):
		var capture_instance = TextureRect.new()
		if pawn<0:
			black_captures_container.add_child(capture_instance)
		else:
			white_captures_container.add_child(capture_instance)
		capture_instance.texture = capture_image(GlobalVars.Piece_Type.PAWN,pawn)
		capture_instance.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for bishop in range(bishop_count, 0, 1 if bishop_count < 0 else -1):
		var capture_instance = TextureRect.new()
		if bishop<0:
			black_captures_container.add_child(capture_instance)
		else:
			white_captures_container.add_child(capture_instance)
		capture_instance.texture = capture_image(GlobalVars.Piece_Type.BISHOP,bishop)
		capture_instance.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for knight in range(knight_count, 0, 1 if knight_count < 0 else -1):
		var capture_instance = TextureRect.new()
		if knight<0:
			black_captures_container.add_child(capture_instance)
		else:
			white_captures_container.add_child(capture_instance)
		capture_instance.texture = capture_image(GlobalVars.Piece_Type.KNIGHT,knight)
		capture_instance.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for rook in range(rook_count, 0, 1 if rook_count < 0 else -1):
		var capture_instance = TextureRect.new()
		if rook<0:
			black_captures_container.add_child(capture_instance)
		else:
			white_captures_container.add_child(capture_instance)
		capture_instance.texture = capture_image(GlobalVars.Piece_Type.ROOK,rook)
		capture_instance.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for queen in range(queen_count, 0, 1 if queen_count < 0 else -1):
		var capture_instance = TextureRect.new()
		if queen<0:
			black_captures_container.add_child(capture_instance)
		else:
			white_captures_container.add_child(capture_instance)
		capture_instance.texture = capture_image(GlobalVars.Piece_Type.QUEEN,queen)
		capture_instance.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var score = pawn_count + (3*knight_count) + (3*bishop_count) + (5*rook_count) + (9*queen_count)
	if score>0:
		white_captures_container.find_child("Label",false,false).text = "+"+str(abs(score))
	if score<0:
		black_captures_container.find_child("Label",false,false).text = "+"+str(abs(score))

func clear_material() -> void:
	var black_captures = black_captures_container.get_children()
	var white_captures = white_captures_container.get_children()
	for mat in black_captures:
		if mat.name != "Label":
			mat.free()
		else:
			mat.text = ""
	for mat in white_captures:
		if mat.name != "Label":
			mat.free()
		else:
			mat.text = ""

func capture_image(type: GlobalVars.Piece_Type, count: int) -> ImageTexture:
	var image: Image = piece_hint[type].get_image()
	var magenta_mask_copy = magenta_mask.duplicate()
	if count>0:
		magenta_mask_copy.reverse()
	for x in range(0,16):
		for y in range(0,16):
			var mask_index = magenta_mask_copy.find(image.get_pixel(x,y))
			if mask_index != -1:
				image.set_pixel(x,y,piece_hint_color[mask_index])
	return ImageTexture.create_from_image(image)

func change_color(new_board_color: Array[Color]) -> void:
	board_color = new_board_color
	var coordinates_children = coordinates.get_children()
	for rank in range(0,8):
		for file in range(0,8):
			var color_index =  (0 if file%2==0 else 1) if rank%2==0 else (1 if file%2==0 else 0)
			coordinates_children[8*rank+file].color = board_color[color_index]
	for file in range(0,8):
		var label = coordinate_labels.get_child(file)
		label.add_theme_color_override("font_color",board_color[file%2])
	for rank in range(0,8):
		var label = coordinate_labels.get_child(8+rank)
		label.add_theme_color_override("font_color",board_color[rank%2])

func _on_color_rect_mouse_entered(tile: ColorRect) -> void:
	hover_square = tile.name
func _on_color_rect_mouse_exited() -> void:
	hover_square = ""

func _on_color_rect_gui_input(_event) -> void:
	if Input.is_action_just_pressed("left_mouse"):
		if GlobalVars.uci_move.length() == 0:
			GlobalVars.uci_move += hover_square
		clicked_square.emit(hover_square)
	if Input.is_action_just_released("left_mouse"):
		if hover_square == "":
			GlobalVars.uci_move = ""
			clear_move_hints()
		if GlobalVars.uci_move.length() == 2:
			GlobalVars.uci_move += hover_square

func _on_move_line_edit_text_submitted(new_text: String) -> void:
	GlobalVars.san_move = new_text
	move_line_edit.text = ""
