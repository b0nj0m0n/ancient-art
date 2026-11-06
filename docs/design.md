# Ancient Art of War Reimagined — Base Design (v0.1)

Working title TBD. A modern reimagining of *The Ancient Art of War* (Broderbund, 1984), set in Sengoku-era Japan, rendered as a living painted-paper world. Target: iPhone, landscape. Primary audience: Ben, with an option to ship later.

## 1. Design Pillars

- **Organisational management, not tactics.** The player's skill is structuring an army, spotting talent and delegating well, not micro-control.
- **Command friction.** Orders travel by runner and may not arrive. You learn about the world through reports filtered by your subordinates' skill.
- **Individuals you get attached to.** Every soldier and camp follower is a unique person with hidden traits who grows through experience.
- **A grand army progressing.** The game must never bog down in small details. Routines and exception reports keep the pace moving.
- **Historical fiction with a hidden layer of legend.** Grounded in real Sengoku Japan, with yokai, spirits and legend discovered only by exploring.

## 2. Setting and Tone

- Historical Japan, as accurate as practical: real clans, provinces and politics.
- The player picks a **start year**, which sets the political landscape of the warring states.
- The player picks a **faction or origin**: a great clan, a small village, an uprising, and so on.
- **Mystical layer:** oni, dragons, spirits, witches and other folklore exist but are rare and found only through exploration, more often far from home.
- **Art direction:** Japanese painting meets Paper Mario. Rice-paper textures, layered cut-paper dioramas and a watercolour or sumi-e palette.

## 3. The Commander and the End Condition

- **Character creation in the style of Cataclysm: Dark Days Ahead.** Spend points on origin, upbringing, advantages and drawbacks, for example noble birth or a warrior-monk raised in a monastery.
- The commander has real skills (observation, communication, negotiation, combat and others) and can fight in skirmishes.
- The commander ages as the days pass, and can be assassinated.
- **Death is always game over.** There are no heirs and no succession.
- **Victory:** unify Japan.

**Humble starts:** most stories begin with the commander alone or with a tiny band, like a ronin. The chosen scenario (runaway, rebel, royal family and so on) sets who joins first, and the army grows from there.

## 4. Time Scales (the camera sets the clock)

| View | Approximate pace |
| --- | --- |
| Overworld map | 1 second of play ≈ 1 day |
| Battle view | 1 second ≈ 10 minutes |
| Skirmish playback | about 1 minute per skirmish |

## 5. Core Loop: The Commander's Day

- Each day the commander has about **12 one-hour slots** of attention.
- Possible uses of an hour: inspect a unit or facility (medical, kitchen, smithy, defences), boost morale, negotiate, observe, **read a detailed after-action report**, or **issue new orders** to an army.
- Results depend on the commander's skills. A good observer finds more problems, and a good communicator raises morale.
- **Routines:** repeat yesterday's schedule, or run a set schedule until an exception occurs.
- Attention is the scarce resource. The army should always be bigger than 12 hours can cover.

## 6. Reports and Management by Exception

- Every morning a **commander's report** lists notable events from each group.
- Reports are **filtered by the reporting officer's communication and organisational skill**, so a weak lieutenant gives a noisy or incomplete picture.
- Notable events happen when capability, experience and luck line up, in either direction. Examples: "Oshii found a wood cache." "The stew was exceptional thanks to foraged mushrooms." "Defences finished two hours early." "Five more died in the hospital."
- The player's job is to turn noise into signal, then reassign, promote and restructure.

## 7. The Individual System

- Every person has hidden underlying attributes (physical, mental, social), a fixed hidden personality, a background and a personal history.
- **Stats are hidden.** You can only infer talent from how fast someone levels up in their assigned role.
- **Growth means stats rise with practice.** Personality does not change.
- **Fit matters:** a natural cook stuck building defences stagnates. Reassigning them is the core gameplay.
- **Visual identity:** uniforms plus individual clothing and markings so you can tell people apart in paintings.
- **Fates:** killed, wounded, sick, permanently disabled, demoted or sent home as a casualty. Losing a veteran should hurt.
- Relationships are light for now. Personal stats matter more than squad bonds.

**Scale and delegation**

- Everyone in the world is simulated as an individual, but your **direct circle stays at about 20 named people**: lieutenants, governors and group leaders. More than that becomes a drag.
- Each leader manages their own people, which mirrors real spans of control.
- **The game grows with you.** Early on, with a small band, you can drill down and reassign individuals yourself. As the kingdom grows, you have to rely on your governors and leaders.
- **Fuzzy knowledge of people:** what you see of each person is an estimate shown in the interface. It sharpens with time invested and the commander's skill at reading people, and it can turn out to be wrong.
- At the top, your job is finding good people, promoting them and letting them handle the details.
- Named characters outside the army, such as alliance offers and family politics, may come later.

**Job experience and ratings (no visible stats)**

- **Job mastery, Final Fantasy style:** the longer someone works a job, the better they get at it. Making a promising soldier a samurai early produces a better samurai later.
- **Natural gifts** such as athleticism speed up growth, but they're never shown as numbers.
- **No visible stats.** There is no strength score in the style of Dungeons & Dragons.
- **Commander's ratings:** after each battle or task, the leader rates each person. This uses a traditional Japanese visual, for example abacus beads or knots (to be chosen).
- **History view:** shows the latest rating plus an average and median over a recent period, as a rough record rather than a full distribution.
- **Ratings are filtered** by the rater's own skill. A poor judge of people gives noisy ratings, which leads to worse promotions.

**Reports, box scores and audits**

- **Sortable rosters:** sort and filter people from best to worst, or worst to best, on any metric.
- **Box score of observable outcomes:** kills, damage dealt, damage taken, wounds sustained, casualties and battles survived.
- **Complex underneath, simple on top:** the hidden mechanics are rich, but the player manages through these observable numbers.
- **Reports are filtered too:** a sloppy lieutenant's ratings and counts can be inflated, deflated or missing.
- **Audits:** spending a commander hour observing a group in person shows the true picture, which reveals both the troops and how reliable their officer's reports are.

**Army review (a commander hour)**

- **Hidden skills per person (initial list):** hand-to-hand, sword, spear, bow, armour use, speed and tactical judgement.
- **A review doesn't re-rate everyone.** It surfaces a random handful of people and also re-rates your lieutenants.
- **Chance of noticing** rises with both the commander's judgement and the size of the gap between the current estimate and the truth. Even a mediocre judge notices a huge gap.
- **Size of the correction** scales with judgement. Each review moves the estimate a fraction of the way toward the truth, plus some noise.
- **Example:** true skill 90, current estimate 50. A poor judge revises to about 55. A good judge revises to about 80.
- Poor judges need many reviews and still get noisy results. Good judges make large, useful corrections.

```latex
\text{new estimate} = \text{old} + k_{\text{judgement}} \times (\text{true} - \text{old}) + \text{noise}
```

**Command hierarchy and cascading reviews**

- **Levels:** kingdom, then armies (dots on the overworld map), then detachments (working groups posted on a road, a ridge or in a forest, seen when you zoom in), then squads, then individuals. Possible historical names: *sonae* for a Sengoku-era combined-arms division and *kumi* for a small group (to be verified).
- **Skirmishes start** when an enemy runs into one of your detachments.
- **An army review covers the whole army,** with the hour split among the general's direct reports. It cascades: first it works out which lieutenants need attention, then, depending on how accurate that is, it goes one level down.
- Army reviews and camp reviews are separate activities.
- **Span of control is the core trade-off:** more direct reports and more detachments means less attention each and less accurate assessments. Fewer reports means each leader must be stronger.

**Design intent: a leadership training tool.** Beneath the Japanese art and war theme, the game is meant to be a realistic leadership exercise: delegation, spans of control, judging people, reporting noise and promoting talent.

The principles are taught **only implicitly**, through consequences. The game never explains or names them, and it is always a game first.

## 8. Camp and Camp Followers

- Alongside the soldiers there is an **army of camp followers** grouped by role: smiths, cooks, medics, gatherers, defence builders and scouts, among others.
- The player never assigns tasks. You place people in groups and choose who leads each group.
- **Smiths** set weapon quality and can invent new weapons. **Cooks** affect food quality, morale and disease. **Builders** set camp defences.
- **Group size trade-off (spans of control):** larger groups carry higher communication costs and more wasted effort. Smaller groups lack capability.
- A day's work is a set of required tasks that each team completes according to its capability, experience and luck.

## 9. Overworld

- Shown as a living ink painting being drawn on rice paper.
- The player gives armies orders and watches them carry those orders out in real time.
- **Runners** carry changed orders. Delivery is not guaranteed. Supplies are sent the same way and can also fail to arrive.
- **Villages:** pillage (most supplies, worst reputation), raid and occupy (some supplies and recruits, little information), or befriend and trade (supplies plus information, no recruits taken by force).
- **Reputation** with villages, territories and factions shapes the world. Friendly regions support you but drain your resources. Hostile regions may launch guerrilla attacks.
- **Recruitment:** each faction starts with a few unit types. More types can be recruited from villages and regions.
- **Rare events and discoveries:** for example a hermit master in a cave, or capturing gunpowder technology.
- **Technology** isn't researched directly. It unlocks through discoveries, alliances and castles you hold and develop.
- All storytelling is generated offline from systems and event templates, with no live AI model.

## 10. Battles and Skirmishes (base rules; detailed design is the next stage)

- Inspired by the original's side-view battles: **2D, left versus right**, landscape only.
- **Scale:** a skirmish usually involves about 30 people, 50 at most. An army is up to **5 squads**.
- **Terrain:** height along the left-to-right line (charging downhill versus fighting uphill), woods as cover that blocks arrows and suits guerrilla tactics, and rivers with bridges as choke points.
- **Slight depth:** stacked paper layers from front to back give some depth for readability.
- **No combat triangle.** Units have several attributes (armour, reach, speed, morale, ranged damage and so on), and matchups emerge from how they interact.
- Unit ideas: samurai, ashigaru spearmen, archers, fast skirmishers, and ninja or spies.
- **Scouting:** on the overworld, enemy armies appear as rough illustrated numbers, with accuracy set by your scouts' quality. Facing a much larger force, you can order a squad to scatter and regroup somewhere else.
- **Pre-battle:** the clash generates a painted battle map. You place each squad in your home third, and an opening phase lets you retreat to the overworld.
- **Skirmishes play live, and you steer like a big ship.** Tap a squad, then either point it at an enemy squad to attack or press retreat to scatter. The individuals inside the squad react on their own.
- **Command bar:** every order spends the bar, and the bar refills at a rate set by the commander's communication skill. A great communicator can coordinate all five squads tightly. A poor one gives orders rarely.
- **The commander is always present** inside one squad. You can throw that squad into the fight or hold it back as an honour guard. If the commander dies, the game ends.
- **Morale and momentum:** winning raises morale and losing drains it. Poorly drilled or low-morale squads can rout, for example after charging into massed archers.
- **Pitched battles:** a representative series of skirmishes, not a simulation of 10,000 people.

**Combat feel, troop types and spoils**

- **Fun over formulas,** to be tuned by playtesting. Possible base is Lanchester-style attrition (melee counts roughly linearly, ranged roughly squared), plus individual attributes and terrain modifiers, kept away from spreadsheet maths.
- **Luck always matters, but within limits:** sound decisions usually play out well, and only terrible luck ruins them. Min-maxing shouldn't guarantee results.
- **No cavalry** (they'd be hard to draw, and they were a small elite in the Sengoku period anyway).
- **Spearmen (ashigaru):** cheap, numerous, the backbone of the army.
- **Samurai:** few, expensive and heavily armoured. They are clearly the best fighters and can usually cross the field under fire.
- **Skirmishers:** fast and lightly armoured. They may not survive the crossing, but once they reach archers they slaughter them.
- **Archers:** deadly against a lone attacker, but too inaccurate to stop a massed charge.
- **Weapon wear:** gear degrades with use.
- **Spoils of war:** captured armour and weapons are either issued as they are or broken down by smiths into new kit.
- **Samurai capacity:** the estates and land you hold set how many samurai you can support, since stipends were paid in koku.
- **Promotion to samurai** costs gear plus an ongoing koku stipend, and it depends on spotting talent first.

## 11. Aftermath: Routs, Stragglers and Prisoners

- **Stragglers:** soldiers who leave the field each roll to reach camp, based on morale, character and wounds. Those who fall on the field stay there. Lightly wounded soldiers with good morale usually make it back.
- **After-action report:** lists who returned, who is missing, who was wounded and who was captured.
- **Prisoners** form their own part of the camp. They are used only for exchange, and are never recruited or mistreated.
- **Hidden value:** a prisoner's qualities stay hidden like everyone else's. You see their physical condition, and you can infer their worth from the price the enemy puts on them.
- **Negotiation model:** every prisoner has a hidden true value. Each side sees an estimate whose accuracy depends on its judge of character. The enemy asks a price, you make a bundled offer (for example a commander plus several soldiers), and negotiation skill decides where in the gap the deal lands.
- Winning enemies over to your side is parked for later.
- **Losing a skirmish** costs reputation, not supplies, because an army carries its supplies with it.

## 12. Economy, Allegiance and Governance

- **Currency:** koku of rice, so harvests are your treasury. Bad seasons and burned fields hurt directly.
- **Taxes:** a levy slider per region. Higher taxes fund the army but drain allegiance.
- **Allegiance replaces territory:** every area has an allegiance level that grows over time when it is safe and prosperous. Garrisons that keep bandits away, good harvests and fair treatment raise it.
- **Setbacks:** bandits, bad harvests and other random events lower allegiance.
- **Castles** are the centre of a region. Small and medium towns can be made into garrisons.
- **Run by policy:** like camp, castles and garrisons are managed through attention levels and policies, never action by action.
- **Governors** are nominated from your own army, so every talented officer you appoint is one fewer leading in the field.
- **Neglect, not intrigue:** there are no scheming officers. A region that is under-supplied, over-taxed or ignored slides in morale and allegiance until it is overrun or breaks away, even under a loyal governor.
- Dynasty and marriage alliances are parked for later.

## 13. Open Questions

- How many simulated individuals can the game support before performance or readability suffer?
- How many armies or sub-commanders can you run at once?
- How should hidden attributes and level-up rates work mathematically?
- Which interaction model replaces rock-paper-scissors for combat matchups?
- How quickly does the command bar refill, and what does each order cost?
- How do reputation and faction diplomacy work in detail?
- What exactly do castle policies and attention levels control?

## 14. Next Stage

- **Engine:** Godot, using GDScript (free, strong 2D, Python-like scripting).
- **First prototype:** one skirmish with five squads per side, the command bar, morale and routs, on a simple paper-style hillside, to test whether it's fun.

Design the battle interaction in detail, then build a playable prototype to test whether it's fun before adding more systems.

## 15. Skirmish Prototype Decisions

Decisions made by Ben for the first prototype.

- **Squad size:** up to 10 people per squad, up to 5 squads per side.
- **First test matchup (10 v 10):**
  - Side A: one samurai squad of 5 and one archer squad of 5.
  - Side B: one ashigaru squad of 10.
- **Squad placement is in the prototype.** Before the fight, each side places its squads in its home third.
- **Terrain features:** trees on the ashigaru side, and a town on the samurai and archer side.
