extends Node2D

func _ready():
	setupBoard()

func setupBoard():
	GlobalVars.parseFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR");
	for piece in GlobalVars.createdPieces:
		add_child(piece)
