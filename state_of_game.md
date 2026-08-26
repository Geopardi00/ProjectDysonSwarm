# Project Dyson Swarm - State of Game

Last updated: 2026-08-25

## Current Prototype Status

Milestones 1-5 are implemented and Milestone 7 has an editor-driven art/UI pass in progress.

Working loop:

- Opening screen shows the title logo over the space background with Start, Options, and Exit Game buttons.
- Options provides persistent live master, music, SFX, and brightness controls plus a scrollable How To Play page.
- Faction select screen lets the player choose USA, China, or EU before starting and also provides Options and Exit Game controls.
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
- Title logo on the opening screen and as a small upper-left overlay during normal game screens.
- Title logo asset, opening-screen logo size, and upper-left overlay logo size/position have been retuned during the current visual pass.
- Faction logos on faction select, with hover/selected highlight treatment.
- Vehicle icons on strategy vehicle cards.
- Material icons on assignment material buttons.
- Cargo piece images on editor-placeable assignment slots and packing lists.
- Empty panel textures for vehicle info / available cargo style panels.
- Vehicle-specific cargo hold panel textures for Big Rocket, Space Shuttle, and SpinLaunch.
- Assignment now presents the live moonbase material requirements inside `empty_panel02.png` above the cargo hold; panel and text X/Y positions are independently Inspector-tunable.
- Successful and failed launches use centered native-size illustrated panels (`launch_succesful_panel.png` and `launch_failure_panel.png`), with result details inside and Continue beneath; both outcomes share the same Inspector-tunable panel/text X/Y positions.
- Victory and defeat use centered native-size illustrated panels (`race_won_panel.png` and `race_lost_panel.png`), with game-over details inside and Play/Try Again plus Main Menu beneath; both outcomes share Inspector-tunable panel/text X/Y positions.
- Options and How To Play share the centered `panel_options.png` artwork at 85% opacity over the normal space background.
- Background music and sound effects use separate Music and SFX audio buses with independently persisted Options sliders.
- Buttons play shared hover/click sounds and use global hover/press tweens; hover playback has a small Inspector-tunable random pitch variation, while cargo material-assignment buttons intentionally keep sounds without tweens.
- The opening glitch effect has a synchronized glitch sound.
- Gameplay screens provide an `Esc` pause overlay with Resume, Options, Quit to Menu, and Exit Game controls.
- Strategy screen, cargo loading screen, cargo grid view, and cargo hold panel are now scene-backed for easier 2D editor placement.
- Strategy vehicle cards have an editor-tuned layout pass with manually placed titles, icons, stat labels, and buttons.
- Launch result and game-over screens now lower their text content below the upper-left logo overlay.

Important UI helper:

```text
scripts/data/UiAssets.gd
```

This centralizes asset paths and provides text outline styling.

## Current Screen Layouts

Opening / options:

- Opening buttons are stacked Start, Options, and Exit Game beneath the title logo.
- The opening title, button dimensions, and gaps have Inspector controls with matching editor/runtime placement.
- Options changes master, music, and SFX volume plus fullscreen brightness live, selects Easy/Medium/Hard difficulty, and saves them to `user://settings.cfg`.
- Difficulty changes apply to the next match. Hard preserves the original CPU pace; Easy and Medium slow CPU progress, increase crash chance, and make rivals favor Shuttle and SpinLaunch missions.
- How To Play opens inside the same options panel and documents the faction-neutral goal, cargo flow, controls, and launch outcomes.
- Back and `Esc` return from instructions to Options and from Options to the opening menu.

Faction select:

- Reached after the opening screen start button.
- Shows the upper-left title logo, centered faction logos, a small "Select faction" prompt, and a Start/Options/Exit Game stack below.
- No faction is selected by default.
- Start is disabled/greyed out until the player selects a faction.
- Hovering a faction logo slightly enlarges, brightens, and halos it.
- The selected faction keeps the same highlight treatment.
- Options returns to faction selection without losing the current faction choice.
- Faction choice is flavor only for now.

Global button feedback:

- All standard buttons receive center-pivoted hover/press scale and brightness tweens, including buttons created dynamically at runtime.
- Tween scale, brightness, and timing values are exposed on the Main scene under the Button Tween Inspector category.
- Existing authored button scales are preserved without shifting their resting positions.
- Assignment material buttons (Fuel, Carbon Metals, Silicon, Copper, Electronics, Rare Metals, and Propellant) are excluded from tweens so their dense layout remains stable.

Strategy / vehicle selection:

- Left panel: day, player status, readiness, moonbase needs, and CPU competitors.
- Center area: three independently positionable vehicle cards.
- Right panel: independently scrollable news feed constrained inside the panel's dark content area.
- Vehicle card names, icons, and stat labels are manually placeable in `StrategyScreen.tscn`.
- Vehicle stat text uses separate labels: payload, fuel needed, days to launch, cargo grid.
- Status, news, and vehicle-card text sizes and positions have Inspector controls with live editor preview.
- `StrategyVehicleIconPlacementPreview.tscn` exists as a small tuning scene for vehicle-card placement.
- Current vehicle-card pass uses fixed/manual placement to keep icon, stat, and button positions stable.
- The visible debug row includes test launch-failure and launch-success buttons in addition to news and forced-win controls.

Assignment:

- The Back button is an independent top-right overlay, so its width, height, font size, and margins can be tuned without moving assignment content.
- Left panel: selected piece image preview, copy buttons, payload/fuel meters, material buttons, per-material assigned-unit labels.
- Payload, fuel, and warning text have Inspector-controlled font size and character spacing for readability.
- Selected assignment piece preview tints to the selected copy's assigned material color at 68% opacity.
- Material buttons and their assigned-unit labels are hand-placeable in the 2D editor.
- Center: moonbase needs inside a dedicated 85%-opacity panel above the manually placeable cargo hold panel.
- Moonbase panel and text X/Y positions are independently exposed under the Cargo Loading Screen Inspector settings.
- Right panel: available cargo groups use fixed, editor-placeable icon slots with no runtime text.
- Assignment cargo group icons are centered inside their slot rectangles; slot rectangles can be hand-placed and the list scrolls from their positions.
- ASCII piece previews have been removed from the visible list.
- Reset/confirm buttons live under the center cargo hold panel.

Packing:

- Left panel: selected piece preview, payload/fuel meters, and a lower placed-manifest section.
- Selected packing piece preview tints to the selected piece's assigned material color at 68% opacity and shows material/unit text below it.
- Packing meter labels, bars, warning text, material buttons, icons, unit labels, and row spacing mirror the assignment panel geometry for consistent typography and alignment.
- Packing material icons are integrated into their buttons so icon/text alignment matches assignment; the scene's former overlay icon nodes remain hidden.
- Center: manually placeable cargo hold panel with functional clickable packing overlay.
- Right panel: assigned pieces to place render as centered, tinted block previews with no visible text.
- Cargo hold grid display is horizontally mirrored to match the side-panel piece orientation while keeping the underlying grid data unchanged.
- A moving-piece preview colors each free cell gray and each overlapping occupied cell red, so partial collisions are readable cell by cell.
- Selected pieces rotate with `R` or the mouse wheel while the pointer is over the cargo grid; wheel up rotates clockwise and wheel down rotates counterclockwise.
- Clear placements and launch buttons live under the center cargo hold panel.
- Assignment and packing cargo hold panel positions are independently hand-tunable but currently matched.

Launch result / game over:

- The upper-left logo remains a separate overlay.
- Successful and failed launches each use their matching centered 812x781 panel at native resolution and 85% opacity.
- Both launch outcomes share title/detail positioning in the upper readable area and the same controls under `Launch Result Panel Layout`.
- The launch-result Continue button sits below the panel and follows panel X/Y adjustments.
- Victory and defeat each use their matching centered 812x781 race panel at native resolution and 85% opacity.
- Both game-over outcomes share title/detail positioning and the same controls under `Game Over Panel Layout`.
- Play/Try Again and Main Menu sit in a centered row beneath the race panel and follow panel X/Y adjustments.

## Known Rough Edges

- Some UI is still generated dynamically, especially packing piece preview buttons and copy buttons.
- Large layout surfaces are now scene/editor-backed, but exact pixel polish is still in progress.
- Cargo hold panel art and click/grid alignment have been tuned for Big Rocket but may need verification for Shuttle and SpinLaunch.
- Material needs panel is text-first; it can later become icon/progress-bar based.
- Panel textures may still need exact padding and scale adjustments.
- Debug buttons are currently visible on the strategy screen.
- `esc_gear.png` and `button_hover2.wav` are present in the asset tree but are not currently wired into runtime UI/audio.

## Useful Validation Commands

Run from the project root:

```powershell
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/CargoSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/CpuDifficultySmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/CargoUiSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/StrategyScreenSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/LaunchFailurePanelSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/GameOverPanelSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/OpeningCutsceneSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/OptionsMenuSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/PauseMenuSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/UiSoundSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://scripts/tests/ButtonTweenSmokeTest.gd
& 'C:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --quit-after 1 res://scenes/main/Main.tscn
```

Latest checks passed before this checkpoint:

- CPU difficulty smoke test passed.
- Cargo smoke test passed.
- Cargo UI smoke test passed.
- Strategy screen smoke test passed.
- Launch result panel smoke test passed for successful and failed outcomes.
- Game over panel smoke test passed for victory and defeat outcomes.
- Opening cutscene smoke test passed.
- Options menu smoke test passed.
- Pause menu smoke test passed.
- UI sound smoke test passed.
- Button tween smoke test passed.
- Main scene loaded headless during this visual pass.
- 2026-05-22 checkpoint: Cargo UI smoke test passed after cargo grid display mirroring.
- 2026-05-22 checkpoint: Main scene loaded headless after launch-result and game-over layout tuning.
- 2026-08-23 checkpoint: Added the persistent Options/How To Play flow, Start/Options/Exit opening stack, fullscreen brightness control, and opening-layout parity.
- 2026-08-23 checkpoint: Split strategy status and news into left/right panels, constrained scrolling and readiness content, and added editor-previewable positioning/font controls.
- 2026-08-23 checkpoint: Improved cargo text/icon readability and separated the Back button from the cargo content layout; its Inspector controls now apply in editor and runtime without shifting assignment content.
- 2026-08-23 checkpoint: Added Music/SFX routing and Options sliders, global UI hover/click sounds, the opening glitch sound, and an `Esc` gameplay pause/options flow.
- 2026-08-23 checkpoint: Added Options/Exit Game to faction selection and global hover/press button tweens with stable handling for pre-scaled controls.
- 2026-08-23 checkpoint: Matched packing meter, warning, manifest-button, icon, unit-label, and row geometry to the assignment panel.
- 2026-08-25 checkpoint: Added the assignment moonbase-needs panel with independent panel/text positioning, refreshed cargo-hold artwork, and made partial packing overlaps readable per cell.
- 2026-08-25 checkpoint: Added the illustrated failed-launch panel with independent panel/text positioning, placed Continue beneath it, and added strategy debug buttons for failed and successful launch results.
- 2026-08-25 checkpoint: Added subtle Inspector-tunable random pitch variation to repeated button-hover playback.
- 2026-08-25 checkpoint: Added illustrated successful-launch, race-won, and race-lost panels; launch outcomes share one layout, game-over outcomes share another, and all action buttons sit beneath their panels.
- 2026-08-26 checkpoint: Added bidirectional mouse-wheel rotation for selected packing pieces while preserving `R` and isolating wheel input to the cargo grid so the piece list still scrolls normally.
- 2026-08-26 checkpoint: Added saved Easy/Medium/Hard settings that apply on the next match, with difficulty-specific CPU pace, crash risk, vehicle selection, and vehicle-aware news.

## Suggested Next Steps

1. Playtest current visual pass and take screenshots.
2. Verify cargo hold panel/grid alignment for Shuttle and SpinLaunch.
3. Continue tuning exact panel positions in `.tscn` scenes.
4. Hide or gate debug buttons.
5. Improve moonbase needs display using material icons.
6. Continue first visual pass before changing balance.
