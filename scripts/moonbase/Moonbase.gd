extends RefCounted
class_name Moonbase

var remaining_requirements: Dictionary = {}
var total_required := 0
var useful_delivered := 0
var wasted_materials := 0


func setup(requirements: Dictionary) -> void:
	remaining_requirements = requirements.duplicate(true)
	total_required = 0
	useful_delivered = 0
	wasted_materials = 0
	for amount: int in remaining_requirements.values():
		total_required += amount


func apply_delivery(manifest: Dictionary) -> Dictionary:
	var used: Dictionary = {}
	var wasted: Dictionary = {}

	for material: String in remaining_requirements.keys():
		var delivered := int(manifest.get(material, 0))
		var needed := int(remaining_requirements[material])
		var accepted := mini(delivered, needed)
		var overdelivered := maxi(delivered - accepted, 0)

		remaining_requirements[material] = needed - accepted
		used[material] = accepted
		wasted[material] = overdelivered
		useful_delivered += accepted
		wasted_materials += overdelivered

	return {
		"used": used,
		"wasted": wasted,
		"used_total": _sum_values(used),
		"wasted_total": _sum_values(wasted),
	}


func get_remaining_total() -> int:
	return _sum_values(remaining_requirements)


func get_readiness_percent() -> float:
	if total_required <= 0:
		return 100.0
	return clampf(100.0 * (1.0 - (float(get_remaining_total()) / float(total_required))), 0.0, 100.0)


func is_complete() -> bool:
	return get_remaining_total() <= 0


func _sum_values(values: Dictionary) -> int:
	var total := 0
	for amount: int in values.values():
		total += amount
	return total
