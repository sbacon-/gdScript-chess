extends Node



enum Piece_Type{KING,QUEEN,BISHOP,KNIGHT,ROOK,PAWN}
enum Player_Color{WHITE,BLACK}
enum Direction{N,NW,W,SW,S,SE,E,NE}

var piece_str = "kqbnrp"

#(2.4) The eight vertical columns of squares are called ‘files’. The eight horizontal rows of squares are called ‘ranks’. A straight line of squares of the same colour, running from one edge of the board to an adjacent edge, is called a ‘diagonal’.
#(C.5) The eight files (from left to right for White and from right to left for Black) are indicated by the small letters, a, b, c, d, e, f, g and h, respectively.
#(C.6) The eight ranks (from bottom to top for White and from top to bottom for Black) are numbered 1, 2, 3, 4, 5, 6, 7, 8, respectively. Consequently, in the initial position the white pieces and pawns are placed on the first and second ranks; the black pieces and pawns on the eighth and seventh ranks.
#(C.7) As a consequence of the previous rules, each of the sixty-four squares is invariably indicated by a unique combination of a letter and a number.
var file_str = "abcdefgh"
var rank_str = "12345678"

var coord_array: Array[Array] = [
	["a8", "b8", "c8", "d8", "e8", "f8", "g8", "h8"], 
	["a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7"], 
	["a6", "b6", "c6", "d6", "e6", "f6", "g6", "h6"], 
	["a5", "b5", "c5", "d5", "e5", "f5", "g5", "h5"], 
	["a4", "b4", "c4", "d4", "e4", "f4", "g4", "h4"], 
	["a3", "b3", "c3", "d3", "e3", "f3", "g3", "h3"], 
	["a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2"], 
	["a1", "b1", "c1", "d1", "e1", "f1", "g1", "h1"]
]

var tile_scale = (1920-1080)/8.0
var tile_scalev = Vector2(tile_scale,tile_scale)
var tile_offset = Vector2(tile_scale/2,tile_scale/2)
var piece_scale = Vector2(tile_scale/16,tile_scale/16) - Vector2.ONE

var uci_move = ""
var san_move = ""
var move_change = ""
var scroll_dir = ""

var board_color: int = 0
var mute: bool = false


	
