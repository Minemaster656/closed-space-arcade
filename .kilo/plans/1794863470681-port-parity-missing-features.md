# Port parity plan: Unity → Godot

Missing/incorrectly ported items from `SpaceShipEvolutionYG2` to fix.

## Scope
- Add asteroid HP bars
- Add ambient lighting (CanvasModulate / Environment)
- Add distance score counter (points)
- Add starting platform + launch animation
- Planet background: optional, deferred

Shop stays as separate scene (intentional, out of scope).

## Tasks

1. Asteroid HP bar
   - In `asteroid.tscn` / `Asteroid.tscn`, add a `ProgressBar` (or custom `TextureProgressBar`) child, anchored top-center, hidden until damaged.
   - In `asteroid.gd`, track `max_health`, update bar on `take_damage`, hide when full, remove on death.
   - Ensure pool reset restores bar visibility/state.

2. Ambient lighting
   - Add `CanvasModulate` node to `game.tscn` with a tint matching Unity URP ambient (sky/equator/ground blend). Or set `WorldEnvironment` if 3D; 2D → CanvasModulate.
   - Keep values configurable in `game.gd`.

3. Distance score counter
   - Track distance traveled by rocket (vertical position delta over time) in `game.gd`.
   - Add UI label (bottom or top) showing score; update each frame.
   - Persist best via existing save (optional, follow SAVE pattern later).

4. Starting platform
   - Add `start_platform` node/sprite at launch position in `game.tscn`.
   - Play launch animation (rocket rises from platform) on `_ready` before enabling control; reuse `GameStartAnimation` logic (planet optional).
   - Disable spawner until launch completes.

5. Planet background (deferred)
   - Mark as out of scope for this pass; note for later.

## Validation
- Run game scene, verify HP bars appear on hit, lighting tint visible, score increments, platform shows at start.
- Lint/typecheck if available.
