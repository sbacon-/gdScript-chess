extends Node2D

var activePlayer = GlobalVars.WHITE

var moveQueue = []

func _ready():
	reset()

func reset():
	setupBoard("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")
	activePlayer = GlobalVars.WHITE
	moveQueue.clear()
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
	if GlobalVars.isSquareOccupied(text.substr(0,2))!=null:
		parseUCI(text)
	else:
		parseSAN(text)

func parseUCI(text):
	var from = text.substr(0,2)
	var to = text.substr(2,2)
	var promote = text.substr(text.length()-1)
	
	var piece = GlobalVars.isSquareOccupied(from)
	if piece==null: return
	
	if piece.calculateLegalMoves(false).find(to)==-1: return
	
	if piece.getPieceType()==GlobalVars.PAWN and (to[1]=="1" or to[1]=="8"):
		var options = ["Q","R","B","N"]
		promote = promote.to_upper()
		if options.find(promote)==-1: return
		piece.promoType = GlobalVars.pieceSTR.find(promote)
		piece.moveTo(to)
	
	$Camera2D/MoveInput.clear()
	piece.targetSquare = to
	moveQueue.push_back(text)
	print(moveQueue)

func parseSAN(text):
	var implied = ["x","+","#","="]
	for i in implied:
		text = text.replace(i,"")
	var from
	var to
	var promote = text.substr(text.length()-1)
	if(int(promote)==0): to = text.substr(text.length()-3,2)
	else: 
		to = text.substr(text.length()-2,2)
		promote = ""
	var candidates = []
	var info = text.rstrip(promote)
	info = info.rstrip(to)
	if GlobalVars.pieceSTR.find(info.substr(0,1)) == -1:
		info = "P"+info
	for p in GlobalVars.pieces:
		if  p.getColor()==activePlayer and p.getPieceType()==GlobalVars.pieceSTR.find(info.substr(0,1)):
			if (p.calculateLegalMoves(false).find(to)!=-1):
				candidates.push_back(p)
	info = info.substr(1)
	if candidates.size()>1 and !info.empty():
		var newCandidates = []
		for c in candidates:
			if c.occupiedSquare[0]==info or c.occupiedSquare[1]==info or c.occupiedSquare==info:
				newCandidates.push_back(c)
		candidates=newCandidates
	if candidates.size()==1:
		from = candidates[0].occupiedSquare
		parseUCI(from+to+promote)

func _on_Piece_Moved(piece):
	#OPPONENTS TURN
	if activePlayer == GlobalVars.WHITE : activePlayer=GlobalVars.BLACK
	else: activePlayer = GlobalVars.WHITE
	setPlayerTurn(activePlayer)

func _on_MoveInput_text_changed(new_text):
	if new_text=="":return
	if new_text.to_lower()=="reset":
		reset()
		$Camera2D/MoveInput.clear()
	parseMove(new_text)

func _on_Button_pressed():
	GlobalVars.flipBoard()
