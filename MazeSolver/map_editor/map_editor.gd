
extends Control

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	var children = get_node("CL/StartMenu").get_children() + get_node("CL/EscMenu").get_children()
	for c in children:
		if c extends Button:
			c.connect("pressed",self,"_on_"+c.get_name()+"_pressed")
	var fdialog = get_node("CL/FileDialog")
	fdialog.set_access(FileDialog.ACCESS_FILESYSTEM)
	fdialog.set_mode(FileDialog.MODE_SAVE_FILE)
	fdialog.add_filter("*.tscn");fdialog.add_filter("*.xscn");fdialog.add_filter("*.xml")
	fdialog.connect("file_selected",self,"_save_level")
	if Config.get_val("me_path") != "":
		fdialog.set_current_dir(Config.get_val("me_path"))
	

func show_menu():
	get_node("CL/EscMenu").show()

func _on_BNew_pressed():
	pass

func _on_BSave_pressed():
	get_node("CL/FileDialog").popup()
	pass

func _on_BContinue_pressed():
	get_node("CL/EscMenu").hide()
	get_node("EditorWindow").set_process(true)

func _save_level(path):
	Config.set_val("me_path",path.get_base_dir())
	var rs = ResourceSaver
	var level_name = get_node("CL/EscMenu/LevelName").get_text()
	var packed_level = get_node("EditorWindow").get_packed_level(level_name)
	
	var err = rs.save(path,packed_level)
	if err != OK:
		print("FAILED TO SAVE!")
	else:
		print("SAVED!")

