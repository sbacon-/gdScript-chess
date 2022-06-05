extends Node

enum {KING,QUEEN,BISHOP,KNIGHT,ROOK,PAWN}
enum {WHITE, BLACK}

export (PackedScene) var pieceScene

export (Array, PackedScene) var pieces

const pieceSTR = "KQBNRP"
var files = "abcdefgh"
var ranks = [1,2,3,4,5,6,7,8]

var g_spriteWidth = 16;
var g_boardWidth = g_spriteWidth*8;
var g_scale = 4;

var g_graveWhite = Vector2(1.1,-1) * g_boardWidth/2 * g_scale 
var g_graveBlack = Vector2(1.1, 1) * g_boardWidth/2 * g_scale

var g_whiteColor = Color(0.8,0.8,0.8,1);
var g_blackColor = Color(0.2,0.2,0.2,1);
var g_magentaMask = Color("e500ff");

var enPassant = ""
var enPassantTarget = ""

func parseCoordinate(coord):
	var v2 = Vector2.ZERO
	v2.x = files.find(coord[0])*g_spriteWidth*g_scale
	v2.y = -ranks.find(int(coord[1]))*g_spriteWidth*g_scale
	v2+=Vector2(-1,1)*g_boardWidth/2*g_scale
	v2+=Vector2(1,-1)*g_spriteWidth/2*g_scale
	return v2

func convertIndex(f,r):
	if(f<0 or f>7) or (r<0 or r>7): return ""
	return files[f]+String(ranks[r])

func getNearestSquare(mouse):
	mouse-=get_viewport().size/2
	mouse/=g_spriteWidth*g_scale
	mouse+=Vector2.ONE*g_scale
	if (mouse.x>8 or mouse.y>8) or (mouse.x<0 or mouse.y<0): return "OOB"
	return convertIndex(int(mouse.x),ranks.size()-int(mouse.y)-1)

func parseFEN(fen):
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
			type = pieceSTR.find(c.to_upper())
			pos = convertIndex(file-1,rank-1)
			createPiece(color,type,pos);
			file+=1
		rank-=1

func createPiece(color,type,pos):
	var p = pieceScene.instance()
	p.setColor(color)
	p.setPieceType(type)
	p.position = parseCoordinate(pos)
	p.occupiedSquare = pos
	pieces.push_back(p)

func isSquareOccupied(query):
	#Returns the piece at a given coordinate ("a1")
	for piece in pieces:
		if piece.occupiedSquare == query:
			return piece
	return null

func graveYard(color):
	if(color == WHITE): return g_graveWhite
	if(color == BLACK): return g_graveBlack

func clearEnPassant():
	enPassant = ""
	enPassantTarget = ""

func flipBoard():
	var newfiles = ""
	for f in files:
		newfiles = newfiles.insert(0,f)
	files=newfiles
	var newranks = []
	for r in ranks:
		newranks.push_front(r)
	ranks=newranks
	for p in pieces:
		p.position = GlobalVars.parseCoordinate(p.occupiedSquare)

func simulateMoves(piece,moves):
	var newmoves = []
	var currentSquare = piece.occupiedSquare;
	for m in moves:
		piece.occupiedSquare = m
		#List all of opponents legal moves removing the piece if it would be captured by move m
		var opponentsMoves = []
		for p in pieces:
			if (p.getColor() != piece.getColor() and p.occupiedSquare != m):
				opponentsMoves+=p.calculateLegalMoves(true)
		#Cannot castle OUT OF, THROUGH, or INTO check
		if(m == "0-0"):
			var castles=true;
			var castleCheck = ["e"+currentSquare[1],"f"+currentSquare[1],"g"+currentSquare[1]]
			for c in castleCheck:
				if opponentsMoves.find(c) != -1:
					castles=false
			if castles: newmoves.push_back(m)
			continue;
		if(m == "0-0-0"):
			var castles
			var castleCheck = ["e"+currentSquare[1],"d"+currentSquare[1],"c"+currentSquare[1]]
			for c in castleCheck:
				if opponentsMoves.find(c) != -1:
					castles=false
			if castles: newmoves.push_back(m)
			continue;
		if(!isKingInCheck(opponentsMoves,piece.getColor())):
			newmoves.push_back(m)
	piece.occupiedSquare = currentSquare;
	return newmoves

func isKingInCheck(moves, color):
	#This function will take a list of opponents moves and determine if the king is in check
	var check = false
	var kingLocation = findKing(color).occupiedSquare
	for m in moves:
		if(kingLocation == m):
			check = true
	return check

func findKing(color):
	#Returns the king of a specified color
	for p in pieces:
		if(p.getPieceType()==KING and p.getColor()==color): return p
