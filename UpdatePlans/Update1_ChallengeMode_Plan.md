# Update #1: Challenge Mode — Plan

Source notes: `Update #1 Challenge Mode.txt`. Plan written 2026-10-10.

## Decisions

- **Fastest completion is a pure time trial.** There are no CPU rivals. The score is the number of in-game days to finish the moonbase.
- **Modifiers stack.** The player builds a challenge by switching on any compatible set of modifiers.
- **The demo shows challenges, locked.** Demo players can open the Challenges screen and see every modifier, but cannot start one.

## Player-facing design

### Flow

```text
Opening:     Start | Challenges | Options | Exit Game
Challenges → toggle modifiers → Continue → Faction select → match
```

- **Start** always plays a normal match and clears any challenge rules.
- **Play Again** on the game-over screen keeps the current challenge.
- **Main Menu** clears the current challenge.
- **The Challenges screen** shows:
  - the modifier list
  - a one-line summary of the active rules
  - the personal best for the current modifier combination

### Modifiers

| Modifier | Rule | Parameters | Stacking |
|---|---|---|---|
| ⭐ Time Trial | No CPU rivals. The score is days to 100% readiness. | — | Not with Extreme Rivals |
| ⭐ One Life | Any crashed launch ends the run as a loss. | — | Any |
| ⭐ Alternate Cargo | Big Rocket and Shuttle use a different piece set. | Set id | Any |
| Launch Limit | Running out of launches before 100% is a loss. | 4 / 6 / 8 launches | Any |
| Fixed Vehicle | Only one vehicle card is usable. | Big Rocket / Shuttle / SpinLaunch | SpinLaunch only with Time Trial (see Balance) |
| Extreme Rivals | CPU profile harder than Hard. | — | Not with Time Trial; overrides Options difficulty |
| Random Needs | Moonbase needs are randomly split; the total stays 900. | — | Any |

The base rules don't change. Cargo, packing and launch resolution are locked, as `DESIGN_V1.md` requires. Every modifier either adds a loss condition, restricts a choice, or swaps data such as the piece set, moonbase needs or CPU profile.

### Scoring and records

- **Time Trial score:** in-game days, lower is better. Ties are broken by fewer launches.
  - Wall-clock time is ignored, so the score rewards planning rather than clicking speed.
- **Other challenges:** the record is "cleared" plus the best day count among wins.
- **Storage:** records are keyed by the exact modifier combination, using sorted ids plus parameters such as `launch_limit=6|one_life|time_trial`.
- **Location:** records are saved in `user://challenge_records.cfg`, separate from `settings.cfg`.
- **Random Needs:** these runs keep their own records, because different splits aren't directly comparable.

### Win / loss screens

- **New loss reasons:** the game-over panel says why the run ended, e.g. "A launch crashed — One Life challenge failed" or "Out of launches (6/6)".
- **Time Trial win:** the screen shows the day count, the launch count, the previous best, and a "New record" line when it applies.

### Demo build

- **The Challenges button is visible and clickable.** The screen lists every modifier with a lock icon and the line "Available in the full game".
- **The modifier toggles and Continue are disabled.**
- **Tests:** `DemoOpeningFlowSmokeTest` gains a check that a demo build cannot start a challenge match.

## Technical plan

### Phase 0 — Rules layer, no UI (can land before release)

Goal: the code accepts challenge rules, but default rules behave exactly like today.

- **`scripts/rules/MatchRules.gd`** (new, `RefCounted`) has these fields:
  - `cpu_enabled := true`
  - `max_failures := -1` (-1 means unlimited)
  - `max_launches := -1`
  - `allowed_vehicles: Array[String] = []` (empty means all)
  - `piece_set_id := "standard"`
  - `moonbase_requirements := {}` (empty means `GameData.MOONBASE_REQUIREMENTS`)
  - `cpu_profile_override := ""`
  - `rng_seed := -1` (-1 means `randomize()`)
  - `modifier_ids: Array[String]`
  - `func get_record_key() -> String`
- **`GameState.start_new_match(faction, difficulty, rules := MatchRules.new())`**
  - stores `active_rules`
  - seeds `rng` from `rules.rng_seed`
  - builds the moonbase from the rules' requirements
  - skips `_setup_cpu_competitors()` when `cpu_enabled` is false
- **`GameState.check_for_winner()`**
  - adds the One Life and Launch Limit loss checks after the moonbase check, so finishing on your last allowed launch still counts as a win
  - returns a `loss_reason` field
- **`Moonbase`** keeps `initial_requirements`. These places switch from `GameData.MOONBASE_REQUIREMENTS` to that value:
  - `StrategyScreen.gd:490`
  - `CargoLoadingScreen.gd:446` and `:978-979`
  - `Main.gd:1720`
- **`GameData.get_piece_set(vehicle_id, set_id := "standard")`**
  - `CARGO_PIECE_SETS` becomes keyed by set id, then by vehicle
  - `CargoAssignment.gd:18` passes the active set id through
- **`GameData.DIFFICULTY_PROFILES`** gets an `"extreme"` entry. It's only reachable through rules, not from the Options difficulty choices.
- **Tests:** new `ChallengeRulesSmokeTest.gd` covers:
  - default rules match the current behaviour
  - One Life loses on a crash
  - Launch Limit loses when launches run out, but wins on the final launch if it completes the moonbase
  - Time Trial has no competitors
  - a seeded rng repeats exactly

### Phase 1 — Challenges screen and records

- **`scripts/data/ChallengeData.gd`:** modifier definitions with id, name, description, parameter options and `incompatible_with`, plus `build_rules(selection) -> MatchRules`.
- **`scenes/ui/ChallengesScreen.tscn` + `.gd`:**
  - modifier toggles and parameter pickers
  - incompatible options greyed out, with the reason shown
  - the personal-best readout
  - Back / Continue
  - the locked demo state
  - built scene-first, like the other editor-tunable screens, using the `panel_options.png` look
- **`scripts/records/ChallengeRecords.gd`:** loads and saves `user://challenge_records.cfg`.
- **`Main.gd`:**
  - adds the opening-menu button
  - keeps a `selected_rules` value
  - passes it into the four `start_new_match` call sites (`1510`, `1515`, `1520`, `1525`)
  - `_on_main_menu_pressed` resets `selected_rules`
- **StrategyScreen:**
  - disables the vehicle cards that `allowed_vehicles` excludes
  - in Time Trial, replaces the CPU list with "Time Trial — best: N days"
  - shows a "Launches left / Crashes allowed" line when those limits are active
- **Game-over screen:** shows the loss reason, the Time Trial result and the record line.
- **How To Play:** adds a short Challenges section.

### Phase 2 — Quick-win modifiers

Phase 0 and 1 already provide the rules these modifiers use. This phase only adds their content and tuning.

- **Time Trial, One Life, Launch Limit and Fixed Vehicle:** wire them up, then playtest each one.
- **Extreme Rivals:** a starting profile is `cpu_speed_multiplier 1.15`, `cpu_crash_multiplier 0.75`, Big Rocket only. Tune it in playtest.
- **Random Needs:** split the 900 total with the match rng. Each material gets at least 40 units, with the total rounded so it can be delivered in 10-unit cells.

### Phase 3 — Alternate cargo sets (headline content)

- **Design one or two alternate sets per vehicle** (Big Rocket and Shuttle; SpinLaunch has nothing to vary). Hard constraints:
  - Each set's cells must exactly fill the grid: Big Rocket = 50 cells, Shuttle = 32.
  - No 1-cell pieces.
  - Every set must be able to carry the required fuel. Fuel goes in 10-unit cells, so Big Rocket needs exactly 20 fuel cells and Shuttle needs 12, made from whole pieces.
- **Art:** new piece PNGs under `assets/ui/cargo_pieces/<set>/`, mapped in `UiAssets.gd`.
- **Art fallback:** add a generated-block fallback for pieces without art, so a set is playable before its art is finished.
- **Tests:** extend `CargoSmokeTest` to check every set's cell totals and the fuel-cell constraint.

### Later — Daily / weekly seeded challenge

- **Offline version:** the seed is a hash of the date, used with Random Needs and a rotating modifier combination. Everyone playing that day gets the same run.
- **Phase 0 makes this possible:** all match randomness already goes through `GameState.rng`, so seeding it covers everything.
- **Leaderboards:** online leaderboards are a separate, larger project and are out of scope here.

## Balance facts to keep in mind

Each cell carries 10 units. The moonbase needs a total of 900 units.

| Vehicle | Useful units per launch | Days per launch | Useful units per day |
|---|---:|---:|---:|
| Big Rocket | 500 − 200 fuel = 300 | 30 | 10 |
| Shuttle | 320 − 120 fuel = 200 | 20 | 10 |
| SpinLaunch | 20 | 5 | 4 |

- **Theoretical best Time Trial ≈ 90 days.** That's 3 perfect Big Rocket launches, or a mix with Shuttles at the same rate. Real runs will be slower because extra units beyond a need are wasted.
- **Launch Limit:** the theoretical minimum is 3 launches, so the 4 / 6 / 8 options give hard / medium / easy.
- **SpinLaunch-only against CPUs can't be won.** It takes at least 225 days. The fastest Medium CPU (China) reaches 100% in about 117 days. So Fixed Vehicle: SpinLaunch is only offered together with Time Trial.
- **Big Rocket-only on Hard is tight.** It takes at least 90 days, against about 105 for a crash-free China. That's fine for a challenge, but worth checking in playtest.

## Answered (2026-10-11)

1. **Demo timing:** the locked Challenges screen ships in the release-day demo. That means Phase 1's locked demo state is needed before release, not just Phase 0.
2. **Faction select:** challenges keep the faction-select step.

## Open questions

1. **Alternate cargo sets:** how should each new set differ in play from the standard one? Examples: mostly large pieces, awkward shapes, or many small pieces. These need your sketches, as the original sets did.

## Phase 0 status (2026-10-11)

Implemented on `feature/challenge-rules`. Two changes from the plan above:

- **Piece sets:** the existing `CARGO_PIECE_SETS` stays as the standard set. A new `PIECE_SETS` lookup maps set id → set. A set that leaves out a vehicle falls back to the standard pieces.
- **Record key:** `get_record_key()` moves to Phase 1, because it depends on how `ChallengeData` defines modifier parameters.

## Phase 1 status (2026-10-11)

Implemented on `feature/challenge-rules`, along with the Phase 2 quick-win modifiers: Time Trial, One Life, Launch Limit (4 / 6 / 8), Fixed Vehicle and Extreme Rivals.

- **Challenges in the menu.** The opening menu has a CHALLENGES button. The Challenges screen leads on to faction select, which shows the active challenge.
- **Start always means a normal match.** The last challenge you built is kept and pre-filled the next time the Challenges screen opens.
- **Records** are saved in `user://challenge_records.cfg`. A record counts only wins: fewest days, then fewest launches.
- **Demo build:** the screen is visible, but every control is disabled, with the line "LOCKED: challenges are available in the full game."
- **Visual check done.** Screenshots of the opening menu, Challenges screen, faction select, strategy screen, game over and demo lock were reviewed at 1920×1080.
- **Still open:**
  - Random Needs (Phase 2)
  - Alternate cargo sets (Phase 3)
  - Editor-tunable layout values for the Challenges screen, if you want to hand-place it like the other screens

Outside the plan: `Main.gd` still has unused `_format_needs` / `_format_competitors` helpers that read the constant requirements. They're dead code and nothing calls them.
