# Game structure and level flow

## Scene flow

`title_screen.tscn` is the project entry point. New Game clears session progress and opens `hub.tscn`. The hub unlocks the five challenge stages in order. Completing stages one through four returns to the hub with the next stage unlocked; completing `finale.tscn` opens `ending_screen.tscn`.

`GameFlow` is the single owner of stage paths, unlocked stage, current stage, and scene transitions. Progress is session-only and is not saved to disk, so the title screen omits Continue. Starting a new game always returns to the first stage. Restart reloads the active stage, which resets Wick's abilities, checkpoints, platforms, switches, gates, and hazards to their scene defaults.

## Challenge stages

1. **First Light** — jump between light-sensitive platforms.
2. **A Safe Place** — cross spike hazards and use checkpoints as recovery points.
3. **Across the Dark** — clear a gap that exceeds jump-only distance and requires a dash.
4. **Borrowed Flame** — use a clear flare to activate a one-shot switch and open a gate.
5. **The Last Wick** — combine hazards, checkpoints, light platforms, dash traversal, and a flare gate before the ending.

Each stage has its own scene and layout script and uses the shared `playable_level.gd` assembly helpers, existing Wick and puzzle scenes, and `level_controller.gd` for death, checkpoint, pause, and completion wiring. `test_level.tscn` remains the original mechanic regression scene.

## Controls and checks

- `A` / `D` or arrows: move; `Space`, `W`, or Up: jump.
- `Shift` or `X`: dash; `I` / `K` aim vertical dashes; `E` / `F`: flare.
- `Escape`: pause/resume during a challenge stage.

Dash duration is tuned to 0.22 seconds so the dash stage is crossable with a jump and dash while remaining too wide for a jump alone.

Run `godot --headless --path . --script res://tests/game_flow_smoke.gd` for title, progression, lock, reset, pause, restart, completion, and ending checks. Run `godot --headless --path . --script res://tests/ability_smoke.gd` for ability and puzzle regression checks.

Run `godot --headless --path . --script res://tests/stage_mechanics_smoke.gd` to verify the dash-required gap, closed-gate bypass prevention, flare activation, and physical exit reachability in the flare puzzle and finale.
