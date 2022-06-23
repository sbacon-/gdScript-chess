extends Node2D

export (PackedScene) var moveNavigation
var moveQueueDisplay
var moveQueueSet
var moveInput

var activePlayer = GlobalVars.WHITE

var moveNumber = 0

var uciMoveQueue = []
var sanMoveQueue = []
var fenMoveQueue = []

func _ready():
	moveQueueDisplay = $Camera2D/UI/RightBG/Scroll/VBox
	moveInput = $Camera2D/UI/MoveInput
	reset()

func reset():
	setupBoard("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -")
	moveNumber=0
	uciMoveQueue.clear()
	sanMoveQueue.clear()
	fenMoveQueue.clear()
	for child in moveQueueDisplay.get_children():
		child.queue_free()
	moveInput.grab_focus()

func setupBoard(fen):
	activePlayer = GlobalVars.parseFEN(fen);
	for piece in GlobalVars.pieces:
		add_child(piece)
		piece.connect("pieceMoved",self,"_on_Piece_Moved",[piece])
		piece.connect("promoWait",self,"_on_Piece_PromoWait",[piece])
		piece.connect("promoContinue",self,"_on_Piece_PromoContinue",[piece])
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
		piece.promote()
		piece.promoType = GlobalVars.pieceSTR.find(promote)
	moveInput.clear()
	piece.targetSquare = to
	uciMoveQueue.push_back(text)
	sanMoveQueue.push_back(properSAN(from,to,promote))
	for p in GlobalVars.pieces:
		p.lock()
	if(moveNumber%2==0):
		moveQueueSet = HBoxContainer.new()
		moveQueueDisplay.add_child(moveQueueSet)
	var move = Button.new()
	move.name = String(moveNumber)
	move.connect("pressed",self,"_on_Move_Selected",[move])
	move.text = sanMoveQueue[moveNumber]
	move.rect_size.x = moveQueueDisplay.rect_size.x/2
	moveQueueSet.add_child(move)
	moveNumber+=1

func parseSAN(text):
	var original = text
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
	var info = text.rstrip(promote)
	info = info.rstrip(to)
	var type = info.substr(0,1)
	if GlobalVars.pieceSTR.find(type) == -1:
		type = "P"
	if original=="0-0" or original == "0-0-0":
		type="K"
		if(activePlayer == GlobalVars.WHITE):
			if original == "0-0": to = "g1"
			if original == "0-0-0": to = "c1"
		if(activePlayer == GlobalVars.BLACK):
			if original == "0-0": to = "g8"
			if original == "0-0-0": to = "c8"
	var candidates = getMoveCandidates(GlobalVars.pieceSTR.find(type),to)
	info = info.substr(1)
	if candidates.size()>1 and !info.empty():
		var fileCandidates=[]
		var rankCandidates=[]
		for c in candidates:
			if c.occupiedSquare[0]==info : fileCandidates.push_back(c)
			if c.occupiedSquare[1]==info : rankCandidates.push_back(c)
		if(fileCandidates.size()==1):from = fileCandidates[0].occupiedSquare
		elif(rankCandidates.size()==1):from = rankCandidates[0].occupiedSquare
		else: from = info
	elif(candidates.size()==1): from = candidates[0].occupiedSquare
	var san = properSAN(from,to,promote)
	if original == san:
		parseUCI(from+to+promote)

func properSAN(from,to,promote):
	var sanText
	var piece = GlobalVars.isSquareOccupied(from)
	if(piece==null): return
	var capture = GlobalVars.isSquareOccupied(to)
	var type = GlobalVars.pieceSTR[piece.getPieceType()]
	if(type=="P"):
		if(capture!=null): sanText=(from[0]+"x"+to)
		else: sanText=to
		var options = ["Q","R","B","N"]
		if(to[1]=="1" or to[1]=="8"):
			if(options.find(promote.to_upper())!=-1): 
				sanText+=("="+promote.to_upper())
	else:
		sanText = type+to
		if(capture!=null):
			sanText=sanText.insert(sanText.length()-2,"x")
		var candidates = getMoveCandidates(GlobalVars.pieceSTR.find(type),to)
		if(candidates.size()>1):
			var fileCandidates=[]
			var rankCandidates=[]
			for c in candidates:
				if c.occupiedSquare[0]==from[0] : fileCandidates.push_back(c)
				if c.occupiedSquare[1]==from[1] : rankCandidates.push_back(c)
			if(fileCandidates.size()==1):sanText=sanText.insert(1,from[0])
			elif(rankCandidates.size()==1):sanText=sanText.insert(1,from[1])
			else: sanText=sanText.insert(1,from)
	if(type=="K" and !piece.moved and to=="g"+from[1]): return "0-0"
	if(type=="K" and !piece.moved and to=="c"+from[1]): return "0-0-0"
	return sanText

func getMoveCandidates(type,to):
	var candidates = []
	for p in GlobalVars.pieces:
		if(p.getColor()==activePlayer and p.getPieceType()==type):
			if(p.calculateLegalMoves(false).find(to)!=-1):
				candidates.push_back(p)
	return candidates

func _on_Piece_Moved(piece):
	if(!piece.locked): parseUCI(piece.uciMovement)
	piece.moveTo(piece.targetSquare)
	#OPPONENTS TURN
	if activePlayer == GlobalVars.WHITE : activePlayer=GlobalVars.BLACK
	else: activePlayer = GlobalVars.WHITE
	setPlayerTurn(activePlayer)
	fenMoveQueue.push_back(GlobalVars.constructFen(activePlayer))

func _on_Piece_PromoWait(_piece):
	for p in GlobalVars.pieces:
		p.lock()

func _on_Piece_PromoContinue(piece):
	parseUCI(piece.uciMovement)

func _on_Move_Selected(move):
	activePlayer = GlobalVars.parseFEN(fenMoveQueue[int(move.name)])
	for piece in GlobalVars.pieces:
		add_child(piece)
		piece.connect("pieceMoved",self,"_on_Piece_Moved",[piece])
		piece.connect("promoWait",self,"_on_Piece_PromoWait",[piece])
		piece.connect("promoContinue",self,"_on_Piece_PromoContinue",[piece])
	setPlayerTurn(activePlayer)

func _on_MoveInput_text_changed(new_text):
	if new_text=="":return
	if new_text.to_lower()=="reset":
		reset()
		moveInput.clear()
	if new_text.to_lower()=="fen":
		moveInput.clear()
	parseMove(new_text)

func _on_Button_pressed():
	GlobalVars.flipBoard()
