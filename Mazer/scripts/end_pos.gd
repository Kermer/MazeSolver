extends Area2D

signal player_enter

func _ready():
	connect("body_enter",self,"_on_body_enter")

func _on_body_enter(body):
	if body.is_in_group("Players"):
		emit_signal("player_enter",body)