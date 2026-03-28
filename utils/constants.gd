class_name Constants

const GROUP_PLAYER := "player"
const GROUP_FOLLOWING_CREATURES := "following_creatures"
const GROUP_TAMED_CREATURES := "tamed_creatures"

## Padding beyond combined collision radii for interaction checks (see Node2DUtils.is_within_interaction_range).
## Used when checking if a creature can actually interact (eat, etc.). Wider than [constant INTERACTION_APPROACH_STOP_MARGIN]
## so the creature can interact slightly before translation fully "holds" at the tighter stop distance.
const DEFAULT_INTERACTION_MARGIN: float = 6.0

## Tighter margin for when to STOP moving toward an interaction target (movement uses this; interaction uses [constant DEFAULT_INTERACTION_MARGIN]).
## Must be less than [constant DEFAULT_INTERACTION_MARGIN] so the hold distance is inside the interaction band.
const INTERACTION_APPROACH_STOP_MARGIN: float = 2.0

## Extra gap beyond combined hitbox radii for center-based combat hold / chase spacing (world units).
const DEFAULT_COMBAT_APPROACH_STANDOFF: float = 2.0

## When closer than this (center distance, world units), seek the target's actual position instead of the intercept prediction to reduce jitter with fleeing prey.
const INTERACTION_CLOSE_BLEND_DISTANCE: float = 56.0

const Z_INDEX_TERRAIN := 0
const Z_INDEX_VEGETATION := 10
const Z_INDEX_OBJECTS := 20
const Z_INDEX_SMALL_CREATURES := 100
const Z_INDEX_PLAYER := 200
const Z_INDEX_BIG_CREATURES := 300
const Z_INDEX_FOLIAGE := 500
const Z_INDEX_FLYING_CREATURES := 1000
