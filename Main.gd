extends Node2D

var activePlayer = GlobalVars.WHITE

func _ready():
	setupBoard("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")

func setupBoard(fen):
	GlobalVars.parseFEN(fen);
	for piece in GlobalVars.pieces:
		add_child(piece)
		piece.connect("pieceMoved",self,"_on_Piece_Moved",[piece])
	setPlayerTurn(GlobalVars.WHITE)

func setPlayerTurn(color):
	activePlayer = color
	for piece in GlobalVars.pieces:
		if piece.getColor() == color: piece.unlock()
		else: piece.lock()

func parseMove(text):
	text = text.replace("x","") #Captures can be implied
	var coordinates = text.substr(text.length()-2)
	var pType = text.rstrip(coordinates)
	var pieceType = GlobalVars.PAWN
	var identifier = ""
	if(pType.length()>0):
		pieceType = GlobalVars.pieceSTR.find(pType[0])
		if(pieceType == -1):
			pType = "P"+pType
			pieceType = GlobalVars.PAWN
		if(pType.length()==2): identifier = pType[1]
	var candidates = []
	for p in GlobalVars.pieces:
		if(p.getPieceType()==pieceType and p.getColor()==activePlayer and (p.calculateLegalMoves(false).find(coordinates)!=-1)):
			candidates.push_back(p)
	print(candidates)
	if (identifier != ""):
		var newCandidates = []
		for c in candidates:
			print(c.occupiedSquare)
			if(c.occupiedSquare[0] == identifier or c.occupiedSquare[1] == identifier):
				newCandidates.push_back(c)
		candidates = newCandidates
	if (candidates.size()==1):
		candidates[0].targetSquare = coordinates
		$Camera2D/MoveInput.clear()

func _on_Piece_Moved(piece):
	var occupant = GlobalVars.isSquareOccupied(piece.targetSquare)
	if(occupant != null): occupant.capture()
	#CAPTURE EN PASSANT
	if(piece.getPieceType()==GlobalVars.PAWN and piece.targetSquare==GlobalVars.enPassant):
		GlobalVars.isSquareOccupied(GlobalVars.enPassantTarget).capture()
	if activePlayer == GlobalVars.WHITE : activePlayer=GlobalVars.BLACK
	else: activePlayer = GlobalVars.WHITE
	setPlayerTurn(activePlayer)


func _on_MoveInput_text_changed(new_text):
	parseMove(new_text)
