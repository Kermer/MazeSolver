
# This script is used to load levels from "res://levels" folder, display them and handle interaction while selecting level

extends Control

onready var supported_extensions = ResourceSaver.get_recognized_extensions( PackedScene.new() ) # lazy way of getting supported extensions of 'Scene' (.tscn, .xscn, etc.)
#const button_size = 128
var levels = [] # holds {"filename","name"} of all the loaded levels
var dragging = -1 # holds index of touch we are dragging the screen with
var current_index = -1 # currently shown level index (1 is the first one, instead of 0)
var completed_levels = -1 # loaded from 'Config', amount of completed levels
var level_locked = false # is currently shown level locked?

var swipe_lock = false # this "locks" swipe from triggering multiple times during 1 drag
var touch_pos = null # stores position of the touch
# for swipe to trigger it is needed to drag the screen for 'swipe_length'(pixels on X axis) in less than 'swipe_timer' (seconds)
const swipe_timer = 0.5
const swipe_length = 200
var touch_time = 0 # this is used to count how long are we dragging our screen


func _ready():
	get_node("Current").connect("pressed",self,"_level_selected")
	fetch_levels() # load our levels list

# Overriden functions
func hide():
	set_process_input(false)
	.hide() # call default 'hide()'
func show():
	dragging = -1
	swipe_lock = false
	set_process_input(true)
	update_completed() # check how many levels are completed
	.show()

# Loaded all the scenes inside 'levels' folder.
# Things that are need (for this function) to load a level are:
#	valid extension, .instance() can be called, root node has to contain .get_name() function
#		normally 'name' is loaded from metadata's 'level_name'
func fetch_levels():
	var dir = Directory.new()
	dir.open("res://levels")
	dir.list_dir_begin()
	levels.clear()
	var file_name = dir.get_next()
	while( file_name != "" ):
		if !dir.current_is_dir(): # it's a file
			if file_name.extension() in supported_extensions: # it's a scene
				var level = load("res://levels/"+file_name).instance() # instance it to get the name of the level
				levels.append( {"file":file_name,"name":level.get_name()} )
				level.free()
		file_name = dir.get_next()
	dir.list_dir_end()
	update_completed() # this updates 'completed_levels' and the level displayed


func _input(ev):
	if ev.type == InputEvent.SCREEN_TOUCH:
		if ev.is_pressed(): # >probably< started dragging the screen
			if dragging == -1: # only allow to process 1 finger drag
				dragging = ev.index
				touch_pos = ev.pos
				touch_time = 0
				swipe_lock = -1
				set_process(true)
		else:
			if dragging == ev.index: # stopped dragging
				set_process(false)
				dragging = -1
	elif ev.type == InputEvent.SCREEN_DRAG and ev.index == dragging:
		var touch_length = abs(ev.pos.x-touch_pos.x)
		# this is used to check if we are really dragging or just touching the screen
		# if we dragged for more than 80 pixels (on X axis) then we assume it's a drag
		# otherwise - we asume it's just a touch
		if swipe_lock == -1 and touch_length > 80:
			swipe_lock = 0
		
		if swipe_lock < 1 and touch_time < swipe_timer:
			if touch_length >= swipe_length:
				var dir = sign(ev.pos.x-touch_pos.x)
				if dir == 1: # swipe right
					select_prev()
				else: # left
					select_next()
				swipe_lock = 1
				set_process(false)
		pass

# Currently just used to count the touch/drag time
func _process(delta):
	touch_time += delta
	if touch_time > swipe_timer:
		set_process(false)

func _level_selected():
	# pressed the currently displayed level
	if swipe_lock >= 0 or level_locked: # if we swiped the screen enough or the level is locked
		# do nothing
		return
	var idx = current_index-1
	var level = levels[idx]
	print("Level file: ",level.file)
	print("  Level name: ",level.name)
	get_parent().start_level(level.file,idx) # tell 'menu.gd' that level has been selected
	# 'idx' is passed to 'menu.gd' then to 'game.gd' ( check 'game.gd' _on_win() )
	# 	after calling start_level() whole 'Menu' gets hidden, but hide() in this script won't be called, so need to disable input processing ourself
	set_process_input(false)

func select_next(): # swipe left
	set_current(current_index+1)
func select_prev(): # swipe right
	set_current(current_index-1)

# Displays info about level of given index. (range from 1 to levels.size() - instead of from 0 to size-1)
func set_current(idx):
	if idx < 1 or idx > levels.size(): # is given index valid?
		if idx == levels.size()+1:
			idx -= 1
		else:
			return
	level_locked = false # by default the level is unlocked
	if Config.get_val("all_levels_unlocked") == true:
		pass # keep it unlocked
	else:
		if idx > completed_levels+1: # if we haven't completed previous level
			level_locked = true
	# start making our Label string
	var s = "# "
	if str(idx).length() == 1:
		s += "0"
	s += str(idx)
	s += "\n\n"
	if level_locked:
		s += "[LOCKED]"
	else:
		if idx <= completed_levels:
			s += "[COMPLETED]"
	s += "\n"
	s += levels[idx-1].name
	get_node("Current/Label").set_text( s )
	current_index = idx # update current_index

# Check & update if amount of completed_levels changed (was some level completed recently?)
func update_completed():
	# wait 1 frame to make sure previous changes had time to be completed
	yield(get_tree(),"idle_frame")
	var old_val = completed_levels
	completed_levels = Config.get_val("levels_completed")
	var total = levels.size()
	var s = str(completed_levels," / ",total," Completed")
	get_node("Completed").set_text(s)
	if old_val != completed_levels: # did we unlocked new level since last reload?
		set_current(completed_levels+1)


