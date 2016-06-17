
extends Area2D

export(String,"IncEnergy","ExtraScore") var type = "IncEnergy"

func _ready():
	connect("area_enter",self,"_on_pickup")

func _on_pickup(body):
	if body.get_name() == "Player":
		pass


