class_name TameCommand
extends RefCounted

enum Kind {
	FREE,
	HEEL,
	STAY,
}

## Utility score when this command is active (between wander 0.1 and hungry eat 1.0).
const ACTIVE_SCORE := 0.4
