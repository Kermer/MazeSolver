
extends Control

const SELECT_DISABLED = -1
# check Tree constants
const SELECT_SINGLE = 0
const SELECT_ROW = 1
const SELECT_MULTI = 2


const N=1; const S=2; const E=4; const W=8

const tree_items = [
	{"name":"Dynamic Tiles","tip":"Tiles which adjust to adjacent tiles","children":[
		{"name":"Maze Path","tip":"Base of each maze"},
		{"name":"Maze Wall","tip":"Opposite to 'Path'"}
		]
	},
	{"name":"Objects","tip":"Placeable items with possible unique properties","children":[
		{"name":"Collectibles","tip":"Triggering some action when walked-on","children":[
			{"name":"Increase Energy","tip":"Increases Energy on pickup"}
			]
		}
		]
	},
	{"name":"Environment","tip":"Objects (and more) affecting gameplay","children":[
		{"name":"Start Pos","tip":"Point where player will spawn"},
		{"name":"End Pos","tip":"Step here to finish the level"},
		{"name":"Right Border","tip":""},
		{"name":"Top Border","tip":""}
		]
	}
	]

const items_data = {
	"Maze Path":{"name":"Maze Path","category":"Tiles",
		"preview":{"texture":preload("res://map_editor/previews/path.png")}
		},
	"Maze Wall":{"name":"Maze Wall","category":"Tiles",
		"preview":{"texture":preload("res://map_editor/previews/wall.png")}
		},
	"Increase Energy":{"name":"Increase Energy","category":"Objects","path":"Objects/Collectibles",
		"preview":{"texture":preload("res://map_editor/previews/increase_energy.png"),"scale":Vector2(0.5,0.5)},
		"scene":preload("res://scenes/collectible.tscn"),
		"scene_vars":{"type":"IncEnergy"}
		},
	"Start Pos":{"name":"Start Pos","category":"Environment",
		"preview":{"texture":preload("res://map_editor/previews/start_pos.png"),"scale":Vector2(0.5,0.5)}
		},
	"End Pos":{"name":"End Pos","category":"Environment","path":"EndPos",
		"preview":{"texture":preload("res://map_editor/previews/end_pos.png")},
		"scene":preload("res://scenes/end_pos.tscn")
		},
	"Right Border":{"name":"Right Border","category":"Environment"},
	"Top Border":{"name":"Top Border","category":"Environment"},
	}


# Selection tree related
#var selectable_items = [] # this will be auto-filled
var selected_item = {"name":"","category":""}
onready var item_tree = get_node("CL/ItemSelection")
signal item_selected
# TileMap edition related
const level_script = preload("res://scripts/default_maze.gd")
onready var obj_preview = get_node("Level/HELPERS/ObjectPreview")
var cell_size = 64
var move_speed = 600
var zoom_speed = 0.8
var grid = {}
var mouse_drag = 0 # 0-none 1-LMB 2-RMB
var last_tile_pos = null
var WIDTH = 4
var HEIGHT = 4
onready var tmap = get_node("Level/TileMap")
var objects = {}





func _ready():
#	OS.set_window_maximized(true)
	init()
	item_tree.connect("item_collapsed",self,"_titem_collapsed")
	item_tree.connect("cell_selected",self,"_titem_selected")
	item_tree.connect("item_activated",item_tree,"hide")
	connect("item_selected",self,"_item_selected")
	pass

func init():
	fill_tree()
	get_node("Camera").make_current()

func set_process(val): # override
	.set_process(val)
	set_process_unhandled_input(val)

# ========================================
#  Item Selection Tree
# ========================================
func fill_tree():
	item_tree.clear()
	var titem = item_tree.create_item()
	titem.set_text(0,"Editor")
	item_tree.set_select_mode(0)
	for tree_category in tree_items:
		fill_tree_item(tree_category,titem)
	pass

func fill_tree_item(item_data,parent=null):
	var titem = item_tree.create_item(parent)
	titem.set_text(0,item_data.name)
	titem.set_tooltip(0,"")
	if item_data.has("tip"):
		titem.set_tooltip(0,item_data.tip)
	if item_data.has("children"):
		for child_data in item_data.children:
			fill_tree_item(child_data,titem)
	pass

func _titem_collapsed( titem ):
	if titem.get_text(0) == "Editor" and titem.is_collapsed():
		# hide selection tree
		item_tree.hide()
		titem.set_collapsed(false)
		pass

func _titem_selected():
	var titem = item_tree.get_selected()
	var item_name = titem.get_text(0)
	if items_data.has(item_name):
		if selected_item.name != item_name:
			if selected_item.name == "Right Border":
				get_node("Level/HELPERS/VLine").hide()
			elif selected_item.name == "Top Border":
				get_node("Level/HELPERS/HLine").hide()
			selected_item = items_data[item_name]
			emit_signal("item_selected",selected_item)
			print("item selected: ",item_name)

func toggle_selection_window():
	if item_tree.is_hidden():
		item_tree.show()
	else:
		item_tree.hide()

func set_level_name( s ):
	s = str(s).strip_edges()
	get_node("../CL/EscMenu/LevelName").set_text(s)
	if s == "":
		s = "_UNNAMED_"
	get_node("CL/LevelName").set_text(s)

func clear_level():
	var level = get_node("Level")
	set_level_name("")
	tmap.clear()
	grid.clear()
	for obj_pos in objects:
		objects[obj_pos].queue_free()
	objects.clear()
	var pos = Vector2(32,-32)
	level.get_node("StartPos").set_pos(pos)
	WIDTH = 4; HEIGHT = 4
	level.draw_size(WIDTH*cell_size,HEIGHT*cell_size)

func load_level(new_level):
	var level = get_node("Level")
	# get the name
	var lname = ""
	if new_level.has_meta("level_name"):
		lname = new_level.get_meta("level_name")
		print("Loading level name from metadata")
	else:
		lname = new_level.get_name()
		print("Loading level name from Node name")
	print("Level name: '",lname,"'")
	if lname == "_UNNAMED_":
		lname = ""
	set_level_name(lname)
	# check if it's correct / was made using map editor
	if !new_level.has_meta("level_grid"):
		print("WARNING! Level doesn't contain 'level_grid'! Skipping TileMap loading!")
		print("   Was it made using map editor?")
	else:
		# load TileMap and 'grid'
		level.remove_child(tmap)
		tmap.free()
		grid = new_level.get_meta("level_grid")
		var new_tmap = new_level.get_node("TileMap")
		new_level.remove_child(new_tmap)
		level.add_child(new_tmap)
		level.move_child(new_tmap,0)
		print(new_tmap.get_name())
		tmap = new_tmap
	for obj_pos in objects:
		objects[obj_pos].queue_free()
	objects.clear()
	# wait 2 frames, to make sure our objects are removed before we continue
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	# load Collectibles
	for collectible in new_level.get_node("Objects/Collectibles").get_children():
		var idata = null
		var ipos
		if collectible.get("type") == "IncEnergy":
			idata = items_data["Increase Energy"]
			ipos = collectible.get_pos()
		if idata != null:
			add_object(idata,ipos)
	# TODO load other Objects
	
	# load Start/EndPos
	level.get_node("StartPos").set_pos( new_level.get_node("StartPos").get_pos() )
	var n_end_pos = new_level.get_node("EndPos")
	if n_end_pos.get_type() != "Node2D": # single end pos
		add_object(items_data["End Pos"],n_end_pos.get_pos())
	else: # multiple end pos support
		for end_pos in n_end_pos.get_children():
			add_object(items_data["End Pos"],end_pos.get_pos())
	# WIDTH / HEIGHT
	WIDTH = new_level.get("WIDTH")
	HEIGHT = new_level.get("HEIGHT")
	level.draw_size( WIDTH*cell_size, HEIGHT*cell_size )
	pass

func get_packed_level(level_name):
	var level = get_node("Level").duplicate()
	# replacing Nodes (with other type or scene)
	var nav = Navigation2D.new()
	level.replace_by( nav, true )
	level = nav
	var start_pos = Position2D.new()
	start_pos.set_name("StartPos"); start_pos.set_pos(level.get_node("StartPos").get_pos())
	level.get_node("StartPos").replace_by( start_pos )
	level.remove_child( level.get_node("HELPERS") )
	if level_name == "":
		level_name = "_UNNAMED_"
	level.set_script(level_script)
	level.set_name(level_name)
	var packed_scene = PackedScene.new()
	level.set_meta("level_name",level_name)
	level.set_meta("level_grid",grid)
	level.set_meta("level_width",WIDTH)
	level.set_meta("level_height",HEIGHT)
	level.set("WIDTH",WIDTH)
	level.set("HEIGHT",HEIGHT)
	recursive_set_owner(level,level)
	packed_scene.pack(level)
	packed_scene.set_meta("level_name",level_name)
	return packed_scene

func recursive_set_owner(owner,node):
	
	for child in node.get_children():
		child.set_owner(owner)
		if node.get_name() == "Collectibles" or node.get_name() == "EndPos": # otherwise "Editable Children" glitches
			continue
		recursive_set_owner(owner,child)


# ========================================
#  (mostly) TileMap related
# ========================================
func _unhandled_input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		var mpos = get_node("Level").get_local_mouse_pos()
		if obj_preview.is_visible():
			if mpos.x > 0 and mpos.y < 0:
#				mpos.x = int(mpos.x)/cell_size*cell_size;mpos.y = int(mpos.y)/cell_size*cell_size
#				mpos += Vector2(cell_size/2,cell_size/2)
				mpos = tmap.map_to_world(tmap.world_to_map(mpos)) + Vector2(cell_size,cell_size)/2
#				obj_preview.set_global_pos( mpos )
				if selected_item.category == "Tiles":
					if selected_item.name == "Maze Wall":
						mpos = tmap.map_to_world(tmap.world_to_map(get_node("Level").get_local_mouse_pos() + Vector2(cell_size,cell_size)/2))
					if mouse_drag == 1:
						place_item()
					elif mouse_drag == 2:
						remove_item()
				elif selected_item.name == "Right Border":
					get_node("Level/HELPERS/VLine").set_pos( Vector2(mpos.x+0.5*cell_size,128) )
				elif selected_item.name == "Top Border":
					get_node("Level/HELPERS/HLine").set_pos( Vector2(-128,mpos.y-0.5*cell_size) )
				obj_preview.set_pos( mpos )
	elif event.type == InputEvent.MOUSE_BUTTON:
		if event.button_index == 2:
			if event.is_pressed():
				remove_item()
				mouse_drag = 2
				set_process_input(true)
		elif event.button_index == 1:
			var mpos = get_node("Level").get_local_mouse_pos()
			if mpos.x > 0 and mpos.y < 0:
				if event.is_pressed():
					mouse_drag = 1
					place_item(mpos)
					set_process_input(true)
		elif event.button_index == BUTTON_WHEEL_UP:
			get_node("Camera").set_zoom( get_node("Camera").get_zoom()*zoom_speed )
		elif event.button_index == BUTTON_WHEEL_DOWN:
			get_node("Camera").set_zoom( get_node("Camera").get_zoom()/zoom_speed )
	elif event.type == InputEvent.KEY:
		if event.scancode == KEY_Q and !event.is_echo():
			if event.is_pressed():
				item_tree.show()
			else:
				item_tree.hide()
		elif event.scancode == KEY_ESCAPE and event.is_pressed():
			set_process(false)
			get_parent().show_menu()
	

func _input(event): # basically just for mouse button release
	if mouse_drag and event.type == InputEvent.MOUSE_BUTTON and !event.is_pressed():
		mouse_drag = 0
		last_tile_pos = null
		set_process_input(false)


func place_item(global_pos=null):
	if selected_item.category == "":
		return
	if global_pos==null:
		global_pos = get_node("Level").get_local_mouse_pos()
	var tpos = tmap.world_to_map(global_pos)
	
	# Dynamic Tiles
	if selected_item.category == "Tiles":
		if selected_item.name == "Maze Path":
			add_path(global_pos)
		elif selected_item.name == "Maze Wall":
			add_wall(global_pos)
		else:
			return
	# Objects
	elif selected_item.category == "Objects":
		if selected_item.name == "Increase Energy":
			add_object(selected_item,global_pos)
		else:
			return
	# Environment
	elif selected_item.category == "Environment":
		if selected_item.name == "Start Pos":
			global_pos = tmap.map_to_world(tpos) + Vector2(cell_size,cell_size)/2
			get_node("Level/StartPos").set_pos( global_pos )
		elif selected_item.name == "End Pos":
			# support multiple end pos
			add_object(selected_item,global_pos)
#			global_pos = tmap.map_to_world(tpos) + Vector2(cell_size,cell_size)/2
#			get_node("Level/EndPos").set_pos( global_pos )
		elif selected_item.name == "Right Border":
			WIDTH = tpos.x+1
			get_node("Level").draw_size(WIDTH*cell_size,HEIGHT*cell_size)
			return
		elif selected_item.name == "Top Border":
			HEIGHT = -(tpos.y)
			get_node("Level").draw_size(WIDTH*cell_size,HEIGHT*cell_size)
			return
		else:
			return
	else:
		return
	tpos.x += 1; tpos.y -= 2
	if tpos.x > WIDTH:
		WIDTH = tpos.x
	if tpos.y < -HEIGHT:
		HEIGHT = -tpos.y
	get_node("Level").draw_size(WIDTH*cell_size,HEIGHT*cell_size)

func remove_item(global_pos=null):
	if global_pos==null:
		global_pos = get_node("Level").get_local_mouse_pos()
	
	if selected_item.category == "Tiles":
		if selected_item.name == "Maze Path":
			remove_path(global_pos)
	elif selected_item.category == "Objects":
		remove_object(global_pos)
	elif selected_item.category == "Environment":
		if selected_item.name == "End Pos":
			remove_object(global_pos)


func add_path(global_pos):
	var pos = tmap.world_to_map(global_pos)
	if last_tile_pos != null and last_tile_pos == pos: # still on the same tile
		return
	var connection_mask = 0
	if grid.has(pos):
		connection_mask = grid[pos]
	if last_tile_pos != null:
		var pos_diff = pos - last_tile_pos
		check_and_fix_previous(last_tile_pos,pos_diff)
		if pos_diff.x == 1:
			connection_mask |= W
			grid[last_tile_pos] |= E
		elif pos_diff.x == -1:
			connection_mask |= E
			grid[last_tile_pos] |= W
		elif pos_diff.y == 1:
			connection_mask |= N
			grid[last_tile_pos] |= S
		elif pos_diff.y == -1:
			connection_mask |= S
			grid[last_tile_pos] |= N
		var prop = get_tile_properties(last_tile_pos)
		tmap.set_cellv(last_tile_pos,prop[0],prop[1],prop[2],prop[3])
	grid[pos] = connection_mask
	
	var prop = get_tile_properties(pos)
	tmap.set_cellv(pos,prop[0],prop[1],prop[2],prop[3])
	
	last_tile_pos = pos

func add_wall(global_pos):
	var pos = tmap.world_to_map(global_pos + Vector2(cell_size,cell_size)/2)
	if last_tile_pos == pos: # still on the same tile
		return
	if last_tile_pos == null:
		last_tile_pos = pos
		return
	
	var dir = pos - last_tile_pos
	last_tile_pos = pos
	if dir == Vector2(0,1): # going DOWN
		pos = tmap.world_to_map(global_pos + Vector2(cell_size,-cell_size)/2)
		var poss = prepare_walls_grid(pos);var SEpos = poss[0];var SWpos = poss[1]
		grid[SEpos] -= grid[SEpos]&W
		grid[SWpos] -= grid[SWpos]&E
		var prop = get_tile_properties(SEpos)
		tmap.set_cellv(SEpos,prop[0],prop[1],prop[2],prop[3])
		var prop = get_tile_properties(SWpos)
		tmap.set_cellv(SWpos,prop[0],prop[1],prop[2],prop[3])
	elif dir == Vector2(0,-1): # going UP
		pos = tmap.world_to_map(global_pos + Vector2(cell_size,cell_size*2)/2)
		var poss = prepare_walls_grid(pos);var NEpos = poss[3];var NWpos = poss[2]
		grid[NEpos] -= grid[NEpos]&W
		grid[NWpos] -= grid[NWpos]&E
		var prop = get_tile_properties(NEpos)
		tmap.set_cellv(NEpos,prop[0],prop[1],prop[2],prop[3])
		var prop = get_tile_properties(NWpos)
		tmap.set_cellv(NWpos,prop[0],prop[1],prop[2],prop[3])
	elif dir == Vector2(1,0): # going RIGHT
		pos = tmap.world_to_map(global_pos - Vector2(cell_size,-cell_size)/2)
		var poss = prepare_walls_grid(pos);var SEpos = poss[0];var NEpos = poss[3]
		grid[SEpos] -= grid[SEpos]&N
		grid[NEpos] -= grid[NEpos]&S
		var prop = get_tile_properties(SEpos)
		tmap.set_cellv(SEpos,prop[0],prop[1],prop[2],prop[3])
		var prop = get_tile_properties(NEpos)
		tmap.set_cellv(NEpos,prop[0],prop[1],prop[2],prop[3])
	elif dir == Vector2(-1,0): # going LEFT
		pos = tmap.world_to_map(global_pos - Vector2(-cell_size*2,-cell_size)/2)
		var poss = prepare_walls_grid(pos);var SWpos = poss[1];var NWpos = poss[2]
		grid[SWpos] -= grid[SWpos]&N
		grid[NWpos] -= grid[NWpos]&S
		var prop = get_tile_properties(SWpos)
		tmap.set_cellv(SWpos,prop[0],prop[1],prop[2],prop[3])
		var prop = get_tile_properties(NWpos)
		tmap.set_cellv(NWpos,prop[0],prop[1],prop[2],prop[3])


func prepare_walls_grid( pos ):
	var SEpos = pos
	var SWpos = pos - Vector2(1,0)
	var NWpos = pos - Vector2(1,1)
	var NEpos = pos - Vector2(0,1)
	
	var arr = [SEpos,SWpos,NWpos,NEpos]
	for apos in arr:
		if !grid.has(apos):
			grid[apos] = N|S|W|E
	
	return arr

func add_object(item_data,pos):
	var tpos = tmap.world_to_map(pos)
	if objects.has(tpos):
		return # there's already an object at this point
	var inst = item_data.scene.instance()
	if item_data.has("scene_vars"):
		for var_name in item_data.scene_vars:
			inst.set(var_name,item_data.scene_vars[var_name])
	pos = tmap.map_to_world(tpos) + Vector2(0.5,0.5)*cell_size
	inst.set_pos( pos )
	var level = get_node("Level")
	level.get_node(item_data.path).add_child(inst)
	objects[tpos] = inst

func remove_object(pos):
	var tpos = tmap.world_to_map(pos)
	if objects.has(tpos):
		objects[tpos].queue_free()
		objects.erase(tpos)

func check_and_fix_previous(pos,dir):
	var previous = pos-dir
	if grid.has(previous):
		var previous_mask = grid[previous]
		if dir.x == 1 and previous_mask&E:
			grid[pos] |= W
		elif dir.x == -1 and previous_mask&W:
			grid[pos] |= E
		elif dir.y == 1 and previous_mask&S:
			grid[pos] |= N
		elif dir.y == -1 and previous_mask&N:
			grid[pos] |= S
		var prop = get_tile_properties(previous)
		tmap.set_cellv(previous,prop[0],prop[1],prop[2],prop[3])

func remove_path(global_pos):
	var pos = tmap.world_to_map(global_pos)
	if !grid.has(pos):
		return
	grid.erase(pos)
	tmap.set_cellv(pos,-1)
	pass


func _process(delta):
	var dir = Vector2(0,0)
	var actions = { "me_right":Vector2(-1,0), "me_left":Vector2(1,0), "me_down":Vector2(0,-1), "me_up":Vector2(0,1) }
	for ac in actions:
		if Input.is_action_pressed(ac):
			dir += actions[ac]
	dir = dir.normalized()
	var level = get_node("Level")
	level.set_pos( level.get_pos() + dir*move_speed*delta )

func _item_selected( item_data ):
	var tex = null
	var scale = Vector2(1,1)
	if item_data.has("preview"):
		tex = item_data.preview.texture
		if item_data.preview.has("scale"):
			scale = item_data.preview.scale
	elif item_data.name == "Right Border":
		get_node("Level/HELPERS/VLine").show()
	elif item_data.name == "Top Border":
		get_node("Level/HELPERS/HLine").show()
	obj_preview.set_texture(tex)
	obj_preview.set_scale(scale)
	pass








func get_tile_properties(pos):
	var connect_mask = grid[pos] # direction mask for cells connected to checked one (ones you can walk to)
	var walls_count = 4
	for mask in [N,S,W,E]: # 1, 2, 8, 4
		if connect_mask&mask:
			walls_count -= 1
	var prop = [-1,false,false,false]
	var rot = 0
	if walls_count == 0:
		prop[0] = 0
	elif walls_count == 1:
		prop[0] = 1
		if !connect_mask&W: # wall on the left
			rot = 90
		elif !connect_mask&N:
			rot = 180
		elif !connect_mask&E:
			rot = 270
	elif walls_count == 2:
		if (connect_mask&N and connect_mask&S) or (connect_mask&W and connect_mask&E):
			prop[0] = 3 # tunnel
			if connect_mask&N: # vertical
				rot = 90
		else:
			prop[0] = 2 # corner
			if connect_mask&E:
				if connect_mask&N:
					rot = 90
				else:
					rot = 180
			elif connect_mask&S and connect_mask&W:
				rot = 270
	elif walls_count == 3:
		prop[0]=4
		if connect_mask&E:
			rot = 90
		elif connect_mask&S:
			rot = 180
		elif connect_mask&W:
			rot = 270
	elif walls_count == 4:
		prop[0] = 5
	
	return rotate_properties(prop,rot)


func rotate_properties(prop,rot):
	if rot == 0:
		return prop
	if rot == 90:
		prop = [prop[0],true,false,true]
	elif rot == 180:
		prop = [prop[0],true,true,false]
	elif rot == 270:
		prop = [prop[0],false,true,true]
	return prop





func world_to_map(pos):
	pos.x = floor(pos.x/cell_size)
	pos.y = floor(pos.y/cell_size)
	return pos
func map_to_world(pos):
	pos.x = pos.x*cell_size
	pos.y = pos.y*cell_size
	return pos






