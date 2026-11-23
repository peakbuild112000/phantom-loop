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

	# 6. No timer-driven transfer: 40 simulated seconds change nothing by themselves.
	main.call("_load_level", 0)
	var loops_before: int = main.get("_loops")
	var ghosts_before: int = (main.get("_recordings") as Array).size()
	for i in range(2400):
		main.call("_step", 1.0 / 60.0)
	print("NO_AUTO_TRANSFER=", main.get("_loops") == loops_before and (main.get("_recordings") as Array).size() == ghosts_before)

	# 7. A fourth transfer is a game over.
	for i in range(4):
		for j in range(4):
			main.call("_step", 1.0 / 60.0)
		main.call("_finish_loop")
	print("GAME_OVER=", main.get("_game_over"), " LEVEL_IDX=", main.get("_level_idx"))

	# 8. Walking through the door closes it and advances the sector automatically.
	main.call("_load_level", 0)
	main.set("_door_latched", true)
	player.global_position = Vector3(0.0, 1.0, -9.0)
	main.call("_step", 1.0 / 60.0)
	print("DOOR_CROSS_WON=", main.get("_won"), " TRANSITION=", main.get("_transition") > 0.0)
	main.call("_process", 0.5)
	print("AUTO_NEXT_LEVEL=", main.get("_level_idx") == 1)
	# 9. The mouse stays locked across the door transition (desktop) or keeps
	#    drag-look ready (web). Getting here with visible mode was the bug.
	var headless: bool = DisplayServer.get_name() == "headless"
	var mode_ok: bool = OS.has_feature("web") or headless or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	# The old bug released the pointer inside _win(); that must no longer happen.
	var not_released: bool = not bool(main.get("_mouse_released_by_user"))
	print("MOUSE_AFTER_LEVEL=", mode_ok, " NOT_RELEASED_ON_WIN=", not_released, " HEADLESS=", headless)
	quit()
