# Ancient Art of War Reimagined

A modern mobile reimagining of *The Ancient Art of War* (Broderbund, 1984), set in
Sengoku-era Japan and rendered as a living painted-paper world: Japanese painting
meets Paper Mario.

**Read `docs/design.md` before starting any task.** It is the source of truth for
the game design. If a request conflicts with it, point that out and ask before
building.

## What kind of game this is

- A management game, not an RTS and not a reflex game. The player makes a few
  high-level choices and the simulation plays them out while the player watches.
- The player's skill is organising an army: spotting talent, delegating, spans of
  control. Skill is never fast tapping.
- Every soldier and camp follower is an individual with hidden stats who grows
  through practice. **Stats are never shown as numbers.** The player sees only
  observable outcomes and filtered, noisy reports.
- Battles are 2D side-view, left vs right, landscape only. Height, terrain and
  speed all act along that one line. Stacked paper layers give slight depth.
- All storytelling is generated offline from systems and event templates. The
  game does not call any live AI model.

## Platform and tech

- **Engine:** Godot 4.x, scripted in **GDScript**. Use typed GDScript where it's
  practical.
- **Target:** iPhone, landscape, touch input. Design every interaction for a
  thumb on a phone screen. There is no hover and no right-click.
- **Playtest build:** a Godot Web (HTML5) export deployed to GitHub Pages, so Ben
  can play each build in his phone's browser. Keep the web export working at all
  times.
- Native iOS export comes later. Don't add anything that blocks it.

## Current milestone: skirmish prototype

From `docs/design.md` §14: one skirmish with **five squads per side**, the
**command bar**, **morale and routs**, on a **simple paper-style hillside**. The
goal is to test whether the battle is fun. Build nothing beyond that until Ben
says the prototype is fun.

- Placeholder art is fine. Flat cut-paper shapes on a rice-paper background,
  with a watercolour or sumi-e palette.
- Interaction: tap a squad, then tap an enemy squad to attack, or press retreat.
  Each order spends the command bar.
- The commander is always inside one squad. If the commander dies, the game ends.
- Use the troop types in design §10: ashigaru spearmen, samurai, skirmishers and
  archers. There is no cavalry.

## How to work

- Work in small steps: one feature or fix per change. Each change must leave the
  game in a playable state.
- Before a big feature, write a short plan and wait for Ben to approve it.
- Keep tunable numbers (speeds, morale, damage, command-bar refill) in data or
  resource files, not hard-coded, so Ben can tune them through playtesting.
  Fun beats formulas.
- Use a seeded random number generator so a skirmish can be replayed exactly.
- When a design question comes up that `docs/design.md` doesn't answer, ask.
  Don't invent major mechanics. Once Ben decides, add the answer to
  `docs/design.md`.
- Ben reviews from the Claude mobile app. Summaries should be short and plain:
  what changed, how to try it, and what to look for.

## Repo layout (planned)

- `docs/`: design documents
- `art/reference/`: Japanese battle and landscape prints. Use them as style
  reference only, never as game assets (see its README)
- `art/units/<unit>/`: rigged cut-paper art for one troop type: part textures and
  `rig.json` (parts, pivots, poses, animations). Made by `tools/artgen`; drawn by
  `scripts/view/rigged_figure.gd`
- `tools/artgen/`: Python generator that turns a written spec into a unit folder
  (see its README)
- `project.godot`: the Godot project root
- `scenes/`, `scripts/`, `data/`, `art/`: game content (create these as needed)
