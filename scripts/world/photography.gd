class_name Photography
extends RefCounted
## Ranger camera. Rates the best subject in frame (framing, distance, rarity) and
## records it in the field guide. A poacher in frame counts as evidence.

const MAX_DIST := 50.0


static func snap(player: PlayerAnimal) -> void:
	var cam := player.get_viewport().get_camera_3d()
	if cam == null:
		return
	Events.photo_flash.emit()
	AudioManager.play_ui("click")
	var rect := player.get_viewport().get_visible_rect()
	var center := rect.size * 0.5
	var half_diag := center.length()
	var space := player.get_world_3d().direct_space_state

	var best_species := ""
	var best_pts := 0
	for group in ["animals", "dolphins"]:
		for n in player.get_tree().get_nodes_in_group(group):
			var a := n as Node3D
			if a == null or bool(a.get("dead")):
				continue
			var sp := String(a.get("species"))
			var pts := _rate(cam, space, rect, center, half_diag, a.global_position + Vector3.UP * 0.6, Catalog.rarity(sp), sp, group == "dolphins")
			if pts > best_pts:
				best_pts = pts
				best_species = sp

	var evidence := false
	for n in player.get_tree().get_nodes_in_group("shikari"):
		var s := n as ShikariAI
		if s == null:
			continue
		if _rate(cam, space, rect, center, half_diag, s.global_position + Vector3.UP * 1.0, 3, "", false) > 0:
			evidence = true
			break

	if evidence:
		GameState.add_score(GameState.POINTS["evidence"], "evidence")
		Events.game_event.emit("evidence")
		Events.toast.emit("Evidence photo of a poacher taken!")

	if best_species == "":
		if not evidence:
			Events.toast.emit("No wildlife in frame. Point the camera at an animal.")
		return

	var stars := clampi(1 + best_pts / 25, 1, 5)
	var is_new := Records.register_photo(best_species, best_pts)
	Events.game_event.emit("photo")
	GameState.add_score(best_pts, "photo")
	var star_text := "*".repeat(stars)
	var label := Catalog.species_name(best_species)
	if is_new:
		AudioManager.play_ui("combo")
		Events.toast.emit("NEW SPECIES: %s  %s (%d pts)  [%d/%d discovered]" % [label, star_text, best_pts, Records.discovered_count(), Catalog.total_species()])
	else:
		AudioManager.play_ui("chime", -4.0)
		Events.toast.emit("Photo: %s  %s (%d pts)" % [label, star_text, best_pts])


## 0 if the subject is not visible, otherwise 1..100.
static func _rate(cam: Camera3D, space: PhysicsDirectSpaceState3D, rect: Rect2, center: Vector2, half_diag: float, pos: Vector3, rarity: int, _species: String, skip_terrain_check := false) -> int:
	if cam.is_position_behind(pos):
		return 0
	var dist := cam.global_position.distance_to(pos)
	if dist > MAX_DIST:
		return 0
	var sp := cam.unproject_position(pos)
	if not rect.grow(-20.0).has_point(sp):
		return 0
	if not skip_terrain_check:
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, pos, GameConst.LAYER_TERRAIN)
		if not space.intersect_ray(q).is_empty():
			return 0
	var framing := 1.0 - clampf(sp.distance_to(center) / (half_diag * 0.7), 0.0, 1.0)
	var dist_score := 1.0
	if dist < 6.0:
		dist_score = dist / 6.0
	elif dist > 22.0:
		dist_score = clampf(1.0 - (dist - 22.0) / 28.0, 0.0, 1.0)
	return maxi(5, int(100.0 * (0.4 * framing + 0.25 * dist_score + 0.35 * float(rarity) / 5.0)))
