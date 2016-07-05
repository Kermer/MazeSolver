
extends Control

onready var supported_extensions = ResourceSaver.get_recognized_extensions( PackedScene.new() )
#const button_size = 128
var levels = []
var dragging = -2
var current_index = 1
var completed_levels = 0

var swipe_lock = false

#const columns_per_row = 4


func _ready():
	get_node("Scaling/Current").connect("pressed",self,"_level_selected")
	fetch_levels()
	
#	yield(get_tree(),"idle_frame")
#	get_node("../Main").hide()
#	show()
	
	pass

func hide():
	set_process_input(false)
	.hide()
func show():
	dragging = -2
	swipe_lock = false
	set_process_input(true)
	update_completed()
	.show()

func fetch_levels():
	var dir = Directory.new()
	dir.open("res://levels")
	dir.list_dir_begin()
	levels.clear()
	var file_name = dir.get_next()
	while( file_name != "" ):
		if !dir.current_is_dir(): # it's a file
			if file_name.extension() in supported_extensions: # it's a scene
#				levels.append(file_name)
				# below is a way to load level names
				var level = load("res://levels/"+file_name).instance()
#				print(file_name," : ",level.get_name())
				levels.append( {"file":file_name,"name":level.get_name()} )
				level.free()
		file_name = dir.get_next()
	dir.list_dir_end()
	set_current(current_index)
#	reload_buttons(levels)
	


func _input(ev):
	if ev.type == InputEvent.SCREEN_TOUCH:
		if ev.is_pressed():
			dragging = -1
		else:
			swipe_lock = false
			yield(get_tree(),"idle_frame")
			dragging = -2
	elif ev.type == InputEvent.SCREEN_DRAG:
		if dragging == -1 and ev.speed.length() > 300:
			dragging = ev.index
		if swipe_lock == false:
			if sign(ev.relative_x)==sign(ev.speed_x) && abs(ev.speed_x) > 600:
#				get_node("Label").set_text(str(ev.speed_x))
				if sign(ev.speed_x) == 1:
					select_prev()
				else:
					select_next()
				swipe_lock = true
		pass

func _level_selected():
	if dragging >= 0:
		return
	var idx = current_index-1
	var level = levels[idx]
	print("Level file: ",level.file)
	print("  Level name: ",level.name)
	get_parent().start_level(level.file,idx)
	set_process_input(false)

func select_next():
	set_current(current_index+1)
func select_prev():
	set_current(current_index-1)

func set_current(idx):
	if idx < 1 or idx > levels.size():
		if idx == levels.size()+1:
			idx -= 1
		else:
			return
	var level_locked = false
	if Config.get_val("all_levels_unlocked") == true:
		pass
	else:
		if idx > completed_levels+1:
			level_locked = true
	var s = "# "
	if str(idx).length() == 1:
		s += "0"
	s += str(idx)
	s += "\n\n"
	if level_locked:
		s += "[LOCKED]"
		get_node("Scaling/Current").set_disabled(true)
	else:
		if idx <= completed_levels:
			s += "[COMPLETED]"
		get_node("Scaling/Current").set_disabled(false)
	s += "\n"
	s += levels[idx-1].name
	get_node("Scaling/Current/Label").set_text( s )
	current_index = idx

func update_completed():
	yield(get_tree(),"idle_frame")
	var old_val = completed_levels
	completed_levels = Config.get_val("levels_completed")
	var total = levels.size()
	var s = str(completed_levels," / ",total," Completed")
	get_node("Scaling/Completed").set_text(s)
	if old_val != completed_levels: # did we unlocked new level since last reload?
		set_current(completed_levels+1)


#func _level_selected( idx, row ):
#	idx = int(row*columns_per_row) + int(idx)
#	print("Load level: ",levels[idx])
#	get_parent().start_level(levels[idx])
#	set_process_input(false)
#
#func reload_buttons(levels):
#	for button_arr in get_node("Buttons").get_children():
#		button_arr.queue_free()
#	var row = 0
#	var button_arr
#	for i in range(levels.size()):
#		if i % columns_per_row == 0:
#			button_arr = HButtonArray.new()
#			button_arr.set("button/min_button_size",button_size)
#			button_arr.set_pos( Vector2(0,(button_size+8)*row) )
#			button_arr.set_size(Vector2(columns_per_row*button_size,button_size))
#			button_arr.connect("button_selected",self,"_level_selected",[row])
#			get_node("Buttons").add_child(button_arr)
#			row += 1
#		var s = str(i+1)
#		if s.length() == 1:
#			s = "0"+s
#		button_arr.add_button(s)

