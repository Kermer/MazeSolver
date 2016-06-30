
extends Control

onready var supported_extensions = ResourceSaver.get_recognized_extensions( PackedScene.new() )
const button_size = 128
var levels = []

const columns_per_row = 4


func _ready():
	fetch_levels()
	
#	yield(get_tree(),"idle_frame")
#	get_node("../Main").hide()
#	show()
	
	pass

func fetch_levels():
	var dir = Directory.new()
	dir.open("res://levels")
	dir.list_dir_begin()
	levels.clear()
	var file_name = dir.get_next()
	while( file_name != "" ):
		if !dir.current_is_dir(): # it's a file
			if file_name.extension() in supported_extensions: # it's a scene
				levels.append(file_name)
				# below is a way to load level names
#				var level = load("res://levels/"+file_name).instance()
#				print(file_name," : ",level.get_name())
#				level.free()
		file_name = dir.get_next()
	dir.list_dir_end()
	reload_buttons(levels)
	

func _level_selected( idx, row ):
	idx = int(row*columns_per_row) + int(idx)
	print("Load level: ",levels[idx])
	get_parent().start_level(levels[idx])

func reload_buttons(levels):
	for button_arr in get_node("Buttons").get_children():
		button_arr.queue_free()
	var row = 0
	var button_arr
	for i in range(levels.size()):
		if i % columns_per_row == 0:
			button_arr = HButtonArray.new()
			button_arr.set("button/min_button_size",button_size)
			button_arr.set_pos( Vector2(0,(button_size+8)*row) )
			button_arr.set_size(Vector2(columns_per_row*button_size,button_size))
			button_arr.connect("button_selected",self,"_level_selected",[row])
			get_node("Buttons").add_child(button_arr)
			row += 1
		var s = str(i+1)
		if s.length() == 1:
			s = "0"+s
		button_arr.add_button(s)

