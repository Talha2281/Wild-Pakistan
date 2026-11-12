# Wild Pakistan – The Last Wilderness

A stylized 3D wildlife survival and conservation game for Android, built in **Godot 4.3+ (GDScript, Mobile renderer)**.
Play as a Pakistani animal, survive the seasons, and protect your wilderness from Shikari (poachers).

## What is in the game
- **5 biomes:** Thar Desert, Indus River Plains (2 missions, river + Indus dolphins), Ziarat Juniper Forest (3), Deosai Plains (5), Northern Mountains (7).
- **4 playable animals:** Chinkara (start), Suleiman Markhor (3 missions), Snow Leopard (8), Himalayan Brown Bear (12). Each has its own stats, ability, attack and skins.
- **Survival:** hunger, thirst, health, stamina and body temperature; dens and cover for shelter.
- **Environment:** day/night cycle, four seasons, weather (clear, wind, rain, storm, snow, blizzard, sandstorm), lightning and thunder.
- **Wildlife AI:** FSM-driven predators, prey and territorial animals, herd alarm calls, carcasses, a working food chain and ecosystem respawn.
- **Shikari:** sight and hearing, footprint tracking, nets and rifles, snares and camps you can sabotage, trapped animals to rescue.
- **29 missions**, coins, skins, journal with animal facts, saved progress.
- **Audio:** all sounds are synthesized at runtime (positional 3D, weather and danger reactive ambience). Drop `.ogg` files into `assets/audio/` to override any of them.
- **Touch controls** (joystick, drag-look camera, action buttons); keyboard and mouse work on desktop (WASD, Shift, E, Space, F, Q, Esc).
- **Rewarded ads:** a facade (`AdManager`) is included but disabled (`ADS_ENABLED = false`) until retention is validated.

## Run it
1. Install **Godot 4.3 or newer** (standard build).
2. Open this folder as a project (`project.godot`) and press **F5**.

## Smoke test (recommended first step)
```
godot --headless --path . -s tests/smoke_test.gd
```
Loads every biome with every animal, simulates input, cycles weather and seasons, and synthesizes all sounds. Check the output for `FAIL:` and `SCRIPT ERROR`.

## New in this version
- **Menu:** animated 3D menu with a big pulsing **PLAY NOW** button (starts instantly) and a **START GAME** button pinned at the bottom of the animal screen so it can never scroll out of view.
- **Faster, more engaging play:** 30% faster movement, 2-minute days, glowing **spirit orbs** (gold ones heal), a **combo multiplier** (up to x10) fed by orbs, eating, drinking, hunting and rescues, milestone coin bonuses, best score, and a **PLAY AGAIN** screen.
- **Sound:** background music (menu and in-game), orb/combo chimes, and audio that restarts on the first click/tap so browsers never leave the game silent. Music volume is in Settings.
- **Landing page (`landing/`):** a free real-time 3D scroll flythrough (Thar, Ziarat, Northern Mountains) with a PLAY button. The GitHub workflow publishes it at the site root and the game at `/game/`.

## Ranger, records and leaderboards
- **3 modes** (menu > Choose game mode): Wild Life (play an animal), Ranger Patrol (dart and arrest poachers, free trapped animals and the stranded Indus dolphin, remove snares; lose 6 animals and the patrol fails) and Photo Safari (no poachers, photograph wildlife).
- **Poachers hunt wildlife and defend themselves**, and animals (predators and territorial ones) fight back against them. Any animal can hit a poacher.
- **Field guide:** 19 species with conservation status; photo star ratings (framing, distance, rarity).
- **Profile:** name, rank/XP (Trainee Ranger to Chief Warden), coins, arrests, rescues, photos, fastest rescue.
- **Leaderboards:** local top 10 for score, ranger score, species discovered, best photo, fastest rescue and arrests. A **global** board needs a one-time free backend: see `docs/ONLINE_LEADERBOARD.md`. There is no anti-cheat.
- **Not built yet:** a playable dolphin (the dolphin is photographed and rescued, not played).

## Export as a web game (HTML5)
The project uses the Compatibility renderer, which is what web export requires.
1. Editor > Manage Export Templates > Download and Install.
2. Project > Export > the **Web** preset (already set up) > **Export Project** to `build/web/game/index.html`.
3. Web builds cannot be opened by double-clicking. Test locally with `python3 -m http.server -d build/web 8000` and open http://localhost:8000 , or in Godot use Project > Export > Remote Debug > Run in Browser.
4. To publish: zip the contents of `build/web` and upload to itch.io (kind of project: HTML, "play in browser"), or to any static host.
Thread support is off so it works on any host. Audio starts after the first click (browser rule). Saves use browser storage, so clearing site data erases progress.

## Export to Android
1. Editor > Manage Export Templates > download for your Godot version.
2. Install Android SDK and JDK 17, then set paths in Editor Settings > Export > Android.
3. Project > Export > Add > Android. Enable "Use Gradle Build" only if you add plugins (e.g. AdMob).
4. Create a keystore (`keytool -genkey -v -keystore wild.keystore -alias wild -keyalg RSA -validity 10000`) and set it in the preset.
5. Export APK/AAB. Package name suggestion: `pk.wildpakistan.lastwilderness`.

## Honest status
- The CI smoke test loads every biome in all modes headlessly; it checks for crashes, not for fun. The previews job renders screenshots to the `previews` branch. Gameplay balance of the ranger and poacher systems has not been playtested by a human.
- Models are procedural low-poly placeholders; sounds are synthesized. See `docs/ASSET_PIPELINE.md`.
- Ads are stubbed. Multiplayer is intentionally not built (see `docs/ROADMAP.md`).

## Git workflow
```
git init && git add . && git commit -m "Wild Pakistan full game"
```
Use feature branches (`feature/<name>`), and keep `.godot/` and export folders out of version control.

## Layout
```
scripts/autoload   global singletons (events, state, save, audio, missions, ads)
scripts/data       animals, species, biomes, constants
scripts/world      terrain, decor, interactables, environment, level assembler
scripts/player     player, camera, survival stats
scripts/ai         wildlife and Shikari AI
scripts/ui         HUD, menu, settings, touch controls
scripts/audio      runtime sound synthesis
tests/             headless smoke test
```
