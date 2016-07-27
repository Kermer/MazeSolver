
# This piece of code might be hard to understand and it was made with simple thought in mind:
#	You just insert new entries to 'DEFAULT' and 'mapp' and that's it. Now you can get and set it using just the name from 'mapp'

extends Node

var cfg = ConfigFile.new()
const path = "user://config.cfg"

var DEFAULT = {"me_last_path":"",
			"levels_completed":0,
			"all_levels_unlocked":false,
			"sound":true,"sound_volume":0.8,
			"music":true,"music_volume":0.8
		}
var mapp = {"me_path":["MapEditor","me_last_path"],
			"levels_completed":["Game","levels_completed"],
			"all_levels_unlocked":["Game","all_levels_unlocked"],
			"sound":["Game","sound"],"sound_volume":["Game","sound_volume"],
			"music":["Game","music"],"music_volume":["Game","music_volume"]
		}

func _init():
	cfg.load(path)
	check()


func reload():
	cfg.load(path)

func reset():
	cfg = ConfigFile.new()
	check()
	save(path)

func get_val( name, arg1=null ):
	if mapp.has(name.to_lower()):
		var pair = mapp[name.to_lower()]
		return cfg.get_value(pair[0],pair[1])
	elif arg1 != null and cfg.has_section_key(name, arg1):
		return cfg.get_value(name, arg1)
	return null

func set_val( arg0, arg1, arg2=null ):
	if arg2 == null:
		if mapp.has(arg0):
			var pair = mapp[arg0]
			if get_val(arg0) == arg1:
				return # nothing changed
			cfg.set_value(pair[0],pair[1],arg1)
	else:
		if cfg.get_value(arg0,arg1) == arg2:
			return # nothing changed
		cfg.set_value(arg0, arg1, arg2)
	cfg.save(path)

func check():
	for n in mapp:
		var pair = mapp[n]
		if !cfg.has_section_key(pair[0],pair[1]):
			set_default(pair[0],pair[1])
	cfg.save(path)


func set_default( section, key, s=false ):
	cfg.set_value( section, key, DEFAULT[key] )
	if s == true:
		cfg.save(path)


