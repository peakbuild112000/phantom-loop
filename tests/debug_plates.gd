extends SceneTree

func _init() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var plates: Array = main.get("_plates")
	var player = main.get("_player")

	# 1. Plates + door: no physics frame between steps (deterministic check).
	var rec0: Array = []
	var rec1: Array = []
	for i in range(10):
		rec0.append({"pos": (plates[0] as Area3D).global_position + Vector3(0, 0.9, 0), "action": true})
		rec1.append({"pos": (plates[1] as Area3D).global_position + Vector3(0, 0.9, 0), "action": true})
	var recs: Array = main.get("_recordings")
	recs.append(rec0)
	recs.append(rec1)
	main.call("_reset_room")
	player.global_position = (plates[2] as Area3D).global_position + Vector3(0, 0.9, 0)
	for i in range(6):
		main.call("_step", 1.0 / 60.0)
	var active := []
	for p in plates:
		active.append((p as Area3D).has_meta("active") and (p as Area3D).get_meta("active"))
	print("PLATE_ACTIVE=", active)
	print("DOOR_LATCHED=", main.get("_door_latched"), " DOOR_VISIBLE=", (main.get("_door") as Node3D).visible)

	# 2. Spawn always faces the room (-Z), never the back wall.
	player.rotation.y = 2.5
	main.call("_reset_room")
	print("SPAWN_ROTATION_Y=", player.rotation.y)

	# 3. Ghost limit: repeated transfers never exceed MAX_GHOSTS recordings.
	for n in range(6):
		for i in range(4):
			main.call("_step", 1.0 / 60.0)
		main.call("_finish_loop")
	print("GHOST_LIMIT=", (main.get("_recordings") as Array).size())
	quit()
