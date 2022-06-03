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

func _on_Piece_Moved(piece):
	var occupant = GlobalVars.isSquareOccupied(piece.targetSquare)
	if(occupant != null): occupant.capture()
	#CAPTURE EN PASSANT
	if(piece.getPieceType()==GlobalVars.PAWN and piece.targetSquare==GlobalVars.enPassant):
		GlobalVars.isSquareOccupied(GlobalVars.enPassantTarget).capture()
	if activePlayer == GlobalVars.WHITE : activePlayer=GlobalVars.BLACK
	else: activePlayer = GlobalVars.WHITE
	setPlayerTurn(activePlayer)

