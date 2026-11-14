extends Node
## Player profile, ranger rank, field-guide discoveries and leaderboards.
##
## Boards are kept locally (your personal top 10 per category). If
## res://config/online.cfg contains a Supabase URL and key, scores are also posted
## to an online table and the global board can be read. See docs/ONLINE_LEADERBOARD.md.

const RANKS := [
	{"name": "Trainee Ranger", "xp": 0},
	{"name": "Field Ranger", "xp": 150},
	{"name": "Senior Ranger", "xp": 450},
	{"name": "Wildlife Warden", "xp": 1000},
	{"name": "Chief Warden", "xp": 2200},
]

## id -> [title, ascending (lower is better), unit]
const BOARDS := {
	"survival": ["High Score - Wild Life", false, "pts"],
	"ranger": ["High Score - Ranger Patrol", false, "pts"],
	"discoveries": ["Species Discovered", false, "species"],
	"photo": ["Best Photo Rating", false, "pts"],
	"rescue": ["Fastest Rescue", true, "sec"],
	"arrests": ["Poachers Arrested", false, "arrests"],
}

const CONFIG_PATH := "res://config/online.cfg"

var online_url := ""
var online_key := ""


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		online_url = String(cfg.get_value("online", "url", "")).rstrip("/")
		online_key = String(cfg.get_value("online", "key", ""))
	if player_name() == "":
		set_name_value("Ranger%d" % (randi() % 9000 + 1000))
	Events.game_event.connect(_on_event)


func online_enabled() -> bool:
	return online_url != "" and online_key != ""


# ------------------------------------------------------------------- profile

func rec() -> Dictionary:
	return SaveManager.data["records"]


func player_name() -> String:
	return String(rec().get("name", ""))


func set_name_value(n: String) -> void:
	rec()["name"] = n.strip_edges().left(16)
	SaveManager.save_game()
	publish_web()


func xp() -> int:
	return int(rec().get("xp", 0))


func rank_index() -> int:
	var idx := 0
	for i in RANKS.size():
		if xp() >= int(RANKS[i]["xp"]):
			idx = i
	return idx


func rank_name() -> String:
	return String(RANKS[rank_index()]["name"])


## Returns {"have": xp into this rank, "need": xp for the next rank, "next": name} (need 0 at max).
func rank_progress() -> Dictionary:
	var i := rank_index()
	if i >= RANKS.size() - 1:
		return {"have": 0, "need": 0, "next": ""}
	var lo := int(RANKS[i]["xp"])
	var hi := int(RANKS[i + 1]["xp"])
	return {"have": xp() - lo, "need": hi - lo, "next": String(RANKS[i + 1]["name"])}


func add_xp(amount: int) -> void:
	var before := rank_index()
	rec()["xp"] = xp() + amount
	if rank_index() > before:
		Events.toast.emit("PROMOTED: %s! Reward +%d coins" % [rank_name(), 50 * rank_index()])
		SaveManager.add_coins(50 * rank_index())
		AudioManager.play_ui("combo")
	SaveManager.save_game()


func bump(key: String, amount := 1) -> void:
	rec()[key] = int(rec().get(key, 0)) + amount


func discovered() -> Dictionary:
	return rec()["discovered"]


func discovered_count() -> int:
	return discovered().size()


## Registers a photo. Returns true if the species is new to the field guide.
func register_photo(species: String, points: int) -> bool:
	bump("photos")
	if points > int(rec().get("best_photo", 0)):
		rec()["best_photo"] = points
	var d := discovered()
	var is_new := not d.has(species)
	if is_new or points > int(d[species]):
		d[species] = points
	if is_new:
		add_xp(40)
		SaveManager.add_coins(10 * Catalog.rarity(species))
	add_xp(maxi(2, points / 10))
	SaveManager.save_game()
	return is_new


func _on_event(e: String) -> void:
	match e:
		"arrest":
			bump("arrests")
			add_xp(60)
		"disarm":
			bump("snares")
			add_xp(25)
		"rescued":
			add_xp(80)
			var t := GameState.run_time
			var best := float(rec().get("fastest_rescue", 0.0))
			if best <= 0.0 or t < best:
				rec()["fastest_rescue"] = snappedf(t, 0.1)
				submit("rescue", snappedf(t, 0.1))
		"shikari_defeated":
			bump("poachers_defeated")
			add_xp(20)
		"animal_poached":
			bump("poached_total")
		"day_survived":
			add_xp(10)
		"evidence":
			add_xp(15)


# ---------------------------------------------------------------- leaderboards

func local_board(board: String) -> Array:
	var boards: Dictionary = SaveManager.data["boards"]
	return boards.get(board, [])


## Called at the end of a run.
func finish_run(mode: String, score: int) -> void:
	bump("runs")
	var hist: Array = SaveManager.data.get("history", [])
	hist.push_front({"mode": mode, "biome": GameState.biome_id, "animal": GameState.animal_id, "score": score,
		"t": int(Time.get_unix_time_from_system())})
	while hist.size() > 15:
		hist.pop_back()
	SaveManager.data["history"] = hist
	if mode == "survive":
		submit("survival", score)
	else:
		submit("ranger", score)
	submit("discoveries", discovered_count())
	submit("photo", int(rec().get("best_photo", 0)))
	submit("arrests", int(rec().get("arrests", 0)))
	SaveManager.save_game()
	publish_web()


## Mirrors boards + profile into the browser's localStorage so the landing page's
## "Hall of Rangers" can show them (same site, same browser).
func publish_web() -> void:
	if not OS.has_feature("web"):
		return
	var payload := {"name": player_name(), "rank": rank_name(), "xp": xp(), "boards": SaveManager.data["boards"],
		"history": SaveManager.data.get("history", []), "updated": int(Time.get_unix_time_from_system())}
	var js := JSON.stringify(JSON.stringify(payload))
	JavaScriptBridge.eval("try{localStorage.setItem('wp_hall',%s)}catch(e){}" % js)


func submit(board: String, value: float) -> void:
	if value <= 0.0 or not BOARDS.has(board):
		return
	var ascending: bool = BOARDS[board][1]
	var boards: Dictionary = SaveManager.data["boards"]
	var list: Array = boards.get(board, [])
	list.append({"name": player_name(), "value": value, "t": int(Time.get_unix_time_from_system())})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["value"]) < float(b["value"]) if ascending else float(a["value"]) > float(b["value"]))
	while list.size() > 10:
		list.pop_back()
	boards[board] = list
	publish_web()
	if online_enabled():
		_post_score(board, value)


func _headers() -> PackedStringArray:
	return PackedStringArray(["apikey: " + online_key, "Authorization: Bearer " + online_key, "Content-Type: application/json", "Prefer: return=minimal"])


func _post_score(board: String, value: float) -> void:
	var req := HTTPRequest.new()
	req.timeout = 10.0
	add_child(req)
	req.request_completed.connect(func(_r: int, _c: int, _h: PackedStringArray, _b: PackedByteArray) -> void: req.queue_free())
	var body := JSON.stringify({"board": board, "name": player_name(), "value": value})
	req.request(online_url + "/rest/v1/scores", _headers(), HTTPClient.METHOD_POST, body)


## Fetches the global top 20 for a board. callback(ok: bool, rows: Array).
func fetch_online(board: String, callback: Callable) -> void:
	if not online_enabled():
		callback.call(false, [])
		return
	var ascending: bool = BOARDS[board][1]
	var req := HTTPRequest.new()
	req.timeout = 10.0
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			callback.call(false, [])
			return
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		callback.call(parsed is Array, parsed if parsed is Array else []))
	var order := "asc" if ascending else "desc"
	req.request("%s/rest/v1/scores?board=eq.%s&order=value.%s&limit=20&select=name,value" % [online_url, board, order], _headers())
