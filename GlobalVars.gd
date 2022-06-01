extends Node

enum {KING,QUEEN,BISHOP,KNIGHT,ROOK,PAWN}
enum {BLACK, WHITE}

export (PackedScene) var piece

export (Array, PackedScene) var createdPieces

var g_spriteWidth = 16;
var g_boardWidth = g_spriteWidth*8;
var g_scale = 4;

var g_whiteColor = Color(0.8,0.8,0.8,1);
var g_blackColor = Color(0.2,0.2,0.2,1);
var g_magentaMask = Color("e500ff");

func parseCoordinate(coord):
	var v2 = Vector2.ZERO
	match[coord[0]]:
		["a"]:v2.x=g_spriteWidth*0*g_scale
		["b"]:v2.x=g_spriteWidth*1*g_scale
		["c"]:v2.x=g_spriteWidth*2*g_scale
		["d"]:v2.x=g_spriteWidth*3*g_scale
		["e"]:v2.x=g_spriteWidth*4*g_scale
		["f"]:v2.x=g_spriteWidth*5*g_scale
		["g"]:v2.x=g_spriteWidth*6*g_scale
		["h"]:v2.x=g_spriteWidth*7*g_scale
	v2.y = -(int(coord[1])-1)*g_spriteWidth*g_scale
	v2+=Vector2(-1,1)*g_boardWidth/2*g_scale
	v2+=Vector2(1,-1)*g_spriteWidth/2*g_scale
	
	return v2



func getNearestSquare(mouse):
	mouse-=get_viewport().size/2
	var minDistance = g_spriteWidth*g_scale;
	var result = ""
	for r in range(1,9):
		for f in "abcdefgh":
			var dist = parseCoordinate(f+String(r)).distance_to(mouse)
			if dist < minDistance:
				minDistance = dist
				result = f+String(r)
	return result

func parseFEN(fen):
	var files = "abcdefgh"
	var pieces = "KQBNRP"
	var arr = fen.split('/')
	var rank=8
	for a in arr:
		var file = 1
		while file<=8:
			var c = a[file-1]
			if c.is_valid_integer():
				file+=int(c)
				continue
			var color
			var type
			var pos
			if (c == c.to_upper()):
				color=WHITE
			if (c == c.to_lower()):
				color=BLACK
			type = pieces.find(c.to_upper())
			pos = files[file-1]+String(rank)
			createPiece(color,type,pos);
			file+=1
		rank-=1

func createPiece(color,type,pos):
	var p = piece.instance()
	p.setPieceColor(color)
	p.setPieceType(type)
	p.position = GlobalVars.parseCoordinate(pos)
	p.occupiedSquare = pos
	createdPieces.push_back(p)


