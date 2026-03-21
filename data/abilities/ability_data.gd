class_name AbilityData
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var icon: Texture2D
@export var unlock_rule: AbilityUnlockRule
@export var effect_script: Script
@export_multiline var discover_log_message: String = ""
@export_multiline var use_log_message: String = ""
