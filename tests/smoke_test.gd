extends SceneTree

func _init() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var plates: Array = main.get("_plates")
	var player = main.get("_player")

	# 1. Automatic plates: two parked ghosts, no E / action flag.
	var rec0: Array = []
	var rec1: Array = []
	for i in range(10):
		rec0.append({"pos": plates[0]["pos"] + Vector3(0.0, 0.9, 0.0), "cls": 0})
		rec1.append({"pos": plates[1]["pos"] + Vector3(0.0, 0.9, 0.0), "cls": 0})
	var recs: Array = main.get("_recordings")
	recs.append(rec0)
	recs.append(rec1)
	main.call("_reset_room")
	player.global_position = plates[2]["pos"] + Vector3(0.0, 0.9, 0.0)
	for i in range(6):
		main.call("_step", 1.0 / 60.0)
	var active := []
	for p in plates:
		active.append(p["active"])
	print("PLATE_ACTIVE=", active)
	print("DOOR_LATCHED=", main.get("_door_latched"))

	# 2. Spawn always faces the room.
	player.rotation.y = 2.5
	main.call("_reset_room")
	print("SPAWN_ROTATION_Y=", player.rotation.y)

	# 3. Ghost limit.
	for n in range(6):
		for i in range(4):
			main.call("_step", 1.0 / 60.0)
		main.call("_finish_loop")
	print("GHOST_LIMIT=", recs.size())

	# 4. Sectors + class collision masks.
	print("LEVELS=", (main.get("_levels") as Array).size())
	main.call("_select_class", 3)
	print("PHASE_MASK=", player.collision_mask)
	main.call("_select_class", 0)
	print("NORMAL_MASK=", player.collision_mask)
	main.call("_advance_level")
	print("LEVEL1_PLATES=", (main.get("_plates") as Array).size(), " LEVEL_IDX=", main.get("_level_idx"))

	# 5. Magnet pulls the gold core in sector 3.
	main.call("_load_level", 2)
	main.call("_select_class", 1)
	var key = main.get("_key")
	var before: Vector3 = key.global_position
	for i in range(120):
		main.call("_step", 1.0 / 60.0)
	print("KEY_MOVED=", key.global_position.distance_to(before) > 1.0)
	quit()
