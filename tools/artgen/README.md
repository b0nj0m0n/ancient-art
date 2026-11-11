# artgen: rig-ready cut-paper figures from a written spec

Phase 2 of the art pipeline (vector structure). A spec file names a template and a
set of colours; `artgen.py` writes one SVG per body part plus the rig data Godot
needs to assemble and pose them. Standard library only, any Python 3.9+.

```
python tools/artgen/artgen.py tools/artgen/specs/ashigaru_spearman.json art/units/ashigaru_spearman
```

## Output

- `parts/<name>.svg`: one file per body part, cropped to that part.
- `parts/<name>_edge.svg`: white silhouette of the part, grown by the cut-paper
  edge width. The game draws it under the part as the pale paper border and shadow.
- `rig.json`: for each part its parent, pivot, texture origin, size, draw order and
  tint, plus named poses (rotation in degrees per part) and animations
  (lists of `[pose, seconds]` steps).
- `preview/`: assembled figure, poses strip and the exploded parts sheet. The
  folder holds a `.gdignore`, so Godot neither imports nor exports it.

## Coordinates

Feet at (0, 0), facing right (+x), up is -y, 10 units = 1 game unit. This is the
frame `scripts/view/soldier_figure.gd` uses, ten times larger.

To place a part in Godot: node position = its pivot minus its parent's pivot;
sprite offset = `texture_origin` minus pivot; rotate the node to pose it.

## In the game

`scripts/view/rigged_figure.gd` reads `rig.json` and draws the parts. A troop uses
rigged art when its `rig_path` (in `data/troops/*.tres`) points at a `rig.json`;
leave it empty for the simple built-in figure. The Poses button in the HUD opens a
sheet of every pose.

Parts marked `"tint": "side"` or `"mon"` are stored white and coloured at draw time
with the side's banner and crest colours.

## Upgrading a part later

The game loads whatever file `rig.json` names. To replace a vector part with a
painted one, save a PNG the same size as the part's `size` (or any multiple of it),
with the same placement, and change that part's `texture` to the PNG. Poses, pivots
and code stay as they are. Re-running `artgen.py` rewrites `rig.json` and the SVGs,
so keep painted parts under a different file name.

## Adding a unit

Copy a spec and change the colours or options. A new body shape (armoured samurai,
archer) is a new template function in `artgen.py`, registered in `TEMPLATES`.

## Style source

Colours come from `art/reference/analysis/palette.json`; drawing conventions from
`style_bible.json` (late Edo warrior-print cluster): closed ink keyline of constant
weight, flat fills, small repeat motifs, lacing drawn as stripes.

The SVGs avoid patterns, filters and clip paths so Godot's SVG importer can read them.
