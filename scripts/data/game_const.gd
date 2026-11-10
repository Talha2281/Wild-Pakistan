class_name GameConst
extends RefCounted
## Shared constants: physics layers (as bit values) and misc tuning.

const LAYER_TERRAIN := 1
const LAYER_PLAYER := 2
const LAYER_ANIMAL := 4
const LAYER_SHIKARI := 8
const LAYER_AREA := 16

const GAME_VERSION := "1.0.0"

## One in-game day lasts this many real seconds.
const DAY_LENGTH := 180.0
## Days per season.
const SEASON_DAYS := 2
const SEASONS := ["spring", "summer", "autumn", "winter"]
