# Asset pipeline

## Models
All animals and humans are built in code (`scripts/world/animal_model.gd`) from boxes. To replace one with a Blender model:
1. Model low-poly (under ~1500 tris), apply colour with vertex colours or a single small texture.
2. Name the nodes `Body`, `Head`, `LegFL`, `LegFR`, `LegBL`, `LegBR` so the shared animation works.
3. Export glTF 2.0 (.glb) to `assets/models/<species>.glb`, then load it from `AnimalModel.build()` when the file exists.

## Textures
Keep 512 px max, ETC2/ASTC compression for Android (Project Settings > Rendering > Textures).

## Audio
See `assets/audio/README.md`.

## Performance budget (mid-range phone)
- < 150 draw calls, < 200k triangles on screen
- Flora is MultiMesh; keep shadows off or low on "Low" quality
