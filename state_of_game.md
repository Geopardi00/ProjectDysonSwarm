# Project Dyson Swarm - State of Game

Last updated: 2026-05-08

## Current Prototype Status

Milestones 1-5 are implemented and Milestone 7 has an editor-driven art/UI pass in progress.

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
- Cargo piece images on editor-placeable assignment slots and packing lists.
- Empty panel textures for vehicle info / available cargo style panels.
- Vehicle-specific cargo hold panel textures for Big Rocket, Space Shuttle, and SpinLaunch.
- Strategy screen, cargo loading screen, cargo grid view, and cargo hold panel are now scene-backed for easier 2D editor placement.

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
- Vehicle card names, icons, and stat labels are manually placeable in `StrategyScreen.tscn`.
- Vehicle stat text uses separate labels: payload, fuel needed, days to launch, cargo grid.
- `StrategyVehicleIconPlacementPreview.tscn` exists as a small tuning scene for vehicle-card placement.

Assignment:

- Left panel: selected piece image preview, copy buttons, payload/fuel meters, material buttons, per-material assigned-unit labels.
- Material buttons and their assigned-unit labels are hand-placeable in the 2D editor.
- Center: moonbase needs and manually placeable cargo hold panel.
- Right panel: available cargo groups use fixed, editor-placeable icon slots with no runtime text.
- ASCII piece previews have been removed from the visible list.
- Reset/confirm buttons live under the center cargo hold panel.

Packing:

- Left panel: placed manifest, warnings, payload/fuel info.
- Center: manually placeable cargo hold panel with functional clickable packing overlay.
- Right panel: assigned pieces to place plus rotate/clear controls.
- Launch button lives under the center cargo hold panel.
- Assignment and packing cargo hold panel positions are independently hand-tunable but currently matched.

## Known Rough Edges

- Some UI is still generated dynamically, especially cargo piece list buttons and copy buttons.
- Large layout surfaces are now scene/editor-backed, but exact pixel polish is still in progress.
- Cargo hold panel art and click/grid alignment have been tuned for Big Rocket but may need verification for Shuttle and SpinLaunch.
- Material needs panel is text-first; it can later become icon/progress-bar based.
- Panel textures may still need exact padding and scale adjustments.
- Debug buttons are currently visible on the strategy screen.

## Useful Validation Commands

Run from the project root:

```powershell
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/CargoSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/CargoUiSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/StrategyScreenSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --quit-after 1 res://scenes/main/Main.tscn
```

Latest checks passed before this checkpoint:

- Cargo smoke test passed.
- Cargo UI smoke test passed.
- Strategy screen smoke test passed.
- Main scene loaded headless during this visual pass.

## Suggested Next Steps

1. Playtest current visual pass and take screenshots.
2. Verify cargo hold panel/grid alignment for Shuttle and SpinLaunch.
3. Continue tuning exact panel positions in `.tscn` scenes.
4. Hide or gate debug buttons.
5. Improve moonbase needs display using material icons.
6. Continue first visual pass before changing balance.
