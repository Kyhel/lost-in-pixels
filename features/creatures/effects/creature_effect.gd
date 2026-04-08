class_name CreatureEffect
extends Resource

enum Type {
	NONE,
	ADDITIVE,
	MULTIPLICATIVE,
	OVERRIDE
}

@export var type: Type = Type.NONE
@export var unique: bool = false
