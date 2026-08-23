# Chicken Mama Egg Slinger — Godot 4.7 Vertical Slice

A portrait 2D prototype with faux-2.5D depth. No imported assets are required.

## Run

Open this folder in Godot 4.7.1 and press **F6/F5**, or run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

## Controls

- Hold and drag the mouse, or drag one finger: smooth horizontal movement
- `F1`: show/hide Chicken Mama's attack lane
- `R`: restart

Chicken Mama attacks automatically only when a wolf is inside the narrow lane directly ahead. Eggs are unlimited.

Chicken Mama has three shared hearts. Wolves follow fixed paths while distant, then chase and pounce only at close range. Each normal-wolf hit removes one heart, with a brief invulnerability window. After ten normal wolves are defeated, spawning stops; once the field is clear, the slower 10-HP Wolf Boss appears. A boss contact is an immediate defeat.

## Tuning points

- `ChickenMama.tscn`: follow speed, attack width/range, release timing, attack interval
- `WolfSpawner` in `Main.tscn`: spawn bounds and interval range
- `Wolf.tscn`: HP, far/near speed, far/near scale
- `EggProjectile.tscn`: flight duration and arc height

Placeholder characters use `_draw()` so the project stays self-contained. The gameplay scripts already isolate animation intent (`start_attack()` → timed `release_egg()`), target selection (`find_best_target()`), trajectory, hit handling, and spawning, making future sprite replacement straightforward.
