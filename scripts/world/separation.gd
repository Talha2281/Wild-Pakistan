class_name Separation
extends RefCounted
## Soft body collision between creatures so fighting animals stand side by side
## instead of sliding through each other. Returns a push direction (length 0..n).


static func push(me: Node3D, radius: float, tree: SceneTree, ignore: Node3D = null) -> Vector3:
	var out := Vector3.ZERO
	var others: Array = tree.get_nodes_in_group("animals")
	others.append_array(tree.get_nodes_in_group("shikari"))
	if GameState.player != null and is_instance_valid(GameState.player):
		others.append(GameState.player)
	for n in others:
		var o := n as Node3D
		if o == null or o == me or o == ignore:
			continue
		var to := me.global_position - o.global_position
		to.y = 0.0
		var r := radius + float(o.get_meta("sep_r", 0.55))
		var d := to.length()
		if d >= r:
			continue
		if d < 0.01:
			to = Vector3(randf() - 0.5, 0.0, randf() - 0.5)
			d = 0.01
		out += to / d * clampf((r - d) / r, 0.0, 1.0)
	return out
