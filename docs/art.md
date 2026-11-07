# Art Direction (draft v0.1)

The source of truth for how the game looks, as `design.md` is for how it plays.
Built from the reference images in `art/reference/`. **Draft:** Ben edits this,
and items marked *(decide)* need his call.

## 1. The look in one line

A battle painted on a gold folding screen, with its soldiers drawn like
woodblock-print warriors, then cut out and stood up in layers like a paper diorama.

- **Gold screens (byōbu)** give the stage: gold clouds, flat-topped pines,
  armies as small vivid clusters. They were painted during the Sengoku and
  Momoyama era itself, so they are the period's own way of showing its battles.
- **Woodblock prints (ukiyo-e)** give the figures and the colour: ink outlines,
  flat colour, patterned cloth, graded skies.
- **Paper Mario** gives the physical feel: every element is a piece of paper
  that stands slightly off the page and casts a soft shadow.

## 2. What the references actually do

### Line
- Every figure, tree and building has a **dark ink outline** (sumi), thin and
  slightly uneven. It is not pure black and not a constant width. Inner lines
  mark folds, hair, lacing and armour plates.
- Our original pale "cut edge" is the opposite. The style frame tries an ink
  outline plus a faint cut shadow (see §3).

### Colour
- **Flat fills inside the outlines**, then **bokashi**: one colour fading
  smoothly into the paper or into another colour.
  - Skies: a dark indigo band at the top fading down to cream
    (`loc-01200-01271`, `loc-01300-01317`, `loc-02400-02467`).
  - Mist and the ground fade to grey near the bottom edge (`rp-1685981`, the runners).
  - Red or pink mist bands between hills (`loc-01200-01271`).
- **Palette**, measured from the scans (dominant colours, not guesses). The
  scans have aged and yellowed, so the game can run slightly fresher than these:

  | Role | Hex | Measured from |
  | --- | --- | --- |
  | Paper | `#e9dcc0` | between aged scan paper `#c7b498` and fresh `#ebcba6` |
  | Gold leaf | `#e2ca8b`, highlight `#eeda9e` | gold screen `rp-7661272` |
  | Water, sky band | `#2b3940` | gold-screen river |
  | Hills | `#566d66`, shade `#48625c` | Hiroshige hills `loc-01200-01271` |
  | Pines, far land | `#5f6644`, `#7e734d` | gold-screen pines and ground |
  | Ink | `#373637` | procession outlines `rp-7639167` |
  | Vermilion | `#c0453a` *(estimate; too small to measure cleanly)* | banners, armour |
  | Red mist | `#a18a79` (faded) | Hiroshige mist bands |

  Note how grey-teal the greens are and how pale the gold is. Our current
  hills are too yellow-green.

- Strong saturated colour goes on **people and banners**. The land stays
  quieter, so the armies read clearly.

### Pattern
- Clothing carries **pattern**: checks, waves, tie-dye, crests, lacing bands
  (`rp-1685981`, `rp-7639167`, `rp-7132442`).
- This is how prints make every figure an individual, which fits our design.
  Each soldier should get a pattern from their look seed, not just a sash colour.

### Figures and motion
- Poses lean into the action: wide stances, bodies tilted forward when running,
  clothes flaring behind (`rp-1685981`, `rp-11923978`).
- Our upright, gently swaying figures read as stiff by comparison. Movement in
  the battle should lean and stride, not glide.
- Faces are a few ink strokes. Armour is busy, with many small coloured plates
  and lacing; heads and helmets are large and readable.

### Stage, terrain and space
- **Gold clouds (kumo)** with a scalloped edge and a fine raised pattern hide
  whatever doesn't matter and frame the action (`rp-7637591`, `rp-7661272`,
  `rp-8250534`). For us they can fill the empty sky, soften the screen edges and
  sit behind the interface.
- **Pines** are dark, flat-topped pads on bent trunks. Our pines are in the
  right direction but need ink outlines and more pads per tree.
- **Hills** are smooth flat colour with a darker bokashi along the edge and a
  few fine ink ridge lines (`loc-01200-01271`).
- **Water** is flat indigo with white curling crest lines (`rp-7661272`,
  `rp-7639335`).
- **Lots of empty paper.** Figures often stand on plain ground. Emptiness is
  part of the style, not something to fill.

### Paper and frame
- The paper and fibre grain show through every colour.
- Prints have a thin border, and **red cartouches** (title boxes with vertical
  text) plus **red seals (hanko)**.
- Natural homes for interface elements: squad names, the command bar, end-of-battle text.

## 3. How we get there (agreed process)

Painted pieces, animated like paper cut-outs, under one watercolour shader.

| Layer | Source | Motion |
| --- | --- | --- |
| Sky, mist, gold clouds | Procedural washes and shaders (Claude) | Slow drift; mist bands slide |
| Hills, water, ground | Procedural washes with bokashi edges and ink ridge lines (Claude) | Slight parallax between paper layers |
| Trees, town | Painted sprites with ink outlines | Pine pads sway |
| Soldiers | **Midjourney** images, cut into parts by Ben (decided) | Cut-out rigs (Skeleton2D), animated at 12 fps |
| Whole screen | One watercolour shader: paper grain, pigment pooling at edges, slight hand-drawn boil | Subtle shimmer |

- **One rig per troop type.** Individuals differ through shader colour and
  pattern from their look seed, not separate art.
- **Budget for phones:** atlas each troop type, use compressed textures, one
  full-screen shader pass, a total art download of a few MB.
- **Generated assets are original art.** The reference prints stay reference
  only (see `art/reference/README.md`).

**Steps**
1. **Style frame:** sky, hills, mist and gold clouds plus the watercolour
   shader, judged side by side with the references. *(in progress)*
2. **Pipeline:** `art/source/` → layered PNGs → Godot import, rigs and shader.
3. **Vertical slice:** one squad fully animated on the finished hillside.
4. **Roll out** to all troop types, trees and town.

Soldier and tree art waits until the battle prototype is fun (CLAUDE.md
milestone). The style frame goes ahead now.

*(decide after seeing the style frame: ink outlines with a faint paper shadow
(used in the style frame), or the pale paper-cut edge)*

## 4. Key references

| File | Take from it |
| --- | --- |
| `rp-7637591`, `rp-7661272`, `rp-8250534` | Gold screens: clouds, pines, small vivid armies, water |
| `rp-7639167` | Side-view procession: armour detail, patterned cloth, blank ground |
| `rp-1685981` | Running crowd in profile: lean, stride, pattern, bottom fade |
| `rp-11923978` | Battle triptych: smoke as grey ink clouds, soldiers in action |
| `loc-01200-01271` | Hills: flat green, bokashi edges, red mist, ink pines |
| `loc-01300-01317`, `loc-02400-02467` | Indigo sky band, calm water, distant mountains |
| `rp-7132442`, `rp-11931299` | Dense melee: how prints show chaos and still read |

Some files are mood rather than battle reference: the sumo chart
(`rp-7660772`), the court-lady prints (`loc-00100-00154`, `loc-02600-02608`)
and the waterfall (`rp-3064476`).

## 5. Rules of thumb

- Ink outline on every cut-out, in warm ink (`#373637`). Never pure black (`#000`).
- Flat colour plus one bokashi per shape at most.
- Saturated colour on people and banners; quieter land.
- Let empty paper and gold clouds do the work. Don't fill every space.
- Readable on a phone first: silhouette and banner colour must identify a
  squad at a glance, before any detail.
- **No numbers on screen.** If text is needed, it goes in a cartouche.
