extends Node2D

func _ready() -> void:
	$player.weapon = load("res://game/weapon/revolver/revolver.tscn").instantiate()
	$player.weapon.bullet_fired.connect(on_bullet_fired)
	$UI.player = $player


#func _process(_delta: float) -> void:
	#if Input.is_action_just_pressed("action_test"):
		#var ret = await RpcAwait.send_rpc(1, test_rpc.bind("a"))
		#print("returned: ", ret)
#
#
#@rpc("any_peer", "call_local")
#func test_rpc(data):
	#print(data)
	#return 1


func on_bullet_fired(direction: Vector2):
	var bala = $player.weapon.municion.instantiate()
	bala.position = $player.weapon.cannon.get_global_position()
	bala.shoot(direction, $player)
	add_child(bala)
