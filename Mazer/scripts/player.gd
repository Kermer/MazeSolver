
extends KinematicBody2D

const speed = 150 # max speed
onready var sprite_size = get_node("Sprite").get_texture().get_size() * get_node("Sprite").get_scale() # used for view limit calculations
var limit = {} # camera limits
var movement = Vector2() # should have values between -1 and 1

func _ready():
	add_to_group("Players")

func set_process(val): # override
	set_fixed_process(val)

func set_movement(val): # called from 
	movement = val

func _fixed_process(delta):
	var motion = movement * speed * delta
	motion = clamp_to_limits(motion) 
	move(motion)
	
	if is_colliding(): # slideee
		var n = get_collision_normal()
		motion = n.slide(motion)
		move(motion)

# Stop the motion in specific axis if player would get out of screen
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

# This might get some changes soon
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

# Update single limit
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

