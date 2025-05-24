extends Node2D
@export var piece_textures: Array[Texture2D]
@export var piece_colors: Array[Color] = [Color("#ffffff"),Color("#000000")]

@onready var queen_sprite = $QueenSprite
@onready var knight_sprite = $KnightSprite
@onready var bishop_sprite = $BishopSprite
@onready var rook_sprite = $RookSprite

var sprite_color: GlobalVars.Player_Color
var magenta_mask: Array[Color] = [Color("#ff00e5"),Color("#e500ff")]

func initialize_values (color: GlobalVars.Player_Color, board_flipped):
	var sprites = [queen_sprite,knight_sprite,bishop_sprite,rook_sprite]
	sprite_color = color
	var adj_scale = GlobalVars.tile_scale if !board_flipped else -GlobalVars.tile_scale
	if sprite_color!= GlobalVars.Player_Color.WHITE:
		magenta_mask.reverse()
		adj_scale = -adj_scale
	for sprite in sprites:
		set_sprite_color(sprite)
		sprite.scale = GlobalVars.piece_scale
	
	knight_sprite.position.y += adj_scale
	rook_sprite.position.y += adj_scale*2
	bishop_sprite.position.y += adj_scale*3

func set_sprite_color(sprite: Sprite2D) -> void:
	var image: Image = sprite.texture.get_image()
	for x in range(0,16):
		for y in range(0,16):
			var mask_index = magenta_mask.find(image.get_pixel(x,y))
			if mask_index != -1:
				image.set_pixel(x,y,piece_colors[mask_index])
	sprite.texture = ImageTexture.create_from_image(image)
