# Progress and next steps

A hand-over note so any Claude session (cloud or laptop) can pick up the work.
Update it at the end of each step.

## How we work
- **One Claude edits code at a time.** Ben develops on his laptop:
  `C:\Users\benja\Projects\ancient-art` (Windows, Godot 4.6.1, GitHub Desktop).
  Keep the repo out of OneDrive.
- Test locally in Godot (F5). Publish to the phone build by committing, pushing
  a branch and opening a pull request; Ben merges. `main` is what's live at
  https://b0nj0m0n.github.io/ancient-art/.
- `tests/test_battle.gd` must pass before pushing:
  `godot --headless --script tests/test_battle.gd`
  (on Windows, use the path to the Godot .exe instead of `godot`).

## Done
1. Godot project, web export to GitHub Pages, build label, phones always load
   the latest build, size guard on the game data.
2. Armies, trees and town; watercolour style frame (`docs/art.md`).
3. Advance, then hand-to-hand fighting with Ben's spear rule (`docs/design.md` §15).
4. Rigged ashigaru from `tools/artgen` (laptop work, merged).
5. Tap orders and the command bar: select your squad, tap an enemy to attack,
   or Retreat. Orders are logged, so battles replay exactly.
6. On-screen hints that teach the controls (branch
   `claude/affectionate-thompson-t8jqg2`; not merged yet at the time of writing).

## Next (the rest of the prototype milestone, in suggested order)
- **Morale and routs:** losing drains morale, winning lifts it; shaken or
  poorly drilled squads break and run (design §10). Needs a short plan and Ben's OK.
- **Archers shooting:** deadly against a lone attacker, too scattered to stop a
  massed charge (design §10).
- **Commanders:** losing your commander loses the skirmish (design §15).
- **Placement:** sides take turns placing one squad each on a 5-second timer.
- **AI opponent:** the computer's side gets its own command bar and decisions.

## Open questions for Ben
- Archers: keep waiting and knife-fighting, or shoot next?
- Balance target: currently roughly even (ashigaru 50-55%).
- Optional: a `/preview/` web build of every pushed branch, for phone testing
  without merging.
