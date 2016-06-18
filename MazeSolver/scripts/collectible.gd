
extends Area2D

export(String,"IncEnergy","ExtraScore") var type = "IncEnergy"
signal player_enter

func _ready():
	connect("body_enter",self,"_on_body_enter")
	add_to_group("Objects")
	add_to_group("Collectibles")

func _on_body_enter(body):
	if body.get_name() == "Player":
		emit_signal("player_enter",type,body)
		queue_free()


