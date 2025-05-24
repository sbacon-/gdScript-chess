extends Node

#(1.1) The game of chess is played between two opponents who move their pieces on a square board called a ‘chessboard’.
@onready var board = $Board
@onready var coordinates = $Board/Coordinates
@onready var move_line_edit = $Board/MoveLineEdit
@onready var move_list = $MoveList
@onready var pieces_container = $Pieces
@onready var graveyard_container = $Graveyard
@onready var capture_audio_stream = $Sounds/Capture
@onready var check_audio_stream = $Sounds/Check
@onready var checkmate_audio_stream = $Sounds/Checkmate
@onready var generic_notify_audio_stream = $Sounds/GenericNotify
@onready var move_audio_stream = $Sounds/Move

@onready var piece_scene = preload("res://scenes/piece.tscn")
@onready var promotion_window_scene = preload("res://scenes/promotion_window.tscn")

var active_player: GlobalVars.Player_Color
var castling_availability: String
var en_passant_target: String
var halfmove_clock: int
var fullmove_number: int

var legal_moves: Array[String] = []
var legal_moves_san: Array[String] = []
var attacked_squares: Array[String] = []

var result = "-"

var promotion_wait = false
var auto_flip = false
var auto_submit = true

func _ready() -> void:
	#(2.2) At the beginning of the game White has 16 light-coloured pieces (the ‘white’ pieces); Black has 16 dark-coloured pieces (the ‘black’ pieces).
	#(2.3) The initial position of the pieces on the chessboard is as follows:
	setupFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
	legal_moves = calculate_legal_moves()
	move_line_edit.grab_focus()
	_on_command_window_board_color_selected(GlobalVars.board_color)
	play_sound("notify")
	
	#var move_hints: Array[String] = ["e4","d5"]
	#board.generate_move_hints(move_hints)

func _process(_delta) -> void:
	if move_line_edit.text == "reset":
		get_tree().reload_current_scene()
	if auto_submit && legal_moves_san.find(move_line_edit.text)!=-1:
		GlobalVars.san_move = move_line_edit.text
		move_line_edit.text = ""
	if GlobalVars.move_change != "":
		setupFEN(GlobalVars.move_change)
		
		legal_moves = calculate_legal_moves()
		attacked_squares = calculate_attacked_squares()
		if attacked_squares.find(find_king(active_player).square) != -1:
			board.clear_check_hint()
			board.generate_check_hint(find_king(active_player))
			if legal_moves.size() > 0:
				if GlobalVars.scroll_dir != "down":
					play_sound("check")  
			else: 
				if GlobalVars.scroll_dir != "down":
					play_sound("checkmate")
		else:
			board.clear_check_hint()
		if GlobalVars.scroll_dir == "up":
			play_sound("move")
		GlobalVars.move_change = ""
		
	if !promotion_wait:
		handle_movement(GlobalVars.uci_move)
	if GlobalVars.uci_move == "":
		#pieces should be displayed on their squares
		for piece in pieces_container.get_children():
			piece.position = get_coordinate_position(piece.square)
		#graveyard only used for calculation and can be cleared
		for piece in graveyard_container.get_children():
			piece.queue_free()
	if Input.is_action_just_pressed("mouse_wheel_up") && board.hover_square!="":
		GlobalVars.scroll_dir = "up"
		#Go forward a move
		move_list.scroll_move(GlobalVars.scroll_dir,get_fen())
	if Input.is_action_just_pressed("mouse_wheel_down") && board.hover_square!="":
		#Go back a move
		GlobalVars.scroll_dir = "down"
		if fullmove_number == 1 and active_player==GlobalVars.Player_Color.BLACK:
			setupFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
			legal_moves = calculate_legal_moves()
		else: 
			move_list.scroll_move(GlobalVars.scroll_dir,get_fen())
	move_list.display_result(result)

func setupFEN(fen: String) -> void:
	#Clear the board
	for piece in pieces_container.get_children():
		piece.free()
	var fen_array = fen.split(' ')
	#FEN piece placement
	var piece_array = fen_array[0].split('/')
	var current_rank_index = 0
	var current_file_index = 0
	for rank in piece_array:
		current_file_index=0
		for file in rank:
			if file.is_valid_int():
				current_file_index+= int(file)
			else:
				instance_piece(
					GlobalVars.Player_Color.WHITE if file.casecmp_to(file.capitalize())==0 else GlobalVars.Player_Color.BLACK,
					GlobalVars.piece_str.find(file.to_lower()),
					GlobalVars.file_str[current_file_index]+GlobalVars.rank_str.reverse()[current_rank_index]
				)
				current_file_index+=1
		current_rank_index+=1
	#(1.2) The player with the light-coloured pieces (White) makes the first move, then the players move alternately, with the player with the dark-coloured pieces (Black) making the next move.
	if fen_array[1] == "w": 
		active_player = GlobalVars.Player_Color.WHITE
	if fen_array[1] == "b": 
		active_player = GlobalVars.Player_Color.BLACK
	
	castling_availability = fen_array[2] #FEN Castlin White - KQ | Black - kq
	en_passant_target = fen_array[3] #FEN square pawned passed over
	halfmove_clock = int(fen_array[4]) #FEN used for 50 move rule
	fullmove_number = int(fen_array[5]) #FEN move incremented after Black's move
	result = "-"
	board.calculate_material(fen)

func instance_piece(color,type,square) -> void:
	var piece = piece_scene.instantiate()
	pieces_container.add_child(piece)
	piece.position = get_coordinate_position(square)
	piece.set_piece_type(type)
	piece.set_piece_color(color)
	piece.square = square
	piece.name = GlobalVars.Player_Color.keys()[color] + GlobalVars.Piece_Type.keys()[type]

func get_coordinate_position(coord_str: String) -> Vector2:
	var tile = coordinates.get_node(coord_str)
	return tile.global_position + GlobalVars.tile_offset

func is_square_occupied(coord_str: String) -> Node:
	for piece in pieces_container.get_children():
		if piece.square == coord_str:
			return piece
	return null

func calculate_valid_moves() -> Array[String]:
	var valid_moves: Array[String] = []
	var coord_array = GlobalVars.coord_array
	var group_tags = ["WhitePieces","BlackPieces"]
	var active_pieces: Array[Node] = get_tree().get_nodes_in_group(group_tags[active_player])
	for piece in active_pieces:
		if piece.square == "-":
			continue
		var moves: Array[String] = []
		var current_file = GlobalVars.file_str.find(piece.square[0]) 
		var current_rank = GlobalVars.rank_str.reverse().find(piece.square[1])
		match piece.type:
			GlobalVars.Piece_Type.KING:
				#(3.8) There are two different ways of moving the king:
				#(3.8.1) by moving to an adjoining square
				for x in range(-1,2):
					for y in range(-1,2):
						if x == 0 && y == 0:
							continue
						var target_rank = current_rank + x
						var target_file = current_file + y
						if !(target_file < 0 || target_file > 7 || target_rank < 0 || target_rank > 7):
							moves.push_back(coord_array[target_rank][target_file])
				#(3.8.2) by ‘castling’. This is a move of the king and either rook of the same colour along the player’s first rank, counting as a single move of the king and executed as follows: the king is transferred from its original square two squares towards the rook on its original square, then that rook is transferred to the square the king has just crossed.
				#(3.8.2.2) Castling is prevented temporarily:
				#3) If the square on which the king stands, or the square which it must cross, or the square which it is to occupy, is attacked by one or more of the opponent's pieces, or
				#4) If there is any piece between the king and the rook with which castling is to be effected.
				if castling_availability!= "-" && attacked_squares.find(coord_array[current_rank][current_file]) == -1:
					if piece.color == GlobalVars.Player_Color.WHITE && coord_array[current_rank][current_file] == "e1":
						var c_file = coord_array[current_rank][current_file-2]
						var d_file = coord_array[current_rank][current_file-1]
						var f_file = coord_array[current_rank][current_file+1]
						var g_file = coord_array[current_rank][current_file+2]
						if castling_availability.find("K") != -1:
							if attacked_squares.find(f_file) == -1 && attacked_squares.find(g_file) == -1:
								if is_square_occupied(f_file) == null && is_square_occupied(g_file) == null:
									moves.push_back("g1")
						if  castling_availability.find("Q") != -1:
							if attacked_squares.find(d_file) == -1 && attacked_squares.find(c_file) == -1:
								if is_square_occupied(d_file) == null && is_square_occupied(c_file) == null:
									moves.push_back("c1")
					if piece.color == GlobalVars.Player_Color.BLACK && coord_array[current_rank][current_file] == "e8":
						var c_file = coord_array[current_rank][current_file-2]
						var d_file = coord_array[current_rank][current_file-1]
						var f_file = coord_array[current_rank][current_file+1]
						var g_file = coord_array[current_rank][current_file+2]
						if castling_availability.find("k") != -1:
							if attacked_squares.find(f_file) == -1 && attacked_squares.find(g_file) == -1:
								if is_square_occupied(f_file) == null && is_square_occupied(g_file) == null:
									moves.push_back("g8")
						if  castling_availability.find("q") != -1:
							if attacked_squares.find(d_file) == -1 && attacked_squares.find(c_file) == -1:
								if is_square_occupied(d_file) == null && is_square_occupied(c_file) == null:
									moves.push_back("c8")
			GlobalVars.Piece_Type.QUEEN:
				#(3.4) The queen may move to any square along the file, the rank or a diagonal on which it stands.
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.N))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.NW))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.W))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.SW))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.S))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.SE))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.E))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.NE))
			GlobalVars.Piece_Type.BISHOP:
				#(3.2) The bishop may move to any square along a diagonal on which it stands.
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.NW))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.SW))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.SE))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.NE))
			GlobalVars.Piece_Type.KNIGHT:
				#(3.6) The knight may move to one of the squares nearest to that on which it stands but not on the same rank, file or diagonal.
				for x in [2,1,-1,-2]:
					for y in [2,1,-1,-2]:
						if abs(x)==abs(y):
							continue
						var target_rank = current_rank + x
						var target_file = current_file + y
						if !(target_file < 0 || target_file > 7 || target_rank < 0 || target_rank > 7):
							moves.push_back(coord_array[target_rank][target_file])
			GlobalVars.Piece_Type.ROOK:
				#(3.3) The rook may move to any square along the file or the rank on which it stands.
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.N))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.W))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.S))
				moves.append_array(move_until_intervine(current_file,current_rank,GlobalVars.Direction.E))
			GlobalVars.Piece_Type.PAWN:
				#(3.7) The pawn:
				var target_rank = current_rank
				var target_file = current_file
				var direction = 0
				var starting_rank
				var promotion_rank
				if piece.color == GlobalVars.Player_Color.WHITE:
					direction = -1
					starting_rank = 6
					promotion_rank = 0
				if piece.color == GlobalVars.Player_Color.BLACK:
					direction = 1
					starting_rank = 1
					promotion_rank = 7
				#(3.7.1) The pawn may move forward to the square immediately in front of it on the same file, provided that this square is unoccupied, or
				if is_square_occupied(coord_array[target_rank+direction][target_file]) == null:
					if target_rank+direction == promotion_rank:
						moves.push_back(coord_array[target_rank+direction][target_file]+"q")
						moves.push_back(coord_array[target_rank+direction][target_file]+"r")
						moves.push_back(coord_array[target_rank+direction][target_file]+"b")
						moves.push_back(coord_array[target_rank+direction][target_file]+"n")
					else:
						moves.push_back(coord_array[target_rank+direction][target_file])
					#(3.7.2) on its first move the pawn may move as in 3.7.1 or alternatively it may advance two squares along the same file, provided that both squares are unoccupied, or
					if current_rank==starting_rank && is_square_occupied(coord_array[target_rank+(2*direction)][target_file]) == null:
						moves.push_back(coord_array[target_rank+(2*direction)][target_file])
				#(3.7.3) the pawn may move to a square occupied by an opponent’s piece diagonally in front of it on an adjacent file, capturing that piece.
				if current_file>0 && (is_square_occupied(coord_array[target_rank+direction][target_file-1]) != null || coord_array[target_rank+direction][target_file-1]==en_passant_target):
					if target_rank+direction == promotion_rank:
						moves.push_back(coord_array[target_rank+direction][target_file-1]+"q")
						moves.push_back(coord_array[target_rank+direction][target_file-1]+"r")
						moves.push_back(coord_array[target_rank+direction][target_file-1]+"b")
						moves.push_back(coord_array[target_rank+direction][target_file-1]+"n")
					else:
						moves.push_back(coord_array[target_rank+direction][target_file-1])
				if current_file<7 && (is_square_occupied(coord_array[target_rank+direction][target_file+1]) != null || coord_array[target_rank+direction][target_file+1]==en_passant_target):
					if target_rank+direction == promotion_rank:
						moves.push_back(coord_array[target_rank+direction][target_file+1]+"q")
						moves.push_back(coord_array[target_rank+direction][target_file+1]+"r")
						moves.push_back(coord_array[target_rank+direction][target_file+1]+"b")
						moves.push_back(coord_array[target_rank+direction][target_file+1]+"n")
					else:
						moves.push_back(coord_array[target_rank+direction][target_file+1])
				#(3.7.3.3) When a player, having the move, plays a pawn to the rank furthest from its starting position, he/she must exchange that pawn as part of the same move for a new queen, rook, bishop or knight of the same colour on the intended square of arrival. This is called the square of ‘promotion’.
				#(3.7.3.4) The player's choice is not restricted to pieces that have been captured previously.
				
		for move in moves:
			var occupant = is_square_occupied(move)
			if occupant!= null && occupant.color == piece.color: #(3.1) It is not permitted to move a piece to a square occupied by a piece of the same colour.
				move = ""
			else:
				valid_moves.push_back(piece.square + move)
	return valid_moves

func move_until_intervine(current_file, current_rank, direction: GlobalVars.Direction,) -> Array[String]:
	#(3.5) When making these moves, the bishop, rook or queen may not move over any intervening pieces.
	var coord_array = GlobalVars.coord_array
	var moves: Array[String]
	for distance in range(1, 8):
		var target_file = current_file
		var target_rank = current_rank
		match direction:
			GlobalVars.Direction.N:
				target_rank += distance
			GlobalVars.Direction.NW:
				target_rank += distance
				target_file -= distance
			GlobalVars.Direction.W:
				target_file -= distance
			GlobalVars.Direction.SW:
				target_rank -= distance
				target_file -= distance
			GlobalVars.Direction.S:
				target_rank -= distance
			GlobalVars.Direction.SE:
				target_rank -= distance
				target_file += distance
			GlobalVars.Direction.E:
				target_file += distance
			GlobalVars.Direction.NE:
				target_rank += distance
				target_file += distance
		if (target_file < 0 || target_file > 7 || target_rank < 0 || target_rank > 7):
			break;
		moves.push_back(coord_array[target_rank][target_file])
		if (is_square_occupied(coord_array[target_rank][target_file])):
			break;
	return moves

func calculate_legal_moves() -> Array[String]:
	var candidate_moves = calculate_valid_moves()
	
	#(3.10) Legal and illegal moves; illegal positions:
	#(3.10.1) A move is legal when all the relevant requirements of Articles 3.1 – 3.9 have been fulfilled.
	#(3.10.2) A move is illegal when it fails to meet the relevant requirements of Articles 3.1 – 3.9.
	#(3.10.3) A position is illegal when it cannot have been reached by any series of legal moves.
	var illegal_moves: Array[String] = []
	for move in candidate_moves:
		var move_from_target = is_square_occupied(move.substr(0,2))
		var un_move = move_from_target.square
		var move_to_target = is_square_occupied(move.substr(2,2))
		var un_move_capture
		if move_to_target != null:
			un_move_capture = move_to_target.square
			move_to_target.square = "-" #CAPTURES
			move_to_target.reparent(graveyard_container)
		move_from_target.square = move.substr(2,2)
		#(3.9) The king in check:
		#(3.9.1) The king is said to be 'in check' if it is attacked by one or more of the opponent's pieces, even if such pieces are constrained from moving to the square occupied by the king because they would then leave or place their own king in check.
		var simulated_attacked_squares = calculate_attacked_squares()
		var in_check = simulated_attacked_squares.find((find_king(active_player).square)) != -1
		if in_check:
			#(3.9.2) No piece can be moved that will either expose the king of the same colour to check or leave that king in check.
			illegal_moves.push_back(move)
		move_from_target.square = un_move
		if move_to_target != null:
			move_to_target.square = un_move_capture
			move_to_target.reparent(pieces_container)
	for move in illegal_moves:
		candidate_moves.remove_at(candidate_moves.find(move))
	#(1.4) The objective of each player is to place the opponent’s king ‘under attack’ in such a way that the opponent has no legal move.
	#(1.4.1) The player who achieves this goal is said to have ‘checkmated’ the opponent’s king and to have won the game. Leaving one’s own king under attack, exposing one’s own king to attack and also ’capturing’ the opponent’s king is not allowed.
	#(1.4.2) The opponent whose king has been checkmated has lost the game.
	if candidate_moves.size() == 0:
		if calculate_attacked_squares().find(find_king(active_player).square) != -1:
			#CHECKMATE
			result = str(active_player)+"-"+str(get_opponent())
			play_sound("notify")
		else:
			#STALEMATE
			result = "1/2-1/2"
			play_sound("notify")
	legal_moves_san = convert_uci_to_san(candidate_moves)
	return candidate_moves

func convert_uci_to_san(uci_moves) -> Array[String]:
	var san_moves: Array[String] = []
	var board_array = get_board_array()
	for move_uci in uci_moves:
		#(C.1) In this description, ‘piece’ means a piece other than a pawn.
		#(C.2) Each piece is indicated by an abbreviation. In the English language it is the first letter, a capital letter, of its name. Example: K=king, Q=queen, R=rook, B=bishop, N=knight. (N is used for a knight, in order to avoid ambiguity.)
		var uci_from_square = move_uci.substr(0,2)
		var abbreviation = board_array[GlobalVars.rank_str.reverse().find(uci_from_square[1])][GlobalVars.file_str.find(uci_from_square[0])].to_upper()
		#(C.3) For the abbreviation of the name of the pieces, each player is free to use the name which is commonly used in his/her country. Examples: F = fou (French for bishop), L = loper (Dutch for bishop). In printed periodicals, the use of figurines is recommended.
		#(C.4) Pawns are not indicated by their first letter, but are recognised by the absence of such a letter. Examples: the moves are written e5, d4, a5, not pe5, Pd4, pa5.
		var move_san = "" if abbreviation == "P" else abbreviation
		#(C.8) Each move of a piece is indicated by the abbreviation of the name of the piece in question and the square of arrival. There is no need for a hyphen between name and square. Examples: Be5, Nf3, Rd1.
		# In the case of pawns, only the square of arrival is indicated. Examples: e5, d4, a5.
		# A longer form containing the square of departure is acceptable. Examples: Bb2e5, Ng1f3, Ra1d1, e7e5, d2d4, a6a5. [move_san += move_uci]
		var uci_to_square = move_uci.substr(2,2)
		#(C.9) When a piece makes a capture, an x may be inserted between:
		#(C.9.1) the abbreviation of the name of the piece in question and
		#(C.9.2) the square of arrival. Examples: Bxe5, Nxf3, Rxd1, see also C.10.
		#(C.9.3)    When a pawn makes a capture, the file of departure must be indicated, then an x may be inserted, then the square of arrival. Examples: dxe5, gxf3, axb5. In the case of an ‘en passant’ capture, ‘e.p.’ may be appended to the notation. Example: exd6 e.p.
		var arrival = board_array[GlobalVars.rank_str.reverse().find(uci_to_square[1])][GlobalVars.file_str.find(uci_to_square[0])]
		if abbreviation != "P" && arrival != "":
			#(C.13.3) x = captures
			move_san += "x" + uci_to_square
		elif abbreviation == "P" && (arrival != "" || uci_to_square == en_passant_target):
			move_san += uci_from_square[0]+"x"+uci_to_square
			if uci_to_square == en_passant_target:
				#(C.13.6) e.p. = captures ‘en passant’
				move_san += " e.p."
		else:
			move_san += uci_to_square
		#(C.11)  In the case of the promotion of a pawn, the actual pawn move is indicated, followed immediately by the abbreviation of the new piece. Examples: d8Q, exf8N, b1B, g1R.
		if move_uci.ends_with("q") || move_uci.ends_with("r") ||  move_uci.ends_with("b") || move_uci.ends_with("n"):
			move_san += move_uci.right(1).to_upper()
		#(C.13) Abbreviations
		#(C.13.1) 0-0 = castling with rook h1 or rook h8 (kingside castling)
		if (move_san == "Kg8" && move_uci == "e8g8") || move_san =="Kg1" && move_uci == "e1g1":
			move_san = "0-0"
		#(C.13.2) 0-0-0 = castling with rook a1 or rook a8 (queenside castling)
		if (move_san == "Kc8" && move_uci == "e8c8") || move_san =="Kc1" && move_uci == "e1c1":
			move_san = "0-0-0"
		san_moves.push_back(move_san)
	
	for index in range(0,san_moves.size()):
		#(C.10) If two identical pieces can move to the same square, the piece that is moved is indicated as follows:
		for check_index in range(index+1, san_moves.size()):
			#TODO WHEN 3 or more identical pieces can move to the same square something like THIS MAY BE NECESSARY 
			#var original_value_index = san_moves[index]
			#var original_value_check_index = san_moves[check_index]
			#var duplicate indicies: Array[int] = [index, check_index, ...]
			if(san_moves[index] == san_moves[check_index]):
				#(C.10.1) If both pieces are on the same rank by:
				if uci_moves[index][1] == uci_moves[check_index][1]:
					#(C.10.1.1) The abbreviation of the name of the piece,
					#(C.10.1.2) The file of departure, and
					san_moves[index] = san_moves[index].insert(1,uci_moves[index][0])
					san_moves[check_index] = san_moves[check_index].insert(1,uci_moves[check_index][0])
					#(C.10.1.2) The square of arrival.
				#(C.10.2) If both pieces are on the same file by:
				elif uci_moves[index][0] == uci_moves[check_index][0]:
					#(C.10.2.1) The abbreviation of the name of the piece,
					#(C.10.2.2) The rank of the square of departure, and
					san_moves[index] = san_moves[index].insert(1,uci_moves[index][1])
					san_moves[check_index] = san_moves[check_index].insert(1,uci_moves[check_index][1])
					#(C.10.2.3) The square of arrival.
				#(C.10.3) If the pieces are on different ranks and files, method 1 is preferred. Examples:
				else:
					san_moves[index] = san_moves[index].insert(1,uci_moves[index][0])
					san_moves[check_index] = san_moves[check_index].insert(1,uci_moves[check_index][0])
					#(C.10.3.1) There are two knights, on the squares g1 and e1, and one of them moves to the square f3: either Ngf3 or Nef3, as the case may be.
					#(C.10.3.2) There are two knights, on the squares g5 and g1, and one of them moves to the square f3: either N5f3 or N1f3, as the case may be.
					#(C.10.3.3) There are two knights, on the squares h2 and d4, and one of them moves to the square f3: either Nhf3 or Ndf3, as the case may be.
					#(C.10.3.4) If a capture takes place on the square f3, the notation of the previous examples is still applicable, but an x may be inserted: 1) either Ngxf3 or Nexf3, 2) either N5xf3 or N1xf3, 3) either Nhxf3 or Ndxf3, as the case may be.
	return san_moves

func find_king(color: GlobalVars.Player_Color) -> Node:
	for piece in pieces_container.get_children():
		if piece.color == color && piece.type == GlobalVars.Piece_Type.KING:
			return piece
	return null

func calculate_attacked_squares() -> Array[String]:
	var attacked_squares_array: Array[String] = []
	#(3.1.2)    A piece is said to attack an opponent’s piece if the piece could make a capture on that square according to Articles 3.2 to 3.8.
	#(3.1.3)    A piece is considered to attack a square even if this piece is constrained from moving to that square because it would then leave or place the king of its own colour under attack.
	active_player = get_opponent()
	var group_tags = ["WhitePieces","BlackPieces"]
	var active_pieces: Array[Node] = get_tree().get_nodes_in_group(group_tags[active_player])
	var moves = calculate_valid_moves()
	var noncaptures: Array[String] = []
	for piece in active_pieces:
		if piece.square == "-":
			continue
		if piece.type == GlobalVars.Piece_Type.PAWN:
			for move in moves:
				if move.begins_with(piece.square) && move[2] == move[0]:
					noncaptures.push_back(move)
			var current_file = GlobalVars.file_str.find(piece.square[0]) 
			var current_rank = GlobalVars.rank_str.reverse().find(piece.square[1])
			var direction = -1 if piece.color == GlobalVars.Player_Color.WHITE else 1
			if current_file>0  && attacked_squares_array.find(GlobalVars.coord_array[current_rank+direction][current_file-1]) ==-1:
				attacked_squares_array.push_back(GlobalVars.coord_array[current_rank+direction][current_file-1])
			if current_file<7  && attacked_squares_array.find(GlobalVars.coord_array[current_rank+direction][current_file+1]) ==-1:
				attacked_squares_array.push_back(GlobalVars.coord_array[current_rank+direction][current_file+1])
		if piece.type == GlobalVars.Piece_Type.KING:
			for move in moves:
				if move.begins_with(piece.square):
					if move.begins_with("e") && (move[2] == "g"|| move[2]=="c"):
						noncaptures.push_back(move)
	for move in noncaptures:
		moves.remove_at(moves.find(move))
	active_player = get_opponent()
	
	for move in moves:
		if attacked_squares_array.find(move.substr(2,2)) ==-1:
			attacked_squares_array.push_back(move.substr(2,2))
	
	return attacked_squares_array

func get_fen() -> String:
	var fen_str = ""
	var board_array = get_board_array()
	for rank in board_array:
		var blank_counter = 0
		for file in rank:
			if file.is_empty():
				blank_counter+=1
			else:
				if blank_counter!=0:
					fen_str+=str(blank_counter)
					blank_counter=0
				fen_str+=file
		if blank_counter!=0:
			fen_str+=str(blank_counter)
			blank_counter=0
		fen_str+="/"
	fen_str = fen_str.rstrip('/')
	fen_str += " " + GlobalVars.Player_Color.keys()[active_player][0].to_lower()
	fen_str += " " + castling_availability + " " + en_passant_target  
	fen_str += " " + str(halfmove_clock) + " " + str(fullmove_number)
	return fen_str

func get_opponent() -> GlobalVars.Player_Color:
	return GlobalVars.Player_Color.WHITE if active_player==GlobalVars.Player_Color.BLACK else GlobalVars.Player_Color.BLACK

func get_board_array() -> Array[Array]:
	var board_array: Array[Array]
	for rank in GlobalVars.rank_str.reverse():
		board_array.push_back([])
		for file in GlobalVars.file_str:
			board_array[GlobalVars.rank_str.reverse().find(rank)].push_back("")
	var pieces = pieces_container.get_children()
	for piece in pieces:
		var current_file = GlobalVars.file_str.find(piece.square[0]) 
		var current_rank = GlobalVars.rank_str.reverse().find(piece.square[1])
		var current_type = GlobalVars.piece_str[piece.type].to_upper() if piece.color == GlobalVars.Player_Color.WHITE else GlobalVars.piece_str[piece.type] 
		board_array[current_rank][current_file] = current_type
	return board_array

func flip_board() -> void:
		board.flip_board()
		for piece in pieces_container.get_children():
			piece.position = get_coordinate_position(piece.square)

func handle_movement(uci_move: String) -> void:
	if legal_moves_san.find(GlobalVars.san_move) != -1:
		uci_move = legal_moves[legal_moves_san.find(GlobalVars.san_move)]
		GlobalVars.san_move = ""
	var move_from_target = is_square_occupied(uci_move.substr(0,2))
	var move_to_target = is_square_occupied(uci_move.substr(2,2))
	if uci_move.length()==2:
		if move_from_target!= null && move_from_target.color == active_player:
			move_from_target.position=get_viewport().get_mouse_position()
			var moves: Array[String] = []
			var captures: Array[String] = []
			for move in legal_moves:
				if move.begins_with(uci_move) && !move.ends_with("n") && !move.ends_with("r") && !move.ends_with("b"):
					if is_square_occupied(move.substr(2,2)) != null:
						captures.push_back(move.substr(2,2))
					moves.push_back(move.substr(2,2))
			board.clear_move_hints()
			board.generate_move_hints(move_from_target,moves,captures)
		else:
			GlobalVars.uci_move =""
	if uci_move.length()>=4:
		board.clear_move_hints()
		if legal_moves.find(uci_move) != -1 || legal_moves.find(uci_move+"q") != -1:
			if move_from_target.type == GlobalVars.Piece_Type.PAWN:
				#(3.7.3.1) A pawn occupying a square on the same rank as and on an adjacent file to an opponent’s pawn which has just advanced two squares in one move from its original square may capture this opponent’s pawn as though the latter had been moved only one square.
				if uci_move.substr(2,2)==en_passant_target:
					#(3.7.3.2) This capture is only legal on the move following this advance and is called an ‘en passant’ capture.
					var capture_target = uci_move[2]+"5" if move_from_target.color == GlobalVars.Player_Color.WHITE else uci_move[2]+"4"
					var captured_piece = is_square_occupied(capture_target)
					captured_piece.square = "-" #CAPTURES (en passant)
					captured_piece.reparent(graveyard_container)
					play_sound("capture")
					en_passant_target = "-"
				elif move_from_target.color == GlobalVars.Player_Color.WHITE && (uci_move[1] == "2" && uci_move[3] =="4"):
					en_passant_target = uci_move[0]+"3"
				elif move_from_target.color == GlobalVars.Player_Color.BLACK && (uci_move[1] == "7" && uci_move[3] =="5"):
					en_passant_target = uci_move[0]+"6"
				else:
					en_passant_target = "-"
				
				#(3.7.3.5) This exchange of a pawn for another piece is called promotion, and the effect of the new piece is immediate.
				if legal_moves.find(uci_move+"q") != -1:
					promotion_wait = true
					var promotion_window_instance = promotion_window_scene.instantiate()
					add_child(promotion_window_instance)
					move_from_target.position = get_coordinate_position(uci_move[2]+"8" if move_from_target.color == GlobalVars.Player_Color.WHITE else uci_move[2]+"1")
					promotion_window_instance.position = move_from_target.position
					promotion_window_instance.initialize_values(move_from_target.color, board.board_flipped)
					var selected_promotion = -1
					while selected_promotion == -1:
						if move_to_target != null:
							move_to_target.square = "-" #CAPTURES (with promotion)
							move_to_target.reparent(graveyard_container)
							play_sound("capture")
							halfmove_clock = 0 #reset after capture
						var promotions = [GlobalVars.Piece_Type.QUEEN, GlobalVars.Piece_Type.KNIGHT, GlobalVars.Piece_Type.ROOK, GlobalVars.Piece_Type.BISHOP]
						var promotion_select_coordinates = [
							uci_move[2]+"8",uci_move[2]+"7",uci_move[2]+"6",uci_move[2]+"5"] if move_from_target.color == GlobalVars.Player_Color.WHITE else [
								uci_move[2]+"1",uci_move[2]+"2",uci_move[2]+"3",uci_move[2]+"4"]
						var promotion_select_notation = ["q","n","r","b"]
						
						var selected_square = await board.clicked_square
						if promotion_select_coordinates.find(selected_square) != -1:
							selected_promotion = promotions[promotion_select_coordinates.find(selected_square)]
							move_from_target.set_piece_type(selected_promotion)
							move_from_target.set_piece_color(move_from_target.color)
							promotion_window_instance.queue_free()
							promotion_wait = false
							uci_move = uci_move.substr(0,4) + promotion_select_notation[promotion_select_coordinates.find(selected_square)]
				halfmove_clock = 0 #reset after pawn-move
			else:
				en_passant_target = "-"
			if castling_availability!= "-":
				#(3.8.2.1) The right to castle has been lost:
				#1) If the king has already moved, or
				if move_from_target.type == GlobalVars.Piece_Type.KING:
					if move_from_target.color == GlobalVars.Player_Color.WHITE:
						if uci_move == "e1g1":
							var castling_rook = is_square_occupied("h1")
							castling_rook.square = "f1"
							castling_rook.name = "f1"
							castling_rook.position = get_coordinate_position(castling_rook.square)
						if uci_move == "e1c1":
							var castling_rook = is_square_occupied("a1")
							castling_rook.square = "d1"
							castling_rook.name = "d1"
							castling_rook.position = get_coordinate_position(castling_rook.square)
						if castling_availability.find("K") != -1:
							castling_availability=castling_availability.replace("K","")
						if castling_availability.find("Q") != -1:
							castling_availability=castling_availability.replace("Q","")
					if move_from_target.color == GlobalVars.Player_Color.BLACK:
						if uci_move == "e8g8":
							var castling_rook = is_square_occupied("h8")
							castling_rook.square = "f8"
							castling_rook.name = "f8"
							castling_rook.position = get_coordinate_position(castling_rook.square)
						if uci_move == "e8c8":
							var castling_rook = is_square_occupied("a8")
							castling_rook.square = "d8"
							castling_rook.name = "d8"
							castling_rook.position = get_coordinate_position(castling_rook.square)
						if castling_availability.find("k") != -1:
							castling_availability=castling_availability.replace("k","")
						if castling_availability.find("q") != -1:
							castling_availability=castling_availability.replace("q","")
				#2) With a rook that has already moved.
				if move_from_target.type == GlobalVars.Piece_Type.ROOK:
					if move_from_target.color == GlobalVars.Player_Color.WHITE:
						if castling_availability.find("K") != -1 && uci_move[0]=="h" :
							castling_availability=castling_availability.replace("K","")
						if castling_availability.find("Q") != -1 && uci_move[0]=="a":
							castling_availability=castling_availability.replace("Q","")
					if move_from_target.color == GlobalVars.Player_Color.BLACK:
						if castling_availability.find("k") != -1 && uci_move[0]=="h":
							castling_availability=castling_availability.replace("k","")
						if castling_availability.find("q") != -1 && uci_move[0]=="a":
							castling_availability=castling_availability.replace("q","")
				if castling_availability.is_empty():
					castling_availability = "-"
			if move_to_target != null:
				#(3.1.1) If a piece moves to a square occupied by an opponent’s piece the latter is captured and removed from the chessboard as part of the same move.
				move_to_target.square = "-" #CAPTURES
				move_to_target.reparent(graveyard_container)
				halfmove_clock = 0 #reset after capture
				play_sound("capture")
			move_from_target.square = uci_move.substr(2,2)
			move_from_target.name = uci_move.substr(2,2)
			play_sound("move")
			if active_player == GlobalVars.Player_Color.BLACK:
				fullmove_number+= 1
			halfmove_clock += 1
			#(1.3) A player is said to ‘have the move’ when his/her opponent’s move has been ‘made’.
			active_player = get_opponent()
			attacked_squares = calculate_attacked_squares()
			move_list.add_move(legal_moves_san[legal_moves.find(uci_move)],get_fen())
			board.calculate_material(get_fen())
			legal_moves.clear()
			legal_moves = calculate_legal_moves()
			if attacked_squares.find(find_king(active_player).square) != -1:
				#TODO (C.12)  The offer of a draw shall be marked as (=).
				#(C.13.4)    +     = check
				#(C.13.5) ++ or # = checkmate
				#(Articles C.13.3 – C.13.6 are optional.)
				move_list.append_abbreviation("+" if legal_moves.size() > 0 else "#")
				if legal_moves.size() > 0:
					play_sound("check")  
				else: 
					play_sound("checkmate")
				board.clear_check_hint()
				board.generate_check_hint(find_king(active_player))
			else:
				board.clear_check_hint()
		
			if auto_flip:
				flip_board()
		if move_from_target != null:
			move_from_target.position = get_coordinate_position(move_from_target.square)
		GlobalVars.uci_move = ""

func play_sound(sound: String) ->void:
	if GlobalVars.mute:
		return
	match sound:
		"capture":
			capture_audio_stream.play()
		"check":
			check_audio_stream.play()
		"checkmate":
			checkmate_audio_stream.play()
		"notify":
			generic_notify_audio_stream.play()
		"move":
			if !capture_audio_stream.playing:
				move_audio_stream.play()

func _on_command_window_auto_flip_toggled(toggled_on: bool) -> void:
	auto_flip = toggled_on

func _on_command_window_auto_submit_toggled(toggled_on: bool) -> void:
	auto_submit = toggled_on

func _on_command_window_flip_button_pressed() -> void:
	flip_board()

func _on_command_window_reset_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_command_window_board_color_selected(index: int) -> void:
	var color_array: Array[Color] = [Color("#dddddd"),Color("#222222")]
	match index:
		1: #Brown
			color_array = [Color("#f0d9b5"),Color("#b58863")]
		2: #Green
			color_array = [Color("#ffffdd"),Color("#86a666")]
		3: #Blue
			color_array = [Color("#dee3e6"),Color("#8ca2ad")]
		4: #Purple
			color_array = [Color("#9f90b0"),Color("#7d4a8d")]
	board.change_color(color_array)
	GlobalVars.board_color = index

	
