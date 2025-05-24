extends Node2D
@export var piece_textures: Array[Texture2D]
@export var piece_colors: Array[Color] = [Color("#ffffff"),Color("#000000")]
@onready var sprite = $Area2D/Sprite2D
@onready var cshape = $Area2D/CollisionShape2D

var magenta_mask: Array[Color] = [Color("#ff00e5"),Color("#e500ff")]

var type: GlobalVars.Piece_Type
var color: GlobalVars.Player_Color
var square: String

func _ready() -> void:
	sprite.scale = GlobalVars.piece_scale
	cshape.scale = GlobalVars.piece_scale

func set_piece_type(piece_type) -> void:
	type = piece_type
	sprite.texture = piece_textures[piece_type]

func set_piece_color(piece_color) -> void:
	color = piece_color
	var magenta_mask_copy = magenta_mask.duplicate()
	if color!= GlobalVars.Player_Color.WHITE:
		magenta_mask_copy.reverse()
	var image: Image = sprite.texture.get_image()
	for x in range(0,16):
		for y in range(0,16):
			var mask_index = magenta_mask_copy.find(image.get_pixel(x,y))
			if mask_index != -1:
				image.set_pixel(x,y,piece_colors[mask_index])
	sprite.texture = ImageTexture.create_from_image(image)
	match color:
		GlobalVars.Player_Color.WHITE:
			add_to_group("WhitePieces")
		GlobalVars.Player_Color.BLACK:
			add_to_group("BlackPieces")
	
