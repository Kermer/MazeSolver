
extends KinematicBody2D

const speed = 250
var sprite_size = Vector2()
var limit = {}

func _ready():
	sprite_size = get_node("Sprite").get_texture().get_size() * get_node("Sprite").get_scale()
#	set_darkness(false)
	get_tree().connect("screen_resized",self,"_screen_resized")
	add_to_group("Players")

func set_process(val): # override
	set_fixed_process(val)

func _fixed_process(delta):
	var dir = Vector2(0,0)
	var actions = { "ui_left":Vector2(-1,0), "ui_right":Vector2(1,0), "ui_up":Vector2(0,-1), "ui_down":Vector2(0,1) }
	for ac in actions:
		if Input.is_action_pressed(ac):
			dir += actions[ac]
	
	var motion = dir.normalized() * speed * delta
	motion = clamp_to_limits(motion)
	move(motion)
	
	if is_colliding():
		var n = get_collision_normal()
		motion = n.slide(motion)
		move(motion)

func clamp_to_limits(motion):
	if limit.size() < 3:
		return motion
	var target_pos = get_pos()+motion
	var size = sprite_size/2
	if target_pos.x - size.x <= limit["left"]:
		motion.x = 0
	elif target_pos.x + size.x >= limit["right"]:
		motion.x = 0
	if target_pos.y + size.y >= limit["bottom"]:
		motion.y = 0
	elif limit.has("top") and target_pos.y - size.y <= limit["top"]:
		motion.y = 0
	return motion

func set_limits(left,right,bottom,top=null):
	var camera = get_node("Camera")
	limit["left"] = left
	camera.set_limit(MARGIN_LEFT,left)
	limit["right"] = right
	camera.set_limit(MARGIN_RIGHT,right)
	limit["bottom"] = bottom
	camera.set_limit(MARGIN_BOTTOM,bottom)
	if top == null and limit.has("top"):
		limit.erase("top")
		camera.set_limit(MARGIN_TOP,-10000000)
	elif top != null:
		limit["top"] = top
		camera.set_limit(MARGIN_TOP,top)

func update_limit(name,val):
	if !(name in ["left","right","bottom","top"]):
		return
	var camera = get_node("Camera")
	limit[name] = val
	if name == "left":
		camera.set_limit(MARGIN_LEFT,val)
	elif name == "right":
		camera.set_limit(MARGIN_RIGHT,val)
	elif name == "bottom":
		camera.set_limit(MARGIN_BOTTOM,val)
	elif name == "top":
		camera.set_limit(MARGIN_TOP,val)



#func set_darkness(val,size=null):
#	if typeof(size) == TYPE_VECTOR2:
#		var scale = size / get_node("Darkness").get_texture().get_size()
#		get_node("Darkness").set_scale(scale)
#	if val == true:
#		get_node("Darkness").show()
#		get_node("Light").set_enabled(true)
#	else:
#		get_node("Darkness").hide()
#		get_node("Light").set_enabled(false)

#func _toggle_darkness():
#	if get_node("Darkness").is_hidden():
#		get_node("Darkness").show()
#		get_node("Light").set_enabled(true)
#	else:
#		get_node("Darkness").hide()
#		get_node("Light").set_enabled(false)

func _screen_resized():
	pass
#	var window_size = OS.get_window_size()
#	var scale = window_size / get_node("Darkness").get_texture().get_size()
#	get_node("Darkness").set_scale(scale)
