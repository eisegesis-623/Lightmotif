extends OptionButton


signal leitmotif_item_selected(value,song)
#func _set(property: StringName, value: Variant) -> bool:
	#if property == "selected":
		#selected = value
		#item_selected.emit(value)
		#return true
	#return false
func set_selected(value,song:=Controller.current_song):
	selected = value
	leitmotif_item_selected.emit(value,song)

func _on_item_selected(index: int) -> void:
	leitmotif_item_selected.emit(index,Controller.current_song)

func _ready() -> void:
	pressed.connect(_on_pressed)
	call_deferred("get_song_patterns")
	#call_deferred("set_default_selected")


func _on_pressed():
	get_song_patterns()


func set_default_selected():
	selected = Controller.current_song.patterns.size()-1

func get_song_patterns(song:=Controller.current_song):
	var selected_index = selected
	clear()
	for i in song.patterns.size():
		add_item(song.patterns[i].motif_name)
	selected = selected_index
	
	#var selected_index = selected
	#clear()
	#song.patterns.sort_custom(func(a, b): return a.motif_name.naturalnocasecmp_to(b.motif_name) < 0)
	#for i in song.patterns.size():
		#add_item(song.patterns[i].motif_name)
	#
	#if is_instance_valid($"..".associated_pattern):
		#selected = $"..".associated_pattern.index
	#else:
		#selected = selected_index
	#
	#$"..".switch_to_pattern()
	
	
	
