extends Node2D

export (Array, Texture) var textures

signal pieceMoved

var pieceType = GlobalVars.PAWN
var pieceColor = GlobalVars.WHITE
var clicked = false
var protected = false
var occupiedSquare = "e2"
var targetSquare = ""

func _process(_delta):
	handleMovement()

func on_click():
	clicked = true

func on_click_released():
	clicked = false

func handleMovement():
	if(clicked):
		position=get_viewport().get_mouse_position()
		position.x -= get_viewport_rect().size.x/2
		position.y -= get_viewport_rect().size.y/2
		position.x += GlobalVars.g_spriteWidth/2
		position.y += GlobalVars.g_spriteWidth/2
		z_index = 1;
		targetSquare = GlobalVars.getNearestSquare(get_viewport().get_mouse_position())
	elif targetSquare!="": 
		if calculateLegalMoves().find(targetSquare)!=-1:
			occupiedSquare=targetSquare
			emit_signal("pieceMoved")
		targetSquare = ""
		position = GlobalVars.parseCoordinate(occupiedSquare)
		z_index = 0;

func updateSprite():
	var c
	if pieceColor == GlobalVars.BLACK : c=GlobalVars.g_blackColor;
	else: c=GlobalVars.g_whiteColor;
	var i = textures[pieceType].get_data();
	i.lock();
	for x in i.get_width():
		for y in i.get_height():
			if i.get_pixel(x,y).is_equal_approx(GlobalVars.g_magentaMask):
				i.set_pixel(x,y,c)
	var texture = ImageTexture.new()
	texture.create_from_image(i,1)
	$Sprite.texture = texture

func calculateLegalMoves():
	var moves = []
	var file = GlobalVars.files.find(occupiedSquare[0])
	var rank = GlobalVars.ranks.find(int(occupiedSquare[1]))
	var current=""
	var occupant=null
	var pattern = [[0,0]]
	var extendedMovement = false
	match[pieceType]:
		[GlobalVars.KING]:
			pattern += [[1,1],[1,-1],[-1,1],[-1,-1]]
			pattern += [[0,1],[0,-1],[-1,0],[1,0]]
		[GlobalVars.QUEEN]:
			pattern += [[1,1],[1,-1],[-1,1],[-1,-1]]
			pattern += [[0,1],[0,-1],[-1,0],[1,0]]
			extendedMovement = true
		[GlobalVars.BISHOP]:
			pattern += [[1,1],[1,-1],[-1,1],[-1,-1]]
			extendedMovement = true
		[GlobalVars.KNIGHT]:
			pattern += [[2,1],[2,-1],[1,2],[1,-2],[-1,2],[-1,-2],[-2,1],[-2,-1]]
		[GlobalVars.ROOK]:
			pattern += [[0,1],[0,-1],[-1,0],[1,0]]
			extendedMovement = true
		[GlobalVars.PAWN]:
			if getColor() == GlobalVars.WHITE:
				pattern += [[0,1]]
				if occupiedSquare[1]=="2": pattern += [[0,2]]
				#ATTACK DIAGONALLY
				current = GlobalVars.convertIndex(file-1,rank+1)
				occupant = GlobalVars.isSquareOccupied(current)
				if current != "" and occupant != null and occupant.getColor() != getColor(): moves.push_back(current)
				current = GlobalVars.convertIndex(file+1,rank+1)
				occupant = GlobalVars.isSquareOccupied(current)
				if current != "" and occupant != null and occupant.getColor() != getColor(): moves.push_back(current)
			else:
				pattern += [[0,-1]]
				if occupiedSquare[1]=="7": pattern += [[0,-2]]
				#ATTACK DIAGONALLY
				current = GlobalVars.convertIndex(file-1,rank-1)
				occupant = GlobalVars.isSquareOccupied(current)
				if current != "" and occupant != null and occupant.getColor() != getColor(): moves.push_back(current)
				current = GlobalVars.convertIndex(file+1,rank-1)
				occupant = GlobalVars.isSquareOccupied(current)
				if current != "" and occupant != null and occupant.getColor() != getColor(): moves.push_back(current)
	if !extendedMovement:
		for pat in pattern:
			current = GlobalVars.convertIndex(file+pat[0],rank+pat[1])
			occupant = GlobalVars.isSquareOccupied(current)
			if(current!="" and occupant==null):moves.push_back(current)
			elif(occupant!=null and occupant.getColor()!=getColor()): moves.push_back(current)
	else:
		for patCurrent in pattern:
			current=occupiedSquare
			occupant=null
			var pat = [patCurrent[0],patCurrent[1]]
			while(occupant==null and current!=""):
				current = GlobalVars.convertIndex(file+pat[0],rank+pat[1])
				occupant = GlobalVars.isSquareOccupied(current)
				if(current!="" and occupant==null):moves.push_back(current)
				elif(occupant!=null and occupant.getColor()!=getColor()): moves.push_back(current)
				pat[0]+=patCurrent[0]
				pat[1]+=patCurrent[1]
	print(moves)
	return moves

func setPieceType(p):
	pieceType = p
	updateSprite()

func setColor(c):
	pieceColor = c

func getPieceType():
	return pieceType

func getColor():
	return pieceColor

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		self.on_click()
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and !event.is_pressed():
		self.on_click_released()
