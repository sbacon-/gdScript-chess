extends Node2D

export (Array, Texture) var textures

signal pieceMoved

var pieceType = GlobalVars.PAWN
var pieceColor = GlobalVars.WHITE
var clicked = false
var locked = true
var moved = false

var occupiedSquare = "e2"
var targetSquare = ""

func _process(_delta):
	handleMovement()

func handleMovement():
	if(clicked):
		position=get_viewport().get_mouse_position()
		position.x -= get_viewport_rect().size.x/2
		position.y -= get_viewport_rect().size.y/2
		position.x += GlobalVars.g_spriteWidth/2
		position.y += GlobalVars.g_spriteWidth/2
		z_index = 1;
		targetSquare = GlobalVars.getNearestSquare(get_viewport().get_mouse_position())
		#CHECK IF CASTLING
		if(pieceType == GlobalVars.KING and !moved):
			if(targetSquare == "g"+occupiedSquare[1]):
				targetSquare = "0-0"
			if(targetSquare == "c"+occupiedSquare[1]):
				targetSquare = "0-0-0"
	elif targetSquare!="":
		if calculateLegalMoves(false).find(targetSquare)!=-1:
			emit_signal("pieceMoved")
			moveTo(targetSquare)
		targetSquare = ""
		z_index = 0;
		position = GlobalVars.parseCoordinate(occupiedSquare)

func moveTo(target):
	#CASTLES
	if(target == "0-0"):
		moveTo("g"+String(occupiedSquare[1]))
		GlobalVars.isSquareOccupied("h"+String(occupiedSquare[1])).moveTo("f"+String(occupiedSquare[1]))
		return
	if(target == "0-0-0"):
		moveTo("c"+String(occupiedSquare[1]))
		GlobalVars.isSquareOccupied("a"+String(occupiedSquare[1])).moveTo("d"+String(occupiedSquare[1]))
		return
	#EN PASSANT TARGET
	GlobalVars.clearEnPassant()
	if(pieceType == GlobalVars.PAWN and !moved):
		if(target[1] == "4"):
			GlobalVars.enPassant = target[0]+"3"
			GlobalVars.enPassantTarget = target
		if(target[1] == "5"):
			GlobalVars.enPassant = target[0]+"6"
			GlobalVars.enPassantTarget = target
	moved = true
	occupiedSquare = target
	position = GlobalVars.parseCoordinate(occupiedSquare)

func capture():
	occupiedSquare = "xx"
	$Area2D.queue_free()
	position = GlobalVars.graveYard(getColor())
	scale /= 2

func calculateLegalMoves(onlyAttack):
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
			#CASTLING
			if(!moved):
				var fFile = GlobalVars.convertIndex(file+1,rank)
				var gFile = GlobalVars.convertIndex(file+2,rank)
				var hFile = GlobalVars.convertIndex(file+3,rank)
				if(GlobalVars.isSquareOccupied(fFile)==null and GlobalVars.isSquareOccupied(gFile)==null):
					var rook = GlobalVars.isSquareOccupied(hFile)
					if(rook != null and !rook.moved): moves.push_back("0-0")
				var dFile = GlobalVars.convertIndex(file-1,rank)
				var cFile = GlobalVars.convertIndex(file-2,rank)
				var bFile = GlobalVars.convertIndex(file-3,rank)
				var aFile = GlobalVars.convertIndex(file-4,rank)
				if(GlobalVars.isSquareOccupied(dFile)==null and GlobalVars.isSquareOccupied(cFile)==null and GlobalVars.isSquareOccupied(bFile)==null):
					var rook = GlobalVars.isSquareOccupied(aFile)
					if(rook != null and !rook.moved): moves.push_back("0-0-0")
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
			var diagonalAttacks
			if getColor() == GlobalVars.WHITE:
				pattern += [[0,1]]
				if (occupiedSquare[1]=="2"): pattern += [[0,2]]
				diagonalAttacks = [[-1,1],[1,1]]
			if getColor() == GlobalVars.BLACK:
				pattern += [[0,-1]]
				if (occupiedSquare[1]=="7"): pattern += [[0,-2]]
				diagonalAttacks = [[-1,-1],[1,-1]]
			for d in diagonalAttacks:
				current = GlobalVars.convertIndex(file+d[0],rank+d[1])
				occupant = GlobalVars.isSquareOccupied(current)
				if current != "" and ((occupant != null and occupant.getColor() != getColor()) or current==GlobalVars.enPassant):
					moves.push_back(current)
			for p in pattern:
				current = GlobalVars.convertIndex(file+p[0],rank+p[1])
				occupant = GlobalVars.isSquareOccupied(current)
				if current != "" and occupant == null:
					moves.push_back(current)
			if(!onlyAttack):
				moves = GlobalVars.simulateMoves(self,moves) #Determine if a move would leave the king in check
			return moves
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
	if(!onlyAttack):
		moves = GlobalVars.simulateMoves(self,moves) #Determine if a move would leave the king in check
		print(moves)
	return moves

#PIECE INITIALIZATION
func setPieceType(p):
	pieceType = p
	updateSprite()
func setColor(c):
	pieceColor = c
func getPieceType():
	return pieceType
func getColor():
	return pieceColor

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
	scale = Vector2.ONE*GlobalVars.g_scale

#DISABLES CLICKING WHEN IT IS NOT YOUR TURN
func lock():
	locked=true
func unlock():
	locked=false

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		if !locked: clicked = true;
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and !event.is_pressed():
		clicked = false;

