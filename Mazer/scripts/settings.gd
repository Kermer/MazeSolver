
extends Control

var sound_on
var  sound_volume
var music_on
var  music_volume

const textures = {"sound":[ preload("res://gfx/ui/buttons/sound_off.png"), preload("res://gfx/ui/buttons/sound_on.png") ],
				"music":[ preload("res://gfx/ui/buttons/music_off.png"), preload("res://gfx/ui/buttons/music_on.png") ]
				}

func _ready():
	sound_on = Config.get_val("sound")
	sound_volume = Config.get_val("sound_volume")
	music_on = Config.get_val("music")
	music_volume = Config.get_val("music_volume")
	get_node("BSound").connect("pressed",self,"_on_BSound_pressed")
	get_node("BMusic").connect("pressed",self,"_on_BMusic_pressed")
	toggle_sound(sound_on)
	toggle_music(music_on)

func _on_BSound_pressed():
	toggle_sound( !sound_on )
func toggle_sound( on ):
	var tex = textures["sound"][int(on)]
	get_node("BSound").set_normal_texture( tex )
	sound_on = on
	Config.set_val("sound",sound_on)

func _on_BMusic_pressed():
	toggle_music( !music_on )
func toggle_music( on ):
	var tex = textures["music"][int(on)]
	get_node("BMusic").set_normal_texture( tex )
	music_on = on
	Config.set_val("music",music_on)


