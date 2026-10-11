extends RefCounted
class_name ChallengeData

# Challenge modifiers the player can stack. A selection is a Dictionary of
# modifier id -> option id ("" for modifiers without options). An empty
# selection is a normal match.

const MatchRulesScript := preload("res://scripts/rules/MatchRules.gd")

const TIME_TRIAL := "time_trial"
const ONE_LIFE := "one_life"
const LAUNCH_LIMIT := "launch_limit"
const FIXED_VEHICLE := "fixed_vehicle"
const EXTREME_RIVALS := "extreme_rivals"

const MODIFIERS: Array[Dictionary] = [
	{
		"id": TIME_TRIAL,
		"name": "Time Trial",
		"description": "No rival factions. Finish the moonbase in as few days as possible.",
		"options": [],
		"incompatible_with": [EXTREME_RIVALS],
	},
	{
		"id": ONE_LIFE,
		"name": "One Life",
		"description": "A single crashed launch ends the run.",
		"options": [],
		"incompatible_with": [],
	},
	{
		"id": LAUNCH_LIMIT,
		"name": "Launch Limit",
		"description": "Complete the moonbase within a fixed number of launches.",
		"options": [
			{"id": "4", "label": "4 launches"},
			{"id": "6", "label": "6 launches"},
			{"id": "8", "label": "8 launches"},
		],
		"default_option": "6",
		"incompatible_with": [],
	},
	{
		"id": FIXED_VEHICLE,
		"name": "Fixed Vehicle",
		"description": "Only one launch vehicle may be used.",
		"options": [
			{"id": "big_rocket", "label": "Big Rocket"},
			{"id": "space_shuttle", "label": "Space Shuttle"},
			# SpinLaunch alone is too slow to beat any rival, so it needs Time Trial.
			{"id": "spinlaunch", "label": "SpinLaunch", "requires": [TIME_TRIAL]},
		],
		"default_option": "big_rocket",
		"incompatible_with": [],
	},
	{
		"id": EXTREME_RIVALS,
		"name": "Extreme Rivals",
		"description": "Rivals launch faster and crash less. Overrides the Options difficulty.",
		"options": [],
		"incompatible_with": [TIME_TRIAL],
	},
]


static func get_modifier(modifier_id: String) -> Dictionary:
	for modifier: Dictionary in MODIFIERS:
		if String(modifier["id"]) == modifier_id:
			return modifier
	return {}


static func get_default_option(modifier_id: String) -> String:
	return String(get_modifier(modifier_id).get("default_option", ""))


# Returns why a modifier cannot be switched on alongside the current selection,
# or "" when it can.
static func get_blocking_reason(selection: Dictionary, modifier_id: String) -> String:
	var modifier := get_modifier(modifier_id)
	for other_id: String in selection.keys():
		if other_id == modifier_id:
			continue
		var other := get_modifier(other_id)
		if modifier.get("incompatible_with", []).has(other_id) or other.get("incompatible_with", []).has(modifier_id):
			return "Can't combine with %s" % String(other.get("name", other_id))
	return ""


# Returns why an option cannot be picked with the current selection, or "".
static func get_option_blocking_reason(selection: Dictionary, modifier_id: String, option_id: String) -> String:
	for option: Dictionary in get_modifier(modifier_id).get("options", []):
		if String(option["id"]) != option_id:
			continue
		for required_id: String in option.get("requires", []):
			if not selection.has(required_id):
				return "Needs %s" % String(get_modifier(required_id).get("name", required_id))
	return ""


# Drops unknown or conflicting modifiers and resets options that are no longer
# allowed, so a selection is always playable.
static func sanitize(selection: Dictionary) -> Dictionary:
	var clean := {}
	for modifier: Dictionary in MODIFIERS:
		var modifier_id := String(modifier["id"])
		if not selection.has(modifier_id) or not get_blocking_reason(clean, modifier_id).is_empty():
			continue
		var option_id := String(selection[modifier_id])
		if modifier["options"].is_empty():
			option_id = ""
		elif not _has_option(modifier, option_id):
			option_id = get_default_option(modifier_id)
		clean[modifier_id] = option_id
	for modifier_id: String in clean.keys():
		if not get_option_blocking_reason(clean, modifier_id, String(clean[modifier_id])).is_empty():
			clean[modifier_id] = get_default_option(modifier_id)
	return clean


static func build_rules(selection: Dictionary) -> MatchRules:
	var clean := sanitize(selection)
	var rules: MatchRules = MatchRulesScript.new()
	if clean.has(TIME_TRIAL):
		rules.cpu_enabled = false
	if clean.has(ONE_LIFE):
		rules.max_failures = 0
	if clean.has(LAUNCH_LIMIT):
		rules.max_launches = int(clean[LAUNCH_LIMIT])
	if clean.has(FIXED_VEHICLE):
		rules.allowed_vehicles.append(String(clean[FIXED_VEHICLE]))
	if clean.has(EXTREME_RIVALS):
		rules.cpu_profile_override = "extreme"
	return rules


# Stable key for records: the same combination always gives the same key,
# whatever order the modifiers were switched on in.
static func get_record_key(selection: Dictionary) -> String:
	var clean := sanitize(selection)
	var parts: Array[String] = []
	for modifier_id: String in clean.keys():
		var option_id := String(clean[modifier_id])
		parts.append(modifier_id if option_id.is_empty() else "%s=%s" % [modifier_id, option_id])
	parts.sort()
	return "|".join(parts)


static func describe(selection: Dictionary) -> String:
	var clean := sanitize(selection)
	var names: Array[String] = []
	for modifier: Dictionary in MODIFIERS:
		var modifier_id := String(modifier["id"])
		if not clean.has(modifier_id):
			continue
		var option_label := _get_option_label(modifier, String(clean[modifier_id]))
		names.append(String(modifier["name"]) if option_label.is_empty() else "%s (%s)" % [modifier["name"], option_label])
	return " + ".join(names)


static func _has_option(modifier: Dictionary, option_id: String) -> bool:
	return not _get_option_label(modifier, option_id).is_empty()


static func _get_option_label(modifier: Dictionary, option_id: String) -> String:
	for option: Dictionary in modifier.get("options", []):
		if String(option["id"]) == option_id:
			return String(option["label"])
	return ""
