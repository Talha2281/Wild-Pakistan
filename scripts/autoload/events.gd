extends Node
## Global signal bus. Keeps UI, missions, audio and AI decoupled from each other.

## All values are 0..100 (health is normalised to the animal's max health).
## temp: 50 is comfortable, lower is cold, higher is hot.
signal stats_changed(hunger: float, thirst: float, health: float, stamina: float, temp: float)
signal damaged(amount: float)
signal player_died
signal player_revived
## 0..1. Drives the danger vignette and the dynamic audio mix.
signal danger_level_changed(level: float)
signal prompt_changed(text: String)
signal toast(text: String)
signal coins_changed(total: int)
signal missions_changed
signal weather_changed(weather: String)
signal time_changed(hour: float, day: int, season: String)
## 0..1 fraction of the ability cooldown that has elapsed (1 = ready).
signal ability_cooldown(fraction: float)
signal unlocked(what: String)

## Generic gameplay events consumed by MissionManager:
## drink, eat, hunt, dig, chase_escaped, shikari_lost, rescued, disarm, sabotage,
## summit, lookout, storm_survived, day_survived
signal game_event(event_name: String)
