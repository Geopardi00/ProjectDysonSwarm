extends RefCounted
class_name ChallengeRecords

# Personal bests per challenge combination, saved apart from settings.cfg.
# A record is the best win: fewest days, then fewest launches.

const DEFAULT_PATH := "user://challenge_records.cfg"
const SECTION := "records"

var file_path := DEFAULT_PATH
var records: Dictionary = {}


func load_records(path: String = DEFAULT_PATH) -> void:
	file_path = path
	records.clear()
	var config := ConfigFile.new()
	if config.load(file_path) != OK or not config.has_section(SECTION):
		return
	for key: String in config.get_section_keys(SECTION):
		var record = config.get_value(SECTION, key, {})
		if record is Dictionary:
			records[key] = record


static func format_record(record: Dictionary) -> String:
	if record.is_empty():
		return "not cleared yet"
	var launches := int(record["best_launches"])
	return "%d days, %d %s" % [int(record["best_days"]), launches, "launch" if launches == 1 else "launches"]


func get_record(record_key: String) -> Dictionary:
	return records.get(record_key, {}).duplicate()


func has_record(record_key: String) -> bool:
	return records.has(record_key)


# Saves a finished run and reports whether it beat the previous best.
func submit_result(record_key: String, player_won: bool, days: int, launches: int) -> Dictionary:
	var previous := get_record(record_key)
	var is_new_best := player_won and (
		previous.is_empty()
		or days < int(previous["best_days"])
		or (days == int(previous["best_days"]) and launches < int(previous["best_launches"]))
	)
	if is_new_best:
		records[record_key] = {"best_days": days, "best_launches": launches}
		_save()
	return {"is_new_best": is_new_best, "previous": previous}


func _save() -> void:
	var config := ConfigFile.new()
	for key: String in records.keys():
		config.set_value(SECTION, key, records[key])
	var error := config.save(file_path)
	if error != OK:
		push_warning("Could not save challenge records to %s (error %d)." % [file_path, error])
