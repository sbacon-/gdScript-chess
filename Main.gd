extends Node2D

var activePlayer = GlobalVars.WHITE

func _ready():
	setupBoard("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")
	$Camera2D/MoveInput.grab_focus()

func setupBoard(fen):
	GlobalVars.parseFEN(fen);
	for piece in GlobalVars.pieces:
		add_child(piece)
		piece.connect("pieceMoved",self,"_on_Piece_Moved",[piece])
	setPlayerTurn(activePlayer)

func setPlayerTurn(color):
	for piece in GlobalVars.pieces:
		if piece.getColor() == color: piece.unlock()
		else: piece.lock()

func parseMove(text): 
	#HANDLES TYPED MOVES
	#Captures,Check, & Checkmate are implied
	var implied = ["x","+","#"]
	for i in implied:
		text = text.replace(i,"")
	var coordinates = text.substr(text.length()-2)
	#Handles Pawn promotion via =Q
	var promotionType = null
	if coordinates.substr(0,1) == "=":
		var options = ["Q","R","B","N"]
		if(options.find(coordinates.substr(1,1)) != -1):
			promotionType = GlobalVars.pieceSTR.find(coordinates.substr(1,1))
		else: return
		text = text.rstrip(coordinates)
		coordinates = text.substr(text.length()-2)
	#Determines Piece Type and Identifier
	var pType = text.rstrip(coordinates)
	var pieceType = GlobalVars.PAWN
	var identifier = ""
	if(pType.length()>0):
		pieceType = GlobalVars.pieceSTR.find(pType[0])
		if(pieceType == -1):#Default to PAWN if no pieceType is provided
			pType = "P"+pType
			pieceType = GlobalVars.PAWN
		if(pType.length()>1): identifier = pType.substr(1)
	#Create a list of pieces that can move to the given coordinate
	var candidates = []
	for p in GlobalVars.pieces:
		if p.getPieceType()==pieceType and p.getColor()==activePlayer\
		and p.calculateLegalMoves(false).find(coordinates) != -1:
				candidates.push_back(p)
	#If more than one peice can get to a coordinate look for an identifier(N'b'd2)
	if (candidates.size()>1 and identifier != ""):
		var newCandidates = []
		if(identifier.length()==1):
			#Check ranks and files
			for c in candidates:
				if(c.occupiedSquare[0]==identifier or c.occupiedSquare[1]==identifier):
					newCandidates.push_back(c)
			candidates = newCandidates
		if(identifier.length()>1):
			#Cases where more than one identifier is needed (N'g6'e5)
			#(Only useful if there are 3 or more knights/queens on the board)
			for c in candidates:
				if(c.occupiedSquare==identifier):
					newCandidates.push_back(c)
			candidates = newCandidates
	#There should only be one candidate remaining if the move is valid
	if (candidates.size()==1):
		var c = candidates[0]
		#Handle Pawn Promotion
		if c.getPieceType()==GlobalVars.PAWN and (coordinates[1]=="8" or coordinates[1]=="1"):
			if(promotionType!=null):
				c.promoteType = promotionType
				c.moveTo(coordinates)
				$Camera2D/MoveInput.clear()
			return
		c.targetSquare = coordinates
		$Camera2D/MoveInput.clear()

func _on_Piece_Moved(piece):
	#OPPONENTS TURN
	if activePlayer == GlobalVars.WHITE : activePlayer=GlobalVars.BLACK
	else: activePlayer = GlobalVars.WHITE
	setPlayerTurn(activePlayer)

func _on_MoveInput_text_changed(new_text):
	parseMove(new_text)

func _on_Button_pressed():
	GlobalVars.flipBoard()
