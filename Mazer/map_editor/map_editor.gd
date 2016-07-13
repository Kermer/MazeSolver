
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
	fdialog = get_node("CL/LoadDialog")
	fdialog.set_access(FileDialog.ACCESS_FILESYSTEM)
	fdialog.set_mode(FileDialog.MODE_OPEN_FILE)
	fdialog.add_filter("*.tscn");fdialog.add_filter("*.xscn");fdialog.add_filter("*.xml")
	fdialog.connect("file_selected",self,"_load_level")
	if Config.get_val("me_path") != "":
		fdialog.set_current_dir(Config.get_val("me_path"))
	
	for c in get_children():
		if c.has_method("hide"):
			c.hide()
	get_node("CL/StartMenu").show()
	

func show_menu():
	get_node("CL/EscMenu").show()

func _on_BNew_pressed():
	get_node("CL/StartMenu").hide()
	get_node("CL/EscMenu").hide()
	get_node("EditorWindow").clear_level()
	get_node("EditorWindow").show()
	get_node("EditorWindow").set_process(true)
	pass

func _on_BLoad_pressed():
	get_node("CL/LoadDialog").popup()
	pass
#	get_node("StartMenu").hide()
#	get_node("EditorWindow").load_level(
#	get_node("EditorWindow").set_process(true)

func _on_BSave_pressed():
	get_node("CL/FileDialog").popup()
	pass

func _on_BContinue_pressed():
	get_node("CL/EscMenu").hide()
	get_node("EditorWindow").set_process(true)

func _save_level(path):
	var dir_path = path.get_base_dir()
	Config.set_val("me_path",dir_path)
	get_node("CL/LoadDialog").set_current_dir(dir_path)
	var rs = ResourceSaver
	var level_name = get_node("CL/EscMenu/LevelName").get_text()
	var packed_level = get_node("EditorWindow").get_packed_level(level_name)
	
	var err = rs.save(path,packed_level)
	if err != OK:
		print("FAILED TO SAVE!")
	else:
		print("SAVED!")

func _load_level(path):
	var dir_path = path.get_base_dir()
	Config.set_val("me_path",dir_path)
	get_node("CL/FileDialog").set_current_dir(dir_path)
	var level = load(path).instance()
	print("Loading level: \"",path,"\"")
	get_node("CL/StartMenu").hide()
	get_node("CL/EscMenu").hide()
	get_node("EditorWindow").load_level(level)
	get_node("EditorWindow").set_process(true)
	get_node("EditorWindow").show()

