
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
#var grid = {} # soon it'll be deprecated
var walls_grid = {} # contains info about existing walls
var mouse_drag = 0 # 0-none 1-LMB 2-RMB
var last_tile_pos = null
var last_tile_dir = 0
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
	walls_grid.clear()
	for obj_pos in objects:
		objects[obj_pos].queue_free()
	objects.clear()
	var pos = Vector2(32,-32)
	level.get_node("StartPos").set_pos(pos)
	WIDTH = 4; HEIGHT = 4
	level.draw_size(WIDTH*cell_size,HEIGHT*cell_size)

func load_level(new_level):
#	print("LOADING TEMPORARILY DISABLED")
#	
#	return
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
	var has_paths_grid = new_level.has_meta("level_grid")
	if !new_level.has_meta("walls_grid"): # not made using latest map editor
		if has_paths_grid: # but made using older version
			walls_grid = interpret_paths_to_walls(new_level.get_meta("level_grid"))
			tmap.clear()
			for wpos in walls_grid:
				var prop = get_wall_tile_properties(wpos)
				tmap.set_cellv(wpos,prop[0],prop[1],prop[2],prop[3])
			print("Importing level made using older version of map editor [level_grid->walls_grid]")
		else:
			print("WARNING! Level doesn't contain 'walls_grid'! Skipping TileMap loading!")
			print("   Was it made using map editor?")
			tmap.clear()
	else:
		# load TileMap and 'grid'
		level.remove_child(tmap)
		tmap.free()
		walls_grid = new_level.get_meta("walls_grid")
		var new_tmap = new_level.get_node("TileMap")
		new_level.remove_child(new_tmap)
		level.add_child(new_tmap)
		level.move_child(new_tmap,0)
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
		if has_paths_grid: # outdated levels support
			ipos -= Vector2(0,cell_size)
		if idata != null:
			add_object(idata,ipos)
	# TODO load other Objects
	
	# load Start/EndPos
	level.get_node("StartPos").set_pos( new_level.get_node("StartPos").get_pos() + (int(has_paths_grid)*Vector2(cell_size,-cell_size)/2) )
	var n_end_pos = new_level.get_node("EndPos")
	if n_end_pos.get_type() != "Node2D": # single end pos
		add_object(items_data["End Pos"],n_end_pos.get_pos())
	else: # multiple end pos support
		for end_pos in n_end_pos.get_children():
			var ipos = end_pos.get_pos()
			if has_paths_grid: # outdated levels support
				ipos -= Vector2(0,cell_size)
			add_object(items_data["End Pos"],ipos)
	# WIDTH / HEIGHT
	WIDTH = new_level.get("WIDTH")
	HEIGHT = new_level.get("HEIGHT")
	level.draw_size( WIDTH*cell_size, HEIGHT*cell_size )
	pass

func interpret_paths_to_walls(paths):
	var walls = {}
	for ppos in paths:
		var pmask = paths[ppos]
		var SW=0;var NW=1;var NE=2;var SE=3
		var dirs = [Vector2(0,0),Vector2(0,-1),Vector2(1,-1),Vector2(1,0)]
		var wmasks = [0,0,0,0] # SW,NW,NE,SE
		for i in range(4):
			if walls.has(ppos+dirs[i]):
				wmasks[i] = walls[ppos+dirs[i]]
		# REMINDER: path mask tells you where are another paths (not walls!)
		if !pmask&N: # there's no path (there's a wall) on the north from this position
			wmasks[NW] |= E
			wmasks[NE] |= W
		if !pmask&S:
			wmasks[SW] |= E
			wmasks[SE] |= W
		if !pmask&W:
			wmasks[NW] |= S
			wmasks[SW] |= N
		if !pmask&E:
			wmasks[NE] |= S
			wmasks[SE] |= N
		for i in range(4):
			if wmasks[i] == 0: # no need for unconnected walls
				continue
			var wpos = ppos + dirs[i]
			walls[wpos] = wmasks[i]
	return walls

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
#	level.set_meta("level_grid",grid) # deprecated
	level.set_meta("walls_grid",walls_grid)
	level.set_meta("level_width",WIDTH)
	level.set_meta("level_height",HEIGHT)
	level.set("WIDTH",WIDTH)
	level.set("HEIGHT",HEIGHT)
	recursive_set_owner(level,level)
	packed_scene.pack(level)
	set_level_name(level_name) # update display
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
				var preview_pos = null
#				obj_preview.set_global_pos( mpos )
				if selected_item.category == "Tiles":
					if selected_item.name == "Maze Wall":
						preview_pos = tmap.map_to_world(tmap.world_to_map(mpos)) + Vector2(0.5,0.5)*cell_size
					if mouse_drag == 1:
						place_item()
					elif mouse_drag == 2:
						remove_item()
				elif selected_item.category == "Environment":
					preview_pos = tmap.map_to_world(tmap.world_to_map(mpos + Vector2(cell_size,cell_size)/2))
					if selected_item.name == "Right Border":
						get_node("Level/HELPERS/VLine").set_pos( Vector2(preview_pos.x+cell_size,128) )
					elif selected_item.name == "Top Border":
						get_node("Level/HELPERS/HLine").set_pos( Vector2(-128,preview_pos.y) )
				else:
					preview_pos = tmap.map_to_world(tmap.world_to_map(mpos + Vector2(cell_size,cell_size)/2))
				if preview_pos == null:
					preview_pos = tmap.map_to_world(tmap.world_to_map(mpos + Vector2(cell_size,cell_size)/2))
				obj_preview.set_pos( preview_pos )
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
		last_tile_dir = 0
		set_process_input(false)


func place_item(global_pos=null):
	if selected_item.category == "":
		return
	if global_pos==null:
		global_pos = get_node("Level").get_local_mouse_pos()
	var tpos = tmap.world_to_map(global_pos + Vector2(cell_size,cell_size)/2)
	
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
			global_pos = tmap.map_to_world(tpos)
			get_node("Level/StartPos").set_pos( global_pos )
		elif selected_item.name == "End Pos":
			# support multiple end pos
			add_object(selected_item,global_pos)
#			global_pos = tmap.map_to_world(tpos) + Vector2(cell_size,cell_size)/2
#			get_node("Level/EndPos").set_pos( global_pos )
		elif selected_item.name == "Right Border":
			WIDTH = max(3,tpos.x+1)
			get_node("Level").draw_size(WIDTH*cell_size,HEIGHT*cell_size)
			return
		elif selected_item.name == "Top Border":
			HEIGHT = max(3,-(tpos.y))
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
	WIDTH = max(3,WIDTH)
	HEIGHT = max(3,HEIGHT)
	get_node("Level").draw_size(WIDTH*cell_size,HEIGHT*cell_size)

func remove_item(global_pos=null):
	if global_pos==null:
		global_pos = get_node("Level").get_local_mouse_pos()
	
	if selected_item.category == "Tiles":
		if selected_item.name == "Maze Path":
#			remove_path(global_pos)
			pass
		elif selected_item.name == "Maze Wall":
			remove_wall(global_pos)
	elif selected_item.category == "Objects":
		remove_object(global_pos)
	elif selected_item.category == "Environment":
		if selected_item.name == "End Pos":
			remove_object(global_pos)


#func add_path(global_pos):
#	return
#	var pos = tmap.world_to_map(global_pos)
#	if last_tile_pos != null and last_tile_pos == pos: # still on the same tile
#		return
#	var connection_mask = 0
#	if grid.has(pos):
#		connection_mask = grid[pos]
#	if last_tile_pos != null:
#		var pos_diff = pos - last_tile_pos
#		check_and_fix_previous(last_tile_pos,pos_diff)
#		if pos_diff.x == 1:
#			connection_mask |= W
#			grid[last_tile_pos] |= E
#		elif pos_diff.x == -1:
#			connection_mask |= E
#			grid[last_tile_pos] |= W
#		elif pos_diff.y == 1:
#			connection_mask |= N
#			grid[last_tile_pos] |= S
#		elif pos_diff.y == -1:
#			connection_mask |= S
#			grid[last_tile_pos] |= N
#		var prop = get_tile_properties(last_tile_pos)
#		tmap.set_cellv(last_tile_pos,prop[0],prop[1],prop[2],prop[3])
#	grid[pos] = connection_mask
#	
#	var prop = get_tile_properties(pos)
#	tmap.set_cellv(pos,prop[0],prop[1],prop[2],prop[3])
#	
#	last_tile_pos = pos

func add_path(global_pos):
	var pos = tmap.world_to_map(global_pos + Vector2(cell_size,cell_size)/2)
	if last_tile_pos == null:
		last_tile_pos = pos
		return
	elif last_tile_pos == pos: # still on the same tile
		return
	var dir = pos - last_tile_pos
	var poss = prepare_walls_grid(last_tile_pos)
	var SEpos = poss[0];var SWpos = poss[1];var NWpos = poss[2];var NEpos = poss[3]
	var SEmask = walls_grid[SEpos];var SWmask = walls_grid[SWpos];var NWmask = walls_grid[NWpos];var NEmask = walls_grid[NEpos]
	
	if dir == Vector2(0,1): # going DOWN
		SEmask |= N;SEmask -= SEmask&W
		SWmask |= N;SWmask -= SWmask&E
		NEmask |= S;NEmask -= NEmask&W
		NWmask |= S;NWmask -= NWmask&E
		
		if last_tile_dir == 0:
			if NEmask==S and NWmask==S:
				NEmask |= W; NWmask |= E
		elif last_tile_dir in [E,W]:
			NEmask |= W; NWmask |= E
			if last_tile_dir == E:
				NWmask -= NWmask&S; SWmask -= SWmask&N
			elif last_tile_dir == W:
				NEmask -= NEmask&S; SEmask -= SEmask&N
		last_tile_dir = S
		
	elif dir == Vector2(0,-1): # going UP
		SEmask |= N;SEmask -= SEmask&W
		SWmask |= N;SWmask -= SWmask&E
		NEmask |= S;NEmask -= NEmask&W
		NWmask |= S;NWmask -= NWmask&E
		
		if last_tile_dir == 0:
			if SEmask==N and SWmask==N:
				SEmask |= W; SWmask |= E
		elif last_tile_dir in [E,W]:
			SEmask |= W; SWmask |= E
			if last_tile_dir == E:
				NWmask -= NWmask&S; SWmask -= SWmask&N
			elif last_tile_dir == W:
				NEmask -= NEmask&S; SEmask -= SEmask&N
		last_tile_dir = N
		
	elif dir == Vector2(1,0): # going RIGHT
		SEmask |= W;SEmask -= SEmask&N
		SWmask |= E;SWmask -= SWmask&N
		NEmask |= W;NEmask -= NEmask&S
		NWmask |= E;NWmask -= NWmask&S
		
		if last_tile_dir == 0:
			if SWmask==E and NWmask==E:
				SWmask |= N; NWmask |= S
		elif last_tile_dir in [S,N]:
			SWmask |= N; NWmask |= S
			if last_tile_dir == S:
				NEmask -= NEmask&W; NWmask -= NWmask&E
			elif last_tile_dir == N:
				SEmask -= SEmask&W; SWmask -= SWmask&E
		last_tile_dir = E
		
	elif dir == Vector2(-1,0): # going LEFT
		SEmask |= W;SEmask -= SEmask&N
		SWmask |= E;SWmask -= SWmask&N
		NEmask |= W;NEmask -= NEmask&S
		NWmask |= E;NWmask -= NWmask&S
		
		if last_tile_dir == 0:
			if SEmask==W and NEmask==W:
				SEmask |= N; NEmask |= S
		elif last_tile_dir in [S,N]:
			SEmask |= N; NEmask |= S
			if last_tile_dir == S:
				NEmask -= NEmask&W; NWmask -= NWmask&E
			elif last_tile_dir == N:
				SEmask -= SEmask&W; SWmask -= SWmask&E
		last_tile_dir = W
	
	# save connection masks
	walls_grid[SEpos]=SEmask;walls_grid[SWpos]=SWmask;walls_grid[NWpos]=NWmask;walls_grid[NEpos]=NEmask
	# update tiles acording to walls_grid
	for npos in poss:
		var prop = get_wall_tile_properties(npos)
		tmap.set_cellv(npos,prop[0],prop[1],prop[2],prop[3])
	
	
	last_tile_pos = pos

func add_wall(global_pos):
	var pos = tmap.world_to_map(global_pos)
	if last_tile_pos != null and last_tile_pos == pos: # still on the same tile
		return
	var connection_mask = 0
	if walls_grid.has(pos):
		connection_mask = walls_grid[pos]
	if last_tile_pos != null:
		var dir = pos - last_tile_pos
		if dir.x == 1:
			connection_mask |= W
			walls_grid[last_tile_pos] |= E
		elif dir.x == -1:
			connection_mask |= E
			walls_grid[last_tile_pos] |= W
		elif dir.y == 1:
			connection_mask |= N
			walls_grid[last_tile_pos] |= S
		elif dir.y == -1:
			connection_mask |= S
			walls_grid[last_tile_pos] |= N
		var prop = get_wall_tile_properties(last_tile_pos)
		tmap.set_cellv(last_tile_pos,prop[0],prop[1],prop[2],prop[3])
	walls_grid[pos] = connection_mask
	
	var prop = get_wall_tile_properties(pos)
	tmap.set_cellv(pos,prop[0],prop[1],prop[2],prop[3])
	
	last_tile_pos = pos

func remove_wall( global_pos ):
	var pos = tmap.world_to_map(global_pos)
	if !walls_grid.has(pos):
		return
	var cmask = walls_grid[pos]
	if cmask&N:
		var npos = pos+Vector2(0,-1)
		if walls_grid.has(npos):
			walls_grid[npos] -= walls_grid[npos]&S
			var prop = get_wall_tile_properties(npos)
			tmap.set_cellv(npos,prop[0],prop[1],prop[2],prop[3])
	if cmask&S:
		var npos = pos+Vector2(0,1)
		if walls_grid.has(npos):
			walls_grid[npos] -= walls_grid[npos]&N
			var prop = get_wall_tile_properties(npos)
			tmap.set_cellv(npos,prop[0],prop[1],prop[2],prop[3])
	if cmask&W:
		var npos = pos+Vector2(-1,0)
		if walls_grid.has(npos):
			walls_grid[npos] -= walls_grid[npos]&E
			var prop = get_wall_tile_properties(npos)
			tmap.set_cellv(npos,prop[0],prop[1],prop[2],prop[3])
	if cmask&E:
		var npos = pos+Vector2(1,0)
		if walls_grid.has(npos):
			walls_grid[npos] -= walls_grid[npos]&W
			var prop = get_wall_tile_properties(npos)
			tmap.set_cellv(npos,prop[0],prop[1],prop[2],prop[3])
	
	walls_grid.erase(pos)
	tmap.set_cellv(pos,-1)


func prepare_walls_grid( SEpos ):
	var SWpos = SEpos - Vector2(1,0)
	var NWpos = SEpos - Vector2(1,1)
	var NEpos = SEpos - Vector2(0,1)
	
	var arr = [SEpos,SWpos,NWpos,NEpos]
	for pos in arr:
		if !walls_grid.has(pos):
			walls_grid[pos] = 0
	
	return arr

func add_object(item_data,pos):
	var tpos = tmap.world_to_map(pos + Vector2(0.5,0.5)*cell_size)
	if objects.has(tpos):
		return # there's already an object at this point
	var inst = item_data.scene.instance()
	if item_data.has("scene_vars"):
		for var_name in item_data.scene_vars:
			inst.set(var_name,item_data.scene_vars[var_name])
	pos = tmap.map_to_world(tpos)
	inst.set_pos( pos )
	var level = get_node("Level")
	level.get_node(item_data.path).add_child(inst)
	objects[tpos] = inst

func remove_object(pos):
	var tpos = tmap.world_to_map(pos + Vector2(0.5,0.5)*cell_size)
	if objects.has(tpos):
		objects[tpos].queue_free()
		objects.erase(tpos)

#func check_and_fix_previous(pos,dir):
#	var previous = pos-dir
#	if grid.has(previous):
#		var previous_mask = grid[previous]
#		if dir.x == 1 and previous_mask&E:
#			grid[pos] |= W
#		elif dir.x == -1 and previous_mask&W:
#			grid[pos] |= E
#		elif dir.y == 1 and previous_mask&S:
#			grid[pos] |= N
#		elif dir.y == -1 and previous_mask&N:
#			grid[pos] |= S
#		var prop = get_tile_properties(previous)
#		tmap.set_cellv(previous,prop[0],prop[1],prop[2],prop[3])

#func remove_path(global_pos):
#	return
#	var pos = tmap.world_to_map(global_pos)
#	if !grid.has(pos):
#		return
#	grid.erase(pos)
#	tmap.set_cellv(pos,-1)
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








#func get_tile_properties(pos):
#	var connect_mask = grid[pos] # direction mask for cells connected to checked one (ones you can walk to)
#	var walls_count = 4
#	for mask in [N,S,W,E]: # 1, 2, 8, 4
#		if connect_mask&mask:
#			walls_count -= 1
#	var prop = [-1,false,false,false]
#	var rot = 0
#	if walls_count == 0:
#		prop[0] = 0
#	elif walls_count == 1:
#		prop[0] = 1
#		if !connect_mask&W: # wall on the left
#			rot = 90
#		elif !connect_mask&N:
#			rot = 180
#		elif !connect_mask&E:
#			rot = 270
#	elif walls_count == 2:
#		if (connect_mask&N and connect_mask&S) or (connect_mask&W and connect_mask&E):
#			prop[0] = 3 # tunnel
#			if connect_mask&N: # vertical
#				rot = 90
#		else:
#			prop[0] = 2 # corner
#			if connect_mask&E:
#				if connect_mask&N:
#					rot = 90
#				else:
#					rot = 180
#			elif connect_mask&S and connect_mask&W:
#				rot = 270
#	elif walls_count == 3:
#		prop[0]=4
#		if connect_mask&E:
#			rot = 90
#		elif connect_mask&S:
#			rot = 180
#		elif connect_mask&W:
#			rot = 270
#	elif walls_count == 4:
#		prop[0] = 5
#	
#	return rotate_properties(prop,rot)

func get_wall_tile_properties(pos):
	var connect_mask = walls_grid[pos] # direction mask for cells connected to checked one (ones you can walk to)
	var walls_count = 0
	for mask in [N,S,W,E]: # 1, 2, 8, 4
		if connect_mask&mask:
			walls_count += 1
	var prop = [-1,false,false,false]
	var rot = 0
	if walls_count == 0:
		prop[0] = 1
	elif walls_count == 1:
		prop[0] = 2
		if connect_mask&W: # wall on the left
			rot = 90
		elif connect_mask&N:
			rot = 180
		elif connect_mask&E:
			rot = 270
	elif walls_count == 2:
		if (connect_mask&N and connect_mask&S) or (connect_mask&W and connect_mask&E):
			prop[0] = 4 # tunnel
			if connect_mask&N: # vertical
				rot = 90
		else:
			prop[0] = 3 # corner
			if connect_mask&E:
				if connect_mask&N:
					rot = 90
				else:
					rot = 180
			elif connect_mask&S and connect_mask&W:
				rot = 270
	elif walls_count == 3:
		prop[0]=5
		if !connect_mask&E:
			rot = 90
		elif !connect_mask&S:
			rot = 180
		elif !connect_mask&W:
			rot = 270
	elif walls_count == 4:
		prop[0] = 6
	
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







