extends Node2D

export (Array, Texture) var textures

var pieceType = GlobalVars.PAWN
var pieceColor = GlobalVars.WHITE
var clicked = false
var occupiedSquare = "e2"

func _process(_delta):
	if(clicked):
		position=get_viewport().get_mouse_position()
		position.x -= get_viewport_rect().size.x/2
		position.y -= get_viewport_rect().size.y/2
		position.x += GlobalVars.g_spriteWidth/2
		position.y += GlobalVars.g_spriteWidth/2
		z_index = 1;
		var target = GlobalVars.getNearestSquare(get_viewport().get_mouse_position())
		if !target.empty():
			occupiedSquare=target;
	else:
		position = GlobalVars.parseCoordinate(occupiedSquare)
		z_index = 0;

func on_click():
	clicked = true

func on_click_released():
	clicked = false

func setPieceType(p):
	pieceType = p
	updateSprite()

func getPieceType():
	return pieceType

func setPieceColor(c):
	pieceColor = c

func getPieceColor():
	return pieceColor

func updateSprite():
	var c
	if pieceColor == GlobalVars.BLACK : c=GlobalVars.g_blackColor;
	else: c=GlobalVars.g_whiteColor;
	var i = textures[pieceType].get_data();
	i.lock();
	for x in i.get_width():
		for y in i.get_height():
			if i.get_pixel(x,y).is_equal_approx(GlobalVars.g_magentaMask):
				i.set_pixel(x,y,c)
	var texture = ImageTexture.new()
	texture.create_from_image(i,1)
	$Sprite.texture = texture

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		self.on_click()
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and !event.is_pressed():
		self.on_click_released()
