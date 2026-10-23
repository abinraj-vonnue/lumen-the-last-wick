# Player abilities test notes

## Controls

- Move: `A` / `D` or left / right arrows
- Jump: `Space`, `W`, or Up arrow
- Dash: `Shift` or `X`; aim horizontally with left / right, vertically with `I` / `K`, or diagonally with both
- Flare: `E` or `F`

`W` and Up remain jump-only. `I` and `K` provide vertical dash aim so a jump input cannot unintentionally turn a dash upward. Dash falls back to Wick's facing direction when no aim key is held.

Dash lasts 0.18 seconds at 620 pixels per second and has a 0.45 second cooldown by default. It is available once per airborne turn, then refreshes on landing or checkpoint activation. A collision only ends it when Wick is moving into that collision surface; moving along a ceiling or floor does not cancel a horizontal dash.

## Flare puzzle rules

The flare lasts 0.55 seconds, has a 2.5 second cooldown, and adds 180 pixels to light-platform activation and deactivation distances. With the default platform settings, those limits are 480 and 510 pixels during the flare, preserving the 30 pixel hysteresis gap. When the flare ends, active platforms return to their normal deactivation distance and fade out if the lantern is too far away. The flare increases the lantern's rendered scale and energy as feedback; platform logic still uses distance and line-of-sight raycasts.

The test-level flare switch is deliberately a one-shot trigger. A flare that starts within 420 pixels and has a clear ray to the switch latches it on and permanently opens its connected gate. A flare blocked by geometry or started out of range does not activate it; a later flare can still succeed.

## Runtime smoke test

Run `godot --headless --path . --script res://tests/ability_smoke.gd`. The test covers directional dash, wall and ceiling/floor collision recovery, cooldown, flare range thresholds and expiry, switch line-of-sight and one-shot behavior, gate collision, death/respawn, and the existing level flow.

To play the sequence, press F5. Jump and dash across the spikes, touch the checkpoint, then press E near the diamond switch. The tall gate should open before Wick reaches the exit.
