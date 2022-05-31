extends Node2D

export (PackedScene) var piece;

func _ready():
	setupBoard()

func setupBoard():
	for p in range(6):
		match[p]:
			[GlobalVars.KING]:
				instantiatePiece(GlobalVars.WHITE,GlobalVars.KING,"e1")
				instantiatePiece(GlobalVars.BLACK,GlobalVars.KING,"e8")
			[GlobalVars.QUEEN]:
				instantiatePiece(GlobalVars.WHITE,GlobalVars.QUEEN,"d1")
				instantiatePiece(GlobalVars.BLACK,GlobalVars.QUEEN,"d8")
			[GlobalVars.BISHOP]:
				instantiatePiece(GlobalVars.WHITE,GlobalVars.BISHOP,"c1")
				instantiatePiece(GlobalVars.WHITE,GlobalVars.BISHOP,"f1")
				instantiatePiece(GlobalVars.BLACK,GlobalVars.BISHOP,"c8")
				instantiatePiece(GlobalVars.BLACK,GlobalVars.BISHOP,"f8")
			[GlobalVars.KNIGHT]:
				instantiatePiece(GlobalVars.WHITE,GlobalVars.KNIGHT,"b1")
				instantiatePiece(GlobalVars.WHITE,GlobalVars.KNIGHT,"g1")
				instantiatePiece(GlobalVars.BLACK,GlobalVars.KNIGHT,"b8")
				instantiatePiece(GlobalVars.BLACK,GlobalVars.KNIGHT,"g8")
			[GlobalVars.ROOK]:
				instantiatePiece(GlobalVars.WHITE,GlobalVars.ROOK,"a1")
				instantiatePiece(GlobalVars.WHITE,GlobalVars.ROOK,"h1")
				instantiatePiece(GlobalVars.BLACK,GlobalVars.ROOK,"a8")
				instantiatePiece(GlobalVars.BLACK,GlobalVars.ROOK,"h8")
			[GlobalVars.PAWN]:
				for f in "abcdefgh":
					instantiatePiece(GlobalVars.WHITE,GlobalVars.PAWN,f+"2")
					instantiatePiece(GlobalVars.BLACK,GlobalVars.PAWN,f+"7")

func instantiatePiece(color,type,pos):
	var p = piece.instance()
	p.setPieceColor(color)
	p.setPieceType(type)
	p.position = parseCoordinate(pos)
	add_child(p)

func parseCoordinate(coord):
	var v2 = Vector2.ZERO
	match[coord[0]]:
		["a"]:v2.x=0
		["b"]:v2.x=16
		["c"]:v2.x=32
		["d"]:v2.x=48
		["e"]:v2.x=64
		["f"]:v2.x=80
		["g"]:v2.x=96
		["h"]:v2.x=112
	v2.y = (8-int(coord[1]))*16
	v2.x -= 64 - 8
	v2.y -= 64 - 8
	
	return v2
