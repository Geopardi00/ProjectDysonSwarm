# Project Dyson Swarm — V1.0 Design Document

## 1. Project overview

**Project Dyson Swarm** is a 2D puzzle/strategy game built in **Godot 4.6**.

The player represents one space power racing against two CPU-controlled competitors to complete a moonbase. The moonbase is needed as the first step toward building a Dyson swarm.

The core gameplay combines:

1. Strategic choice of launch vehicle.
2. Material assignment to cargo pieces.
3. Spatial cargo-packing puzzle.
4. Moonbase construction progress.
5. Race against CPU factions.
6. News-flash events that create tension and flavor.

The first playable version should be a **10–15 minute match**.

The goal of V1.0 is not a full commercial game. The goal is a **complete, playable prototype loop** with placeholder visuals.

---

## 2. Target tools and workflow

### Engine

- Godot 4.6
- GDScript
- PC first

### Development workflow

- ChatGPT: design, planning, architecture, balance thinking
- Cursor + ChatGPT Codex: coding and refactoring
- ChatGPT Images: visual concept generation
- Krita: cleanup, editing, UI/art asset preparation

### Development principle

Always build the **smallest playable version first**.

Avoid early scope creep:

- No multiplayer in V1.0
- No complex economy
- No production chains
- No advanced CPU simulation
- No final art before the core loop works
- No campaign structure yet
- No complex animations needed

---

## 3. High-level game fantasy

The player is directing a national or international space program in a near-future space race.

The immediate goal is to deliver the correct materials to a moonbase and reach 100% readiness before rival factions do.

Tone:

- Mostly serious near-future space race
- Small hint of comedy in news messages and failure events
- Clean, readable, strategy-board-game-like UI
- Not realistic simulation
- Not arcade action

---

## 4. Win and loss condition

### Win condition

The first faction to reach **100% moonbase readiness** wins.

For V1.0:

> The player wins immediately when their moonbase reaches 100%.

### Loss condition

The player loses if one of the CPU competitors reaches 100% readiness first.

---

## 5. Match length

Target match length:

> 10–15 minutes

The match should usually end around:

- 3–6 player launches
- approximately 75–130 in-game days
- depending on player choices, packing efficiency, wasted materials, and launch failures

---

## 6. Player factions

The player chooses one faction at the start.

Available factions:

- USA
- China
- EU

The two factions not chosen by the player become CPU competitors.

In V1.0, faction choice is mostly visual/flavor only.

Future versions may give factions different:

- vehicle stats
- moonbase material requirements
- launch reliability
- special bonuses
- news styles

---

## 7. Core gameplay loop

Each turn follows this structure:

1. Player is on the strategy screen.
2. Player reviews:
   - days passed
   - moonbase progress
   - remaining material needs
   - CPU competitor progress
   - news feed
3. Player chooses one launch vehicle:
   - Big Rocket
   - Space Shuttle
   - SpinLaunch
4. Cargo loading begins.
5. Phase 1: player assigns materials to a subset of available cargo pieces.
6. Player confirms assignment.
7. Phase 2: player packs assigned pieces into the cargo grid.
8. Player launches.
9. Launch is resolved:
   - if enough fuel is placed, launch succeeds
   - if too little fuel is placed, launch crashes
10. Time advances by the vehicle's launch duration.
11. CPU competitors progress.
12. News messages appear.
13. Game checks for win/loss.
14. If no one has won, return to strategy screen.

Important rule:

> One launch happens per turn. There are no simultaneous launches in V1.0.

---

## 8. Launch vehicles

Each launch vehicle has:

- cargo grid size
- maximum payload
- required fuel
- launch duration
- vehicle-specific cargo piece set

Each cargo grid square equals **10 units**.

### Vehicle table

| Vehicle | Grid | Max payload | Required fuel | Max construction cargo | Launch days |
|---|---:|---:|---:|---:|---:|
| Big Rocket | 5 × 10 | 500 | 200 | 300 | 30 |
| Space Shuttle | 4 × 8 | 320 | 120 | 200 | 20 |
| SpinLaunch | 1 × 2 | 20 | 0 | 20 | 5 |

### Design purpose

#### Big Rocket

The Big Rocket should have the best large-scale strategic value.

It has:

- largest payload
- largest grid
- highest fuel requirement
- hardest packing challenge
- high reward if used well
- high pain if launched badly

The Big Rocket gives:

```text
300 construction cargo / 30 days = 10 useful units per day
```

#### Space Shuttle

The Space Shuttle is smaller and easier to reason about.

It has:

- medium payload
- smaller grid
- lower fuel requirement
- easier packing challenge
- more frequent launch timing
- same useful units/day when perfectly optimized

The Shuttle gives:

```text
200 construction cargo / 20 days = 10 useful units per day
```

#### SpinLaunch

SpinLaunch is a tactical tool.

It has:

- tiny payload
- no fuel requirement
- fast launch time
- useful for late-game corrections
- poor large-scale efficiency

It is not meant to be the main way to win.

---

## 9. Materials

There are two material categories:

1. Launch material
2. Construction materials

### Launch material

#### Fuel

Fuel is a cargo material.

It must be assigned to cargo pieces and physically placed into the cargo grid.

Fuel competes with useful construction materials.

If placed fuel is below the vehicle requirement, the launch fails.

Fuel does not count toward moonbase construction progress.

### Construction materials

The moonbase requires:

| Material | Required units | Approximate share |
|---|---:|---:|
| Carbon / metals | 320 | 35.5% |
| Silicon | 220 | 24.4% |
| Copper | 140 | 15.5% |
| Electronics | 90 | 10% |
| Rare metals | 70 | 7.8% |
| Propellant | 60 | 6.7% |
| **Total** | **900** | **100%** |

These numbers are rounded to work cleanly with 10-unit grid cells.

---

## 10. Moonbase readiness

The moonbase starts at 0% readiness.

It reaches 100% when all construction material requirements have been fulfilled.

Readiness formula:

```text
readiness_percent = 100 × (1 - remaining_required_units / total_required_units)
```

Example:

```text
Total required = 900
Remaining required = 450
Readiness = 50%
```

Fuel does not affect readiness.

---

## 11. Cargo system

The cargo system is the heart of the game.

Cargo loading has two locked phases:

1. Material assignment phase
2. Packing phase

This two-phase structure is a core design pillar.

---

### 11.1 Phase 1 — Material assignment

The player first chooses a launch vehicle.

Then the player sees that vehicle's available cargo pieces.

The player may assign materials to **any subset** of available pieces.

Rules:

- Player does not need to use every piece.
- One piece can have only one material.
- The whole piece becomes that material.
- Two pieces with the same shape can have different materials.
- Assigned payload cannot exceed vehicle max payload.
- Fuel assignment is allowed like any other material.
- UI shows assigned payload and assigned fuel.
- After confirming, the player cannot return to assignment phase during that turn.

Example:

- L-shaped piece = fuel
- Another L-shaped piece = silicon
- Long bar piece = carbon/metals
- Square piece = electronics

The player commits to a material plan before knowing whether everything will fit neatly.

This creates strategic tension.

---

### 11.2 Phase 2 — Packing

After material assignment is confirmed, the player enters packing phase.

Rules:

- Assignments are locked.
- Player can only place pieces that were assigned a material.
- Empty cargo spaces are allowed.
- No 1-cell gap fillers exist in V1.0.
- Only placed pieces count toward the launch.
- Assigned but unplaced pieces are not launched.
- Player can clear placements and try again.
- Clearing placements does not return to material assignment.
- Player must launch or reset the whole turn only if such a feature is later added.

Important:

> The launch manifest is calculated only from placed pieces, not assigned pieces.

This means the player can make mistakes:

- assigned enough fuel, but could not fit it
- assigned too many awkward shapes
- assigned useful materials but left them outside the grid
- packed construction materials but forgot enough fuel
- wasted cargo space because pieces did not fit

This is intentional.

---

## 12. Cargo piece sets

V1.0 uses **vehicle-specific piece sets**.

Do not use one universal piece set.

### Big Rocket piece set

The Big Rocket has its own larger, harder piece set.

Design goals:

- larger and more awkward pieces
- difficult but possible to pack efficiently
- no 1-cell fillers
- should reward planning
- should create occasional empty spaces

The exact coordinates should be based on the hand-drawn Big Rocket piece sketch.

### Space Shuttle piece set

The Space Shuttle has its own smaller piece set.

Design goals:

- smaller set than Big Rocket
- easier to understand
- still enough awkwardness to create meaningful choices
- no 1-cell fillers
- should allow partially filled launches

The exact coordinates should be based on the hand-drawn Shuttle piece sketch.

### SpinLaunch piece set

Recommended V1.0 implementation:

- very small grid: 1 × 2
- payload: 20 units
- use either:
  - one 2-cell piece
  - or automatic material selection without puzzle

Simplest version:

> SpinLaunch skips complex packing and lets the player send 20 units of one chosen construction material.

However, if consistency is preferred, SpinLaunch can use a tiny 1×2 cargo grid.

---

## 13. Cargo piece data representation

Each piece should be defined as a list of grid coordinates relative to its origin.

Example:

```gdscript
{
	"id": "piece_l_01",
	"display_name": "L Piece",
	"cells": [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(1, 2)
	]
}
```

Cell count determines payload:

```text
payload_units = cell_count × 10
```

A 4-cell piece equals 40 units.

---

## 14. Assignment data

An assigned piece should contain:

```gdscript
{
	"instance_id": "br_piece_03",
	"shape_id": "big_l_01",
	"material": "fuel",
	"cell_count": 4,
	"payload_units": 40
}
```

Important:

- `shape_id` identifies the shape.
- `instance_id` identifies this specific copy.
- material is stored per individual piece instance.
- same shape can appear multiple times with different materials.

---

## 15. Packing data

A placed piece should contain:

```gdscript
{
	"instance_id": "br_piece_03",
	"material": "fuel",
	"origin": Vector2i(2, 5),
	"rotation": 90,
	"occupied_cells": [
		Vector2i(2, 5),
		Vector2i(3, 5),
		Vector2i(3, 6),
		Vector2i(3, 7)
	]
}
```

The final cargo manifest is generated from placed pieces only.

Example manifest:

```gdscript
{
	"fuel": 200,
	"carbon_metals": 120,
	"silicon": 80,
	"copper": 40,
	"electronics": 0,
	"rare_metals": 0,
	"propellant": 20
}
```

---

## 16. Launch resolution

When the player launches:

1. Build manifest from placed cargo pieces.
2. Check placed fuel.
3. If fuel is below vehicle requirement:
   - launch crashes
   - all cargo is lost
   - time advances normally
   - CPU factions progress
   - news message is created
4. If fuel is enough:
   - fuel is consumed
   - construction materials are delivered
   - moonbase requirements are reduced
   - excess construction material is wasted
   - time advances normally
   - CPU factions progress
   - news message is created
5. Check win/loss.

### Launch failure rule

If launch fails:

- cargo is lost
- construction materials do not arrive
- fuel is lost
- time still advances
- CPU progress still happens

This should feel painful but fair.

The UI must clearly warn the player before launch.

---

## 17. Material overdelivery

Overdelivery is wasted.

Example:

```text
Moonbase needs 20 copper.
Player delivers 50 copper.
20 copper is used.
30 copper is wasted.
```

No moonbase storage system in V1.0.

Reason:

- keeps game simple
- creates meaningful planning pressure
- makes SpinLaunch useful near the end
- avoids economy complexity

---

## 18. CPU competitors

CPU competitors do not solve cargo puzzles.

They progress through simplified rules when time advances.

Each CPU faction has:

```text
name
progress_percent
speed_per_day
crash_chance
news_style
```

Only the two non-player factions are active competitors.

### Recommended CPU values

| Faction | Speed | Crash chance | Personality |
|---|---:|---:|---|
| China | 0.95% / day | 10% | fast, aggressive |
| USA | 0.85% / day | 12% | powerful but risky |
| EU | 0.75% / day | 6% | steady, careful |

These are starting values only.

### CPU progress formula

When time advances:

```text
base_gain = elapsed_days × speed_per_day
```

If CPU crash occurs:

```text
actual_gain = base_gain × 0.25
```

If no crash occurs:

```text
actual_gain = base_gain
```

CPU progress should be clamped between 0 and 100.

---

## 19. News system

The news system gives feedback and personality.

News should appear after each launch.

News types:

- player successful launch
- player launch crash
- player material delivery summary
- CPU progress
- CPU crash
- CPU reaches milestone
- win/loss announcement

Tone:

- serious space-race news
- slight comedy in failure descriptions

Examples:

```text
China launches another heavy cargo mission toward the lunar south pole.
EU engineers report slow but steady progress on their moonbase frame.
USA suffers a launch anomaly. Officials describe the event as "a very energetic test."
Your Big Rocket crashes after insufficient fuel loading. The mission board avoids eye contact.
Moonbase crew reports: silicon delivered, copper still critically low.
China reaches 75% moonbase readiness.
```

---

## 20. User interface

V1.0 should have four main screens:

1. Faction select screen
2. Strategy screen
3. Cargo loading screen
4. Game over screen

---

### 20.1 Faction select screen

Purpose:

- choose player faction
- assign the other two as CPU competitors

Elements:

```text
Project Dyson Swarm
Choose your faction:

[USA]
[China]
[EU]

Start Race
```

For V1.0, faction choice only affects names/logos.

---

### 20.2 Strategy screen

Purpose:

- show current race state
- let player choose launch vehicle

Required UI:

```text
Days passed: 60

Player moonbase readiness: 45%

Material needs:
- Carbon/metals: 160 remaining
- Silicon: 80 remaining
- Copper: 90 remaining
- Electronics: 40 remaining
- Rare metals: 50 remaining
- Propellant: 30 remaining

Competitors:
- China: 52%
- EU: 41%

Choose launch:
[Big Rocket]
[Space Shuttle]
[SpinLaunch]

News feed:
- China launched a heavy rocket.
- Your previous shuttle delivered 180 useful units.
```

Vehicle buttons should show:

- payload
- required fuel
- launch days
- grid size

Example:

```text
Big Rocket
Payload: 500
Fuel required: 200
Launch time: 30 days
Grid: 5 × 10
```

---

### 20.3 Cargo loading screen

Cargo loading screen has two sub-phases.

---

#### Cargo screen phase 1: Material assignment

Purpose:

- assign materials to chosen subset of pieces

Required UI:

```text
Vehicle: Big Rocket
Capacity: 0 / 500 assigned
Required fuel: 200
Assigned fuel: 0

Available pieces:
[piece 1] [piece 2] [piece 3] ...

Selected piece:
[piece preview]

Assign material:
[Fuel]
[Carbon/metals]
[Silicon]
[Copper]
[Electronics]
[Rare metals]
[Propellant]

Assigned pieces:
piece 1 = Fuel, 50 units
piece 2 = Silicon, 40 units
piece 3 = Carbon/metals, 30 units

[Reset Assignments]
[Confirm Assignments]
```

Rules:

- player can assign any subset
- assignment cannot exceed vehicle capacity
- assigned fuel warning is shown
- assignment can be reset before confirmation
- after confirmation, move to packing phase

Warning examples:

```text
Fuel assigned is below required minimum.
You may still continue, but make sure enough fuel is placed before launch.
```

---

#### Cargo screen phase 2: Packing

Purpose:

- place already-assigned pieces into grid

Required UI:

```text
Packing phase — assignments locked

Pieces to place:
[Fuel L-piece]
[Silicon bar]
[Carbon block]

Cargo grid:
5 × 10

Placed payload: 360 / 500
Placed fuel: 160 / 200

Warnings:
Not enough fuel placed.
Empty cargo spaces are allowed.

[Clear Placements]
[Launch]
```

Controls:

- click piece to select
- mouse over grid shows ghost preview
- left click grid places piece
- R rotates selected piece
- right click placed piece removes it
- clear placements removes all placed pieces
- launch resolves current placed cargo

Important:

> Do not allow return to assignment phase during the same turn.

---

### 20.4 Game over screen

Victory example:

```text
PROJECT DYSON SWARM SUCCESSFUL

Your faction completed the moonbase first.

Days elapsed: 90
Launches: 4
Successful launches: 4
Failed launches: 0
Useful material delivered: 900
Material wasted: 80
```

Loss example:

```text
SPACE RACE LOST

China completed its moonbase before you.

Your moonbase readiness: 82%
Days elapsed: 105
Launches: 5
Failed launches: 1
```

Buttons:

```text
[Play Again]
[Main Menu]
```

---

## 21. Visual style

V1.0 can use placeholder art.

Later target style:

- clean 2D UI-focused strategy game
- readable icons
- stylized rockets and cargo pieces
- clear material colors
- near-future space race look
- subtle comedy in news panels
- not photorealistic
- not pixel art unless intentionally changed later

Important visual needs:

- cargo pieces must be very readable
- materials must be distinguishable
- fuel warning must be obvious
- moonbase progress must be visible at a glance
- CPU progress must create pressure

---

## 22. Suggested material colors/icons

Temporary prototype colors are fine.

Suggested identity:

| Material | Visual idea |
|---|---|
| Fuel | orange/red tank icon |
| Carbon/metals | dark gray metal beam |
| Silicon | blue crystal/wafer |
| Copper | copper wire/coil |
| Electronics | green circuit board |
| Rare metals | purple/gold ingot |
| Propellant | teal pressure canister |

Do not spend too much time on final icons before the gameplay loop works.

---

## 23. Recommended Godot project structure

```text
project_dyson_swarm/
├── scenes/
│   ├── main/
│   │   └── Main.tscn
│   ├── ui/
│   │   ├── FactionSelectScreen.tscn
│   │   ├── StrategyScreen.tscn
│   │   ├── CargoLoadingScreen.tscn
│   │   └── GameOverScreen.tscn
│   └── cargo/
│       ├── CargoGridView.tscn
│       ├── CargoPieceButton.tscn
│       └── MaterialButton.tscn
├── scripts/
│   ├── autoload/
│   │   └── GameState.gd
│   ├── data/
│   │   └── GameData.gd
│   ├── launch/
│   │   └── LaunchManager.gd
│   ├── cargo/
│   │   ├── CargoGrid.gd
│   │   ├── CargoPiece.gd
│   │   ├── CargoAssignment.gd
│   │   └── CargoPackingState.gd
│   ├── moonbase/
│   │   └── Moonbase.gd
│   ├── cpu/
│   │   └── CPUCompetitor.gd
│   └── news/
│       └── NewsManager.gd
├── assets/
│   ├── placeholder/
│   ├── ui/
│   ├── icons/
│   └── vehicles/
└── docs/
    ├── DESIGN_V1.md
    ├── PROJECT_STATE.md
    └── BALANCE_NOTES.md
```

---

## 24. Recommended main scene structure

```text
Main.tscn
├── GameController
├── FactionSelectScreen
├── StrategyScreen
├── CargoLoadingScreen
└── GameOverScreen
```

Use `Control` nodes for the UI.

This is a UI-heavy strategy/puzzle game, not a physics platformer.

---

## 25. Script responsibilities

### `GameData.gd`

Static data:

- materials
- vehicle stats
- moonbase requirements
- piece sets
- faction data
- CPU defaults

### `GameState.gd`

Global match state:

- selected player faction
- active CPU factions
- days elapsed
- moonbase state
- CPU progress
- news messages
- current screen
- launch stats
- win/loss status

### `Moonbase.gd`

Handles:

- remaining materials
- applying delivered materials
- calculating waste
- calculating readiness percentage
- checking completion

### `LaunchManager.gd`

Handles:

- resolving launch
- checking fuel
- applying cargo delivery
- advancing time
- triggering CPU progress
- creating news
- checking win/loss

### `CargoGrid.gd`

Handles pure grid logic:

- grid width/height
- placed pieces
- collision detection
- out-of-bounds checks
- rotation validation
- placement/removal
- manifest calculation

### `CargoAssignment.gd`

Handles assignment phase:

- selected vehicle
- available pieces
- assigned subset
- assigned materials
- assigned payload
- assigned fuel
- confirm assignment

### `CargoPackingState.gd`

Handles packing phase:

- assigned pieces
- placed pieces
- unplaced pieces
- placed payload
- placed fuel
- launch manifest

### `CPUCompetitor.gd`

Handles:

- CPU name
- progress percent
- speed per day
- crash chance
- progress update
- crash result

### `NewsManager.gd`

Handles:

- adding news messages
- storing recent news
- optional message templates

---

## 26. Development milestones

### Milestone 0 — Project setup

Goal:

Create project folders and core scripts.

No gameplay yet.

Deliverables:

- Godot project created
- folder structure created
- empty main scene
- `GameData.gd`
- `GameState.gd`
- `PROJECT_STATE.md`
- `DESIGN_V1.md`

---

### Milestone 1 — Data-only launch loop

Goal:

Make the strategic game work without real cargo UI.

Create test buttons:

```text
Test Big Rocket Success
Test Shuttle Success
Test Failed Rocket
Test SpinLaunch
```

These buttons send hardcoded cargo manifests.

Must prove:

- launch success/failure works
- fuel check works
- moonbase readiness updates
- overdelivery is wasted
- days advance
- CPU competitors progress
- CPU crashes can happen
- news messages appear
- win/loss is detected

This milestone is very important.

Do not build drag-and-drop before this works.

---

### Milestone 2 — Vehicle-specific piece data

Goal:

Encode Big Rocket and Shuttle piece sets.

Deliverables:

- piece shapes stored as grid coordinate arrays
- Big Rocket uses its own piece set
- Shuttle uses its own piece set
- SpinLaunch stub exists
- piece previews can be generated from data

Use the hand-drawn sketches as source.

Exact balance can change later.

---

### Milestone 3 — Material assignment screen

Goal:

Build phase 1 of cargo screen.

Features:

- selected vehicle shown
- available pieces shown
- material buttons shown
- assign material to any subset
- assigned payload meter
- assigned fuel meter
- cannot exceed vehicle max payload
- reset assignments
- confirm assignments
- move to packing phase

No packing required yet.

---

### Milestone 4 — Packing grid

Goal:

Build phase 2 of cargo screen.

Features:

- grid shown
- assigned pieces shown
- select piece
- rotate piece
- place piece
- reject invalid placement
- remove placed piece
- clear placements
- calculate placed manifest
- show placed fuel
- show fuel warning
- launch button

---

### Milestone 5 — Full playable loop

Goal:

A complete match can be played.

Features:

- choose faction
- choose vehicle
- assign cargo
- pack cargo
- launch
- resolve result
- CPU advances
- news updates
- win/loss screen appears

This is the first real prototype.

---

### Milestone 6 — Balance pass

Goal:

Make the game last 10–15 minutes and feel fair.

Tune:

- CPU speed
- CPU crash chance
- moonbase requirements
- vehicle launch days
- fuel requirements
- piece sets
- number of available pieces
- waste pressure
- SpinLaunch usefulness

Target feel:

- Big Rocket is powerful but hard.
- Shuttle is flexible but not mathematically stronger.
- SpinLaunch is useful for precise late-game fixes.
- A good player can win.
- Bad planning can lose.
- One failed launch hurts but does not always instantly end the match.

---

### Milestone 7 — First visual pass

Only after the full loop works.

Create:

- simple rocket icon
- simple shuttle icon
- simple SpinLaunch icon
- material icons
- faction logos/flags
- cargo piece visuals
- moonbase progress panel
- news panel style

Do not over-polish before gameplay is tested.

---

## 27. Balance notes

### Current useful cargo per day

| Vehicle | Construction cargo | Days | Useful cargo/day |
|---|---:|---:|---:|
| Big Rocket | 300 | 30 | 10 |
| Shuttle | 200 | 20 | 10 |
| SpinLaunch | 20 | 5 | 4 |

Big Rocket and Shuttle are equally efficient when perfectly packed.

The difference is intended to come from:

- puzzle difficulty
- piece shapes
- risk of missing fuel
- overdelivery
- timing
- late-game material needs

If Big Rocket feels too weak, possible buffs:

- reduce launch time to 28 days
- reduce fuel requirement to 180
- make piece set easier
- increase Shuttle launch time to 22–25 days

If Shuttle feels too weak:

- reduce launch time to 18 days
- reduce fuel to 100
- make piece set easier

Do not balance too early. First make the loop playable.

---

## 28. Important design risks

### Risk 1: Assignment phase may feel punishing

Because player cannot return after confirming assignment, bad choices can hurt.

Mitigation:

- make UI warnings clear
- show assigned fuel
- show required fuel
- show total assigned payload
- allow reset before confirmation
- make the rule very clear

### Risk 2: Packing may become frustrating

No 1-cell fillers means gaps will happen.

Mitigation:

- empty spaces are allowed
- player is not required to fill the grid
- success is based on good enough planning, not perfection
- use clear visual previews
- make rotation easy

### Risk 3: Too much arithmetic

Material requirements, fuel, payload, and days could overwhelm player.

Mitigation:

- always show summaries
- use colors/icons
- show warnings
- show “useful delivery estimate”
- keep V1.0 UI simple

### Risk 4: CPU may feel unfair

If CPU progresses too fast, player loses without understanding why.

Mitigation:

- clear CPU progress meters
- news explains CPU gains/crashes
- tune CPU to usually finish around day 100–120
- let player learn vehicle tradeoffs

---

## 29. Cursor/Codex working instructions

When using Cursor + Codex, always give it limited tasks.

Do not ask it to build the whole game at once.

Good task style:

```text
Create the data model only.
Do not build UI yet.
```

or:

```text
Implement CargoGrid placement validation only.
Do not connect it to launch resolution yet.
```

Avoid:

```text
Build the whole game.
```

---

## 30. First Cursor/Codex prompt

Use this first:

```text
We are building a Godot 4.6 UI-based 2D puzzle/strategy prototype called Project Dyson Swarm.

Create the first data-driven prototype structure.

Core game:
- Player races against two CPU factions to reach 100% moonbase readiness.
- One turn = choose launch vehicle, resolve launch, advance time, CPU progresses.
- Do not build cargo UI yet.
- Use hardcoded test cargo manifests for now.

Vehicles:
1. Big Rocket
   - grid 5x10
   - max payload 500
   - required fuel 200
   - launch days 30

2. Space Shuttle
   - grid 4x8
   - max payload 320
   - required fuel 120
   - launch days 20

3. SpinLaunch
   - grid 1x2
   - max payload 20
   - required fuel 0
   - launch days 5

Materials:
- fuel
- carbon_metals
- silicon
- copper
- electronics
- rare_metals
- propellant

Moonbase requirements:
- carbon_metals: 320
- silicon: 220
- copper: 140
- electronics: 90
- rare_metals: 70
- propellant: 60

Rules:
- Fuel is a cargo material.
- Fuel does not count toward moonbase readiness.
- If placed fuel is below vehicle.required_fuel, launch crashes.
- If launch crashes, cargo is lost and time still advances.
- If launch succeeds, non-fuel materials reduce moonbase requirements.
- Overdelivery is wasted.
- After each launch, days advance by vehicle.launch_days.
- CPU competitors progress after time advances.
- CPU competitors can randomly suffer launch crashes.
- First faction to 100% readiness wins.

Create:
1. GameData.gd
2. GameState.gd
3. Moonbase.gd
4. CPUCompetitor.gd
5. LaunchManager.gd
6. NewsManager.gd
7. A simple Main.tscn script with test buttons or callable test functions.

Use Godot 4.6 GDScript.
Keep code simple, modular, and prototype-friendly.
Explain the files and responsibilities before writing code.
```

---

## 31. Second Cursor/Codex prompt

Use this after Milestone 1 works:

```text
Now update Project Dyson Swarm to support vehicle-specific cargo piece sets and a two-phase cargo system.

Do not build final UI yet. Focus on data structures and logic.

Required concepts:

1. Vehicle-specific piece sets:
   - big_rocket has its own piece set
   - space_shuttle has its own piece set
   - spinlaunch can be stubbed

2. Cargo phase 1: Material assignment
   - player may assign materials to any subset of available pieces
   - one piece = one material
   - same shape copies can have different materials
   - assigned payload cannot exceed vehicle max payload
   - track assigned fuel
   - after confirm, assignment is locked

3. Cargo phase 2: Packing
   - only assigned pieces can be placed
   - assignments cannot be changed
   - empty grid spaces are allowed
   - no 1-cell filler pieces are required
   - only placed pieces count toward launch
   - assigned but unplaced pieces are ignored
   - clear placements resets placement only

Create or update:
- CargoPiece.gd
- CargoAssignment.gd
- CargoGrid.gd
- CargoPackingState.gd

CargoGrid must support:
- grid width and height
- can_place_piece()
- place_piece()
- remove_piece()
- rotate_piece()
- clear()
- get_manifest_from_placed_pieces()

Use piece definitions as arrays of Vector2i cells.
Keep everything data-driven and easy to connect to UI later.
Use Godot 4.6 GDScript.
```

---

## 32. Current prototype implementation snapshot

This section records where the playable prototype is now, after Milestones 1-4 and the first cargo UI cleanup pass.

Implemented:

- Data-driven launch loop is working.
- Vehicle selection, material assignment, packing, launch resolution, CPU progress, and win/loss checks are connected.
- Fuel is assigned and packed like any other cargo material.
- Launch success/failure is based on placed fuel only.
- Only placed pieces generate the launch manifest.
- Assigned but unplaced pieces are ignored.
- Overdelivery is wasted.
- The player cannot return from packing to assignment in the same turn.

Current cargo implementation:

- Big Rocket has 10 base shapes, 2 copies each, for 20 assignable piece instances.
- Big Rocket base set totals 50 cells, matching the 5x10 cargo hold.
- Space Shuttle has 8 base shapes, 2 copies each, for 16 assignable piece instances.
- Space Shuttle base set totals 32 cells, matching the 4x8 cargo hold.
- SpinLaunch has a simple 1x2 capsule-style stub.
- Each piece copy has its own instance id, so copies of the same shape can use different materials.
- No universal piece set is used.
- No 1-cell filler pieces are used.

Current assignment UI:

- Available pieces are grouped by shape.
- Selecting a shape group shows the individual copies for assignment.
- Payload and fuel meters update during assignment.
- Moonbase material needs are visible during assignment.
- The center of the assignment screen shows a non-interactive cargo hold preview.
- Layout is currently: info panel on the left, cargo hold preview in the center, available cargo on the right.

Current packing UI:

- The cargo grid is displayed in a horizontal sketch-inspired layout.
- Internal data still uses vehicle grid dimensions, such as Big Rocket 5x10 and Space Shuttle 4x8.
- The visual grid is transposed for readability, such as Big Rocket shown as 10 columns by 5 rows.
- Player can select assigned pieces, rotate before placement, place them, pick placed pieces back up, remove pieces, clear all placements, and launch.
- The placed manifest and fuel warning update from placed pieces only.

Useful next planning targets:

- Milestone 5 full loop polish: faction select, strategy screen, game over screen, and turn-to-turn readability.
- CPU faction personality and balance.
- Better news feed events.
- Material economy and moonbase progress pacing.
- Visual cargo piece treatment and material color language.
- First pass at player guidance without turning the UI into a tutorial wall.

---

## 33. Current locked V1.0 decisions summary

```text
Game name:
Project Dyson Swarm

Engine:
Godot 4.6

Target:
PC prototype

Match length:
10–15 minutes

Win condition:
First faction to 100% moonbase readiness wins

Player resources:
Unlimited Earth materials

Fuel:
Cargo material, must be packed

Launch failure:
Too little placed fuel = crash, cargo lost, time advances

Time:
One launch per turn, time jumps after launch

Vehicles:
Big Rocket: 5x10, 500 payload, 200 fuel, 30 days
Space Shuttle: 4x8, 320 payload, 120 fuel, 20 days
SpinLaunch: 1x2, 20 payload, 0 fuel, 5 days

Cargo:
Vehicle-specific piece sets
No universal piece set
No 1-cell fillers
Empty spaces allowed

Cargo flow:
Phase 1: assign materials to any subset of pieces
Phase 2: pack assigned pieces
No going back to assignment after confirmation

Material overdelivery:
Wasted

CPU:
Simplified progress model with occasional crashes

Tone:
Serious near-future space race with slight comedy
```
