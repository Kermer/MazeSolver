
extends Sprite

var is_active = -1 # holds the index of finger used for movement
var value = Vector2() setget value_setter # value_setter calls 'value_changed' signal

signal value_changed

func _ready():
	hide()
	set_process_unhandled_input(true)

func _unhandled_input(ev):
	if ev.type == InputEvent.SCREEN_TOUCH:
		if ev.is_pressed():
			if is_active == -1:
				is_active = ev.index
				activate(ev.pos)
		else:
			if ev.index == is_active:
				deactivate()
	elif ev.type == InputEvent.SCREEN_DRAG:
		if ev.index == is_active:
			set_value(ev.pos)

# display it
func activate(pos):
	set_pos(pos)
	get_node("S").set_pos(Vector2())
	show()

# hide it
func deactivate():
	is_active = -1
	self.value = Vector2()
	hide()

# interpret drag position to X and Y -1 to 1 values
const drag_mult = 0.5
var tex_size = get_texture().get_size()
func set_value(ev_pos):
	var diff = ev_pos - get_pos()
	var dir = diff.normalized()
	var sscale = get_scale()
	var max_radius = tex_size.x*sscale.x / 2
	diff *= drag_mult
	if diff.length() > max_radius: # limit the radius
		diff = dir*max_radius
	get_node("S").set_pos(diff/sscale) # set the 2nd circle position
	self.value = diff / max_radius # -1:1

func value_setter(val):
	emit_signal("value_changed",val)

# In case you don't want to connect the signal :P
func get_value():
	return value
