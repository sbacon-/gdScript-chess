extends Node2D

var activePlayer = GlobalVars.WHITE

func _ready():
	setupBoard("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")

func setupBoard(fen):
	GlobalVars.parseFEN(fen);
	for piece in GlobalVars.pieces:
		add_child(piece)
		piece.connect("pieceMoved",self,"_on_Piece_Moved")
	setPlayerTurn(GlobalVars.WHITE)

func setPlayerTurn(globalColor):
	activePlayer = globalColor
	for piece in GlobalVars.pieces:
		if piece.getColor() == globalColor: piece.set_process(true)
		else: piece.set_process(false)

func _on_Piece_Moved():
	if activePlayer == GlobalVars.WHITE : activePlayer=GlobalVars.BLACK
	else: activePlayer = GlobalVars.WHITE
	setPlayerTurn(activePlayer)
