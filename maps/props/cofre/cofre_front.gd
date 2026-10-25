extends PanelContainer

var inventario: Inventario

func initialize(inventory: Inventario, nombre: String, columns: int = 0):
	inventario = inventory
	%name.text = nombre
	if columns != 0:
		%container.columns = columns
	else:
		var cant_slots = inventario._slots.size()
		for i in range(2, 7, 1):
			if cant_slots % i == 0 and cant_slots <= i**2:
				%container.columns = i
				break
		if %container.columns == 1:
			%container.columns = min(cant_slots, 4)
	var slot_scene = preload("res://game/ui/inventario/slots/slot.tscn")
	var slot_script = preload("res://game/ui/inventario/slots/ui slot.gd")
	for slot_id in inventario._slots:
		var slot = slot_scene.instantiate()
		slot.set_script(slot_script)
		(slot as UISlot).inventario = inventario
		(slot as UISlot).slot = inventario._slots[slot_id]
		%container.add_child(slot)
