
extends Control

const SELECT_DISABLED = -1
# check Tree constants
const SELECT_SINGLE = 0
const SELECT_ROW = 1
const SELECT_MULTI = 2


const N=1; const S=2; const E=4; const W=8

const tree_items = [
	{"name":"Dynamic Tiles","tip":"Tiles which adjust to adjacent tiles","children":[
		{"name":"Maze Path","selectable":true,"tip":"Base of each maze"}
		]
	},
	{"name":"Objects","tip":"Placeable items with possible unique properties","children":[
		{"name":"Collectibles","tip":"Triggering some action when walked-on","children":[
			{"name":"Increase Energy","tip":"Increases Energy on pickup","selectable":true}
			]
		}
		]
	},
	{"name":"Environment","tip":"Objects (and more) affecting gameplay","children":[
		{"name":"Start Pos","tip":"Point where player will spawn","selectable":true},
		{"name":"End Pos","tip":"Step here to finish the level","selectable":true}
		]
	}
	]

const items_preview = {
	"Maze Path":{"tex":preload("res://map_editor/previews/path.png")},
	"Start Pos":{"tex":preload("res://map_editor/previews/start_pos.png"),"scale":Vector2(0.5,0.5)},
	"Increase Energy":{"tex":preload("res://map_editor/previews/increase_energy.png")}
	}


# Selection tree related
var selectable_items = [] # this will be auto-filled
var selected_item = ""
onready var item_tree = get_node("CL/ItemSelection")
signal item_selected
# TileMap edition related
onready var obj_preview = get_node("Level/ObjectPreview")
var cell_size = 64
var move_speed = 600
var zoom_speed = 0.8
var grid = {}
var mouse_drag = 0 # 0-none 1-LMB 2-RMB
var last_tile_pos = null
var WIDTH = 0
var HEIGHT = 0
onready var tmap = get_node("Level/TileMap")




var DEFAULT_ICON = null

func _ready():
	init()
	DEFAULT_ICON = get_icon("Node")
	item_tree.connect("item_collapsed",self,"_titem_collapsed")
	item_tree.connect("cell_selected",self,"_titem_selected")
	item_tree.connect("item_activated",item_tree,"hide")
	connect("item_selected",self,"_item_selected")
	pass

func init():
	fill_tree()
	get_node("Camera").make_current()
	set_process(true)

func set_process(val): # override
	.set_process(val)
	set_process_unhandled_input(val)

# ========================================
#  Item Selection Tree
# ========================================
func fill_tree():
	item_tree.clear()
	selectable_items.clear()
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
	if item_data.has("selectable"):
		selectable_items.append( item_data.name )
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
	if item_name in selectable_items:
		if selected_item != item_name:
			selected_item = item_name
			emit_signal("item_selected",item_name)
			print("item selected: ",item_name)

func toggle_selection_window():
	if item_tree.is_hidden():
		item_tree.show()
	else:
		item_tree.hide()
#func show_selection_window(pos=null):
#	if typeof(pos) != TYPE_VECTOR2:
#		pos = get_global_mouse_pos()
#	var selector = get_node("CL/ItemSelection")
#	var selector_size = selector.get_size()
#	var window_size = OS.get_window_size()
#	if pos.x + selector_size.x > window_size.x:
#		pos.x = window_size.x-selector_size.x
#	if pos.y + selector_size.y > window_size.y:
#		pos.y = window_size.y-selector_size.y
#	selector.set_global_pos(pos)
#	selector.show()

func get_packed_level(level_name):
	var level = get_node("Level").duplicate()
	var nav = Navigation2D.new()
	level.replace_by( nav, true )
	level = nav
	var start_pos = Position2D.new()
	start_pos.set_name("StartPos"); start_pos.set_pos(level.get_node("StartPos").get_pos())
	level.get_node("StartPos").replace_by( start_pos )
	level.remove_child( level.get_node("ObjectPreview") )
	level.set_script(null)
	level.set_name(level_name)
	var packed_scene = PackedScene.new()
	level.set_meta("level_name",level_name)
	level.set_meta("level_grid",grid)
	level.set_meta("level_size",Vector2(WIDTH,HEIGHT))
	recursive_set_owner(level,level)
	packed_scene.pack(level)
	return packed_scene

func recursive_set_owner(owner,node):
	for child in node.get_children():
		child.set_owner(owner)
		recursive_set_owner(owner,child)


# ========================================
#  (mostly) TileMap related
# ========================================
func _unhandled_input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		var mpos = get_node("Level").get_local_mouse_pos()
		if obj_preview.is_visible():
			if mpos.x > 0 and mpos.y > 0:
#				mpos.x = int(mpos.x)/cell_size*cell_size;mpos.y = int(mpos.y)/cell_size*cell_size
#				mpos += Vector2(cell_size/2,cell_size/2)
				mpos = tmap.map_to_world(tmap.world_to_map(mpos)) + Vector2(cell_size,cell_size)/2
#				obj_preview.set_global_pos( mpos )
				obj_preview.set_pos( mpos )
				if selected_item == "Maze Path":
					if mouse_drag == 1:
						place_item()
					elif mouse_drag == 2:
						remove_item()
	elif event.type == InputEvent.MOUSE_BUTTON:
		if event.button_index == 2:
			if event.is_pressed():
				remove_item()
				mouse_drag = 2
				set_process_input(true)
		elif event.button_index == 1:
			if event.is_pressed():
				mouse_drag = 1
				place_item()
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
	if selected_item == "":
		return
	if global_pos==null:
		global_pos = get_node("Level").get_local_mouse_pos()
	
	if selected_item == "Maze Path":
		add_path(global_pos)
		pass
	elif selected_item == "Start Pos":
		global_pos = tmap.map_to_world(tmap.world_to_map(global_pos)) + Vector2(cell_size,cell_size)/2
		get_node("Level/StartPos").set_pos( global_pos )

func remove_item(global_pos=null):
	if global_pos==null:
		global_pos = get_node("Level").get_local_mouse_pos()
	
	if selected_item == "Maze Path":
		remove_path(global_pos)

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

func _item_selected( iname ):
	var tex = null
	var scale = Vector2(1,1)
	if items_preview.has( iname ):
		var ipreview = items_preview[iname]
		tex = ipreview.tex
		if ipreview.has("scale"):
			scale = ipreview.scale
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






