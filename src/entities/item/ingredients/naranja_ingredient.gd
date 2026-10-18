extends BaseItem

func _process(delta: float) -> void:
	super._process(delta)
	if is_dragging:
		_verify_fruits()

func _verify_fruits() -> void:
	var overlapping_areas = $Area2D.get_overlapping_areas()
	
	for area in overlapping_areas:
		var target = area.get_parent()

		if target == self: continue
		if target is BaseItem and target.data and target.data.item_id == "exprimidor":
			print("EXPRIMIR")
			#successful_drop = true
			#queue_free()
			#break

