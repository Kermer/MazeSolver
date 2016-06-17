extends Camera2D

func _ready():
	set_process_input(true)

var speed = 80
var zoom_speed = 0.8
func _input(event):
	if event.type == InputEvent.MOUSE_BUTTON and event.is_pressed():
		if event.button_index == BUTTON_WHEEL_DOWN:
			set_zoom( get_zoom()/zoom_speed )
		elif event.button_index == BUTTON_WHEEL_UP:
			set_zoom( get_zoom()*zoom_speed )
