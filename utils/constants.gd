class_name Constants

const GROUP_PLAYER := "player"
const GROUP_FOLLOWING_CREATURES := "following_creatures"

## Padding beyond combined collision radii for interaction checks (see Node2DUtils.is_within_interaction_range).
const DEFAULT_INTERACTION_MARGIN: float = 6.0

## Extra gap beyond combined hitbox radii for center-based combat hold / chase spacing (world units).
const DEFAULT_COMBAT_APPROACH_STANDOFF: float = 2.0

## When closer than this (center distance, world units), seek the target's actual position instead of the intercept prediction to reduce jitter with fleeing prey.
const INTERACTION_CLOSE_BLEND_DISTANCE: float = 56.0
