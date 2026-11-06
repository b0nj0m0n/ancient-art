class_name SideSetup
extends Resource
## One side of a skirmish: its colours and its squads (up to 5).

@export var side_name: String = "Left"
## Banner and sashimono colour.
@export var banner_colour: Color = Color("2f4a7a")
## Colour of the crest (mon) on the banners.
@export var mon_colour: Color = Color("f4efe2")
@export var squads: Array[SquadSetup] = []
