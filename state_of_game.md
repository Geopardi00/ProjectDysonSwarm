# Project Dyson Swarm - State of Game

Last updated: 2026-05-06

## Current Prototype Status

Milestones 1-5 are implemented and Milestone 7 has an early art/UI pass in progress.

Working loop:

- Faction select screen lets the player choose USA, China, or EU.
- Strategy screen shows day, player faction, readiness, moonbase needs, CPU progress, news, and vehicle selection.
- Vehicle selection supports Big Rocket, Space Shuttle, and SpinLaunch.
- Cargo loading has two locked phases:
  - material assignment
  - packing
- Assignment groups pieces by shape but still assigns individual copies.
- Packing uses assigned individual piece instances.
- Only placed pieces count toward launch.
- Fuel is cargo and must be placed.
- Launch result feedback appears before returning to strategy.
- CPU competitors progress after time advances.
- Win/loss opens a game over screen.

## Locked Cargo Rules

- Do not change cargo rules casually.
- Do not change launch resolution rules.
- Do not allow returning from packing to assignment in the same turn.
- Fuel does not count toward moonbase readiness.
- If placed fuel is below vehicle.required_fuel, the launch crashes.
- Crashed launch cargo is lost and time still advances.
- Assigned but unplaced pieces are ignored.
- Empty cargo spaces are allowed.
- No 1-cell filler pieces.

## Vehicle Data

Big Rocket:

- Grid: 5x10 internally, displayed horizontally as 10x5.
- Max payload: 500.
- Required fuel: 200.
- Launch days: 30.
- Piece set: 10 base shapes, 2 copies each, 20 instances total.
- Base set totals 50 cells.

Space Shuttle:

- Grid: 4x8 internally, displayed horizontally as 8x4.
- Max payload: 320.
- Required fuel: 120.
- Launch days: 20.
- Piece set: 8 base shapes, 2 copies each, 16 instances total.
- Base set totals 32 cells.

SpinLaunch:

- Grid: 1x2.
- Max payload: 20.
- Required fuel: 0.
- Launch days: 5.
- Uses a simple capsule/block stub.

## Current Art/UI Pass

Assets live under:

```text
assets/ui/
```

Currently wired:

- Space background image on main and cargo screens.
- Faction logos on faction select.
- Vehicle icons on strategy vehicle cards.
- Material icons on assignment material buttons.
- Cargo piece images on assignment and packing lists.
- Panel textures for vehicle info, available cargo, and cargo hold.

Important UI helper:

```text
scripts/data/UiAssets.gd
```

This centralizes asset paths and provides text outline styling.

## Current Screen Layouts

Faction select:

- Shows title, faction logo cards, and start button.
- Faction choice is flavor only for now.

Strategy / vehicle selection:

- Left panel: day, player status, moonbase needs, CPU competitors, news.
- Right area: three vehicle cards.
- Vehicle stats are moving toward the lower part of each card.

Assignment:

- Left panel: selected piece/copy info, payload/fuel meters, material buttons, assigned summary, reset/confirm.
- Center: moonbase needs and cargo hold panel.
- Right panel: available cargo groups.
- ASCII piece previews have been removed from the visible list.

Packing:

- Left panel: placed manifest, warnings, payload/fuel info, launch.
- Center: cargo hold panel with functional clickable packing overlay.
- Right panel: assigned pieces to place plus rotate/clear controls.
- The scripted grid background has been removed so the panel art can carry the cargo hold.

## Known Rough Edges

- UI is still script-built. This is fast for iteration but not ideal for exact pixel placement.
- Final visual polish may be easier in Godot's 2D editor once the layout stops changing.
- Cargo hold panel art is used, but click/grid alignment may still need visual tuning.
- Material needs panel is text-first; it can later become icon/progress-bar based.
- Panel textures may still need exact padding and scale adjustments.
- Debug buttons are currently visible on the strategy screen.

## Useful Validation Commands

Run from the project root:

```powershell
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/CargoSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/CargoUiSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --quit-after 1 res://scenes/main/Main.tscn
```

Latest checks passed before this checkpoint:

- Cargo smoke test passed.
- Cargo UI smoke test passed.
- Main scene loaded headless.

## Suggested Next Steps

1. Playtest current visual pass and take screenshots.
2. Tune panel scale/padding and cargo hold click alignment.
3. Decide whether to move major UI placement into `.tscn` scenes for easier 2D-editor editing.
4. Hide or gate debug buttons.
5. Improve moonbase needs display using material icons.
6. Continue first visual pass before changing balance.
