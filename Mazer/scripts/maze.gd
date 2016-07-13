
extends Navigation2D

const N=1; const S=2; const E=4; const W=8

var WIDTH=0
var HEIGHT=0
var SEED=0

# for our TileMap parts creation:
const tileset = preload("res://resources/maze_tileset.tres")
export(int,8,128) var cell_size = 64 # export means it can be edited via Inspector
export(float) var tilemap_scale = 0.5
export(int,0,6) var max_parts = 3
var parts = []
var player = null
var create_next_part_at = null
# and pathfinding
var display_path = []

# these vars are stored for further generations
var LAST_POS = 0 # Y
var LAST_SET = []
var LAST_ROW = [] # this will be used to connect last row of previous part to newly generated part


func get_size():
	return Vector2(WIDTH,HEIGHT)
func get_cell_size():
	return cell_size
func get_tilemap_scale():
	return tilemap_scale
func get_tileset():
	return tileset
func get_level_name():
	return "Endless"

func _ready():
#	generate_new(width,height)
#	get_node("../End").set_global_pos(Vector2(width/2*cell_size*tilemap_scale,-99999))
#	show_path()
#	var start_pos = Vector2(6,0.5)*cell_size*tilemap_scale
#	var end_pos = Vector2(width-1,height-1)*cell_size*tilemap_scale
#	var end_pos = Vector2(width-6,height-0.5)*cell_size*tilemap_scale
#	get_node("../Start").set_pos(start_pos)
#	get_node("../End").set_pos(end_pos)
#	var path = get_simple_path(start_pos,end_pos)
#	display_path = path
#	update()
#	print("Path size: ",path.size())
#	print(tileset.get_tiles_ids())
#	set_process_input(true)
	pass

func generate(height,width=null,mseed=0):
	if width == null:
		width = Globals.get("display/width")/cell_size +1
	generate_new(width,height,mseed)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		generate_next_part()
#	elif event.type == InputEvent.MOUSE_BUTTON and event.is_pressed():
#		var mpos = get_global_mouse_pos()
#		mpos.x = int(mpos.x);mpos.y = int(mpos.y)
#		mpos.x = mpos.x - (int(mpos.x) % int(cell_size*tilemap_scale)) + 0.5*cell_size*tilemap_scale
#		mpos.y = mpos.y - (int(mpos.y) % int(cell_size*tilemap_scale)) - 0.5*cell_size*tilemap_scale
#		if event.button_index == 1:
#			get_node("../Player").set_global_pos(mpos)
#			show_path()
#		elif event.button_index == 2:
#			get_node("../End").set_global_pos(mpos)
#			show_path()

func show_path():
	var from = get_node("../Player").get_global_pos()
	var to = Vector2()
#	var to = get_node("../End").get_global_pos()
	display_path = get_simple_path(from,to)
#	print(display_path.size())
	update()

func generate_new(width,height,mseed=0):
	clean_up()
	if width < 4 or height < 4:
		dprint(str("generate_new(): too small size given (",width,"x",height,")"))
		return
	var timestamp = OS.get_ticks_msec() # lets check how long everything will take to complete
	# save the args
	WIDTH = int(width)
	HEIGHT = int(height)
	LAST_POS = -HEIGHT
	if mseed == 0: # no seed given
		randomize()
		mseed = 1 + randi() % 65535 # from 1, since 0 is random
	SEED = mseed
	dprint(str("Generating ",width,"x",HEIGHT," maze with seed=",mseed," ..."))
	seed(mseed)
	
	generate_next_part()
	generate_next_part()
	generate_next_part()
	create_next_part_at = parts[1].get_pos().y

	dprint(str("Done in ",OS.get_ticks_msec()-timestamp,"ms"))
	set_process(true)

func _process(delta):
	if create_next_part_at == null:
		return
	if player.get_global_pos().y < create_next_part_at:
		var bot_limit = parts[0].get_global_pos().y
		generate_next_part()
		create_next_part_at = parts[1].get_pos().y
		player.update_limit("bottom",bot_limit)

func generate_next_part(height=HEIGHT):
	dprint(str("Adding ",WIDTH,"x",height," TileMap part."))
#	var grid = eller(WIDTH,height)
#	create_map_part(grid)
	var grid = eller_inverted(WIDTH,height)
	create_map_part(grid,true)
	pass

func clean_up():
	WIDTH = 0
	HEIGHT = 0
	SEED = 0
	LAST_POS = 0
	LAST_SET = []
	parts = []
	for c in get_children():
		if c extends TileMap:
			c.queue_free()

# Eller's Algorithm. Currently using "eller_inverted()" func instead
func eller(width,height):
	var grid = new_grid(width,height)
	if grid.size() < 3 or grid[0].size() < 3:
		return
	var size = Vector2(width,height)
	var sets = range(size.x)
	if !LAST_SET.empty():
#		sets = LAST_SET
		for x in range(size.x):
			grid[0][x] += E | W
	for y in range(size.y):
#		print("======== Y: ",y)
		for x in range(size.x-1):
#			print("X: ",x)
			if ( y == size.y-1 or (randi()%2 == 1) ) and sets[x] != sets[x+1]:
				sets[x+1] = sets[x]
				grid[y][x] |= E # add E to our connections maskgrid[y][x] |= E
#				grid[y][x] += E # add E to our connections maskgrid[y][x] |= E
				grid[y][x+1] |= W # add W ...
#				grid[y][x+1] += W # add W ...
		if y != size.y-1:
			var next_sets = range(y*size.x, (y+1)*size.x)
			var all_sets = clear_sets(sets)
			var have_moved = []
			while( all_sets != have_moved ):
				for x in range(size.x):
					var rand
					# decrease chance of getting long paths on the sides
					if x==0 or x==1 or x==size.x-1 or x==size.x-2:
						rand = randi()%10
					else:
						rand = randi()%4
					if ( (!rand) and !(sets[x] in have_moved) ):
						have_moved.append(sets[x])
						next_sets[x] = sets[x]
						grid[y][x] |= S
#						grid[y][x] += S
						grid[y+1][x] |= N
#						grid[y+1][x] += N
				have_moved = clear_sets(have_moved)
			if y == size.y-2:
				LAST_SET = get_fresh_last_set(sets) # global var
			sets = next_sets
	
#	LAST_ROW = []
#	for x in range(size.x):
#		LAST_ROW.append(grid[size.y-2][x])
	
	return grid

func eller_inverted(width,height):
	var grid = new_grid(width,height)
	if grid.size() < 3 or grid[0].size() < 3:
		return
	var size = Vector2(width,height)
	var sets
	if LAST_SET.empty():
		sets = range(size.x)
	else:
		sets = LAST_SET
		for x in range(size.x):
			grid[size.y-1][x] += E | W
	var i = 0
	for y in range(size.y-1,-1,-1):
		for x in range(size.x-1):
#			print("X: ",x)
			if ( y == 0 or (randi()%2 == 1) ) and sets[x] != sets[x+1]:
				sets[x+1] = sets[x]
				grid[y][x] |= E # add E to our connections maskgrid[y][x] |= E
#				grid[y][x] += E # add E to our connections maskgrid[y][x] |= E
				grid[y][x+1] |= W # add W ...
#				grid[y][x+1] += W # add W ...
		if y > 0:
			var next_sets = range(i*size.x, (i+1)*size.x)
			var all_sets = clear_sets(sets)
			var have_moved = []
			while( all_sets != have_moved ):
				for x in range(size.x):
					var rand
					# decrease chance of getting long paths on the sides
					if x==0 or x==1 or x==size.x-1 or x==size.x-2:
						rand = randi()%10
					else:
						rand = randi()%4
					if ( (!rand) and !(sets[x] in have_moved) ):
						have_moved.append(sets[x])
						next_sets[x] = sets[x]
						grid[y][x] |= N
#						grid[y][x] += S
						grid[y-1][x] |= S
#						grid[y+1][x] += N
				have_moved = clear_sets(have_moved)
			if y == 1:
				LAST_SET = get_fresh_last_set(sets) # global var
			sets = next_sets
		i += 1
	
#	LAST_ROW = []
#	for x in range(size.x):
#		LAST_ROW.append(grid[size.y-2][x])
	
	return grid

# converts sets like [124,243,243,243] to [1,2,2,2]
func get_fresh_last_set(from):
	var index_map = {}
	var new_set = []
	var idx = 0
	for i in range(from.size()):
		var set_id = from[i]
		if index_map.has(set_id):
			new_set.append(index_map[set_id])
		else:
			new_set.append(idx)
			index_map[set_id] = idx
			idx += 1
	return new_set

# cleans up Array from duplicate entries and sorts it
func clear_sets( sets ):
	var new_set = []
	for val in sets:
		if new_set.find(val) == -1:
			new_set.append(val)
	new_set.sort()
	return new_set

# returns [Y][X] grid ( Array )
func new_grid(size_x,size_y):
	var grid = []
	grid.resize(size_y)
	for y in range(size_y):
		var arr = []
		arr.resize(size_x)
		grid[y] = arr
		for x in range(size_x):
			grid[y][x] = 0 # set everything to 0
	return grid

# adds another part of the maze
func create_map_part(grid,inverted=false):
	var tmap = TileMap.new()
	tmap.set_light_mask(1)
	tmap.set_tileset(tileset)
	tmap.set_scale(Vector2(tilemap_scale,tilemap_scale))
	tmap.set_pos(Vector2(0,LAST_POS*tilemap_scale*cell_size))
	
	var size = Vector2(grid[0].size(),grid.size())
	
	for y in range(size.y):
		for x in range(size.x):
			var connect_mask = grid[y][x] # direction mask for cells connected to checked one (ones you can walk to)
			var masks = [1,2,4,8] # N S E W
			var dir = [Vector2(0,-1),Vector2(0,1),Vector2(1,0),Vector2(-1,0)] # direction as X,Y
			var wall_dir = []+dir # copy array. If you would do wall_dir = dir you would get just reference
			# ^ it will tell us which type of TileMap cell to use: how many adjacent walls and from which directions
			# (it's passed to get_wall_properties() later on)
			for i in range(4):
				var xx = x+dir[i].x;var yy = y+dir[i].y
				if xx<0 or xx>size.x-1: # left and right borders
					# we want to keep this wall
					continue
				if yy<0 or yy>size.y-1: # top and bottom borders
					wall_dir.erase(dir[i]) # we don't want these
					continue
				var mask = masks[i]
				if !(connect_mask&mask==mask):
					continue # this is wall for sure
				var neighbor = grid[yy][xx]
				var nmask
				if mask == 1 or mask == 4:
					nmask = mask*2
				else:
					nmask = mask/2
				if !(neighbor&nmask==nmask):
					continue # this is wall for sure
				# if this cell is connected with some other cell - delete wall connection between those
				wall_dir.erase(dir[i])
			
			var properties = get_tile_properties(wall_dir) # tile_id, flip_x, flip_y, transpose
			tmap.set_cell(x,y,properties[0],properties[1],properties[2],properties[3]) # tile_id, flip_x, flip_y, transpose
	
	# add left and right border
	var x = -1
	for y in range(size.y):
		tmap.set_cell(x,y,1,false,true,true)
	x = size.x
	for y in range(size.y):
		tmap.set_cell(x,y,1,true,false,true)
	
	parts.append(tmap)
	add_child(tmap)
	if inverted:
		LAST_POS -= size.y-1
	else:
		LAST_POS += size.y-1
	
	if parts.size() > max_parts:
		# free/remove oldest part
		var part_to_erase = parts[0]
		part_to_erase.queue_free()
		parts.remove(0)
	
#	show_path()




# this function checks how many walls and from which direction we want to connect in some cell
# then returns proper tile_id, flip_x, flip_y and transpose of that cell
# it's just shitload of simple logic
func get_tile_properties(dir):
	var counter = dir.size()
	var prop = [1,false,false,false]
	if counter == 0:
		prop[0]=0
	elif counter == 1:
		prop[0]=1
		if dir[0].y == 1: # below
			pass
		elif dir[0].y == -1: # above
			prop[1]=true;prop[2]=true
		elif dir[0].x == 1: # right
			prop[2]=true;prop[3]=true
		elif dir[0].x == -1: # left
			prop[1]=true;prop[3]=true
	elif counter == 2:
		if dir[0].x == -dir[1].x or dir[0].y == -dir[1].y: # line
			prop[0]=3
			if abs(dir[0].y) == 1: # vertical
				pass
			else: # horizontal
				prop[1]=true;prop[3]=true
		else: # corner
			prop[0]=2
			# another wall is ...
			var up = (dir[0].y==-1 or dir[1].y==-1)
			var down = (dir[0].y==1 or dir[1].y==1)
			var left = (dir[0].x==-1 or dir[1].x==-1)
			var right = (dir[0].x==1 or dir[1].x==1)
			if down&&left:
					prop[1]=true
			elif up:
				prop[2]=true
				if right:
					prop[3]=true
				else:
					prop[1]=true
	elif counter == 3:
		prop[0]=4
		# another wall is ...
		var up = (dir[0].y==-1 or dir[1].y==-1 or dir[2].y==-1)
		var down = (dir[0].y==1 or dir[1].y==1 or dir[2].y==1)
		var left = (dir[0].x==-1 or dir[1].x==-1 or dir[2].x==-1)
		var right = (dir[0].x==1 or dir[1].x==1 or dir[2].x==1)
		if down&&left&&up:
			prop[1]=true;prop[3]=true
		elif left&&up&&right:
			prop[1]=true;prop[2]=true
		elif up&&right&&down:
			prop[2]=true;prop[3]=true
				
	elif counter == 4:
		prop[0]=5
	
	return prop

#func get_wall_tile_properties(pos):
#	var connect_mask = walls_grid[pos] # direction mask for cells connected to checked one (ones you can walk to)
#	var walls_count = 0
#	for mask in [N,S,W,E]: # 1, 2, 8, 4
#		if connect_mask&mask:
#			walls_count += 1
#	var prop = [-1,false,false,false]
#	var rot = 0
#	if walls_count == 0:
#		prop[0] = 1
#	elif walls_count == 1:
#		prop[0] = 2
#		if connect_mask&W: # wall on the left
#			rot = 90
#		elif connect_mask&N:
#			rot = 180
#		elif connect_mask&E:
#			rot = 270
#	elif walls_count == 2:
#		if (connect_mask&N and connect_mask&S) or (connect_mask&W and connect_mask&E):
#			prop[0] = 4 # tunnel
#			if connect_mask&N: # vertical
#				rot = 90
#		else:
#			prop[0] = 3 # corner
#			if connect_mask&E:
#				if connect_mask&N:
#					rot = 90
#				else:
#					rot = 180
#			elif connect_mask&S and connect_mask&W:
#				rot = 270
#	elif walls_count == 3:
#		prop[0]=5
#		if !connect_mask&E:
#			rot = 90
#		elif !connect_mask&S:
#			rot = 180
#		elif !connect_mask&W:
#			rot = 270
#	elif walls_count == 4:
#		prop[0] = 6
#	
#	return rotate_properties(prop,rot)
#
#
#func rotate_properties(prop,rot):
#	if rot == 0:
#		return prop
#	if rot == 90:
#		prop = [prop[0],true,false,true]
#	elif rot == 180:
#		prop = [prop[0],true,true,false]
#	elif rot == 270:
#		prop = [prop[0],false,true,true]
#	return prop

func get_tilemap_size(tmap):
	var csize = tmap.get_cell_size()
	var quadrant = tmap.get_quadrant_size()
	var tmap_rect = tmap.get_item_rect()
	print("RECT: ",tmap_rect)
	return tmap_rect.size



func _draw():
	var col = Color(1,0,0,0.8)
	for i in range(display_path.size()-1):
		var from = display_path[i]
		var to = display_path[i+1]
		draw_line(from,to,col,2)






# for our own "debug print"
func dprint( s ):
	s = str(s)
	print("[maze.gd] ",s)
