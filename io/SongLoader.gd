###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name SongLoader extends RefCounted


static func load(path: String) -> Song:
	if path.get_extension() != Song.FILE_EXTENSION:
		printerr("SongLoader: The song file must have a .%s extension." % [ Song.FILE_EXTENSION ])
		return null
	
	var file := FileAccess.open(path, FileAccess.READ)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("SongLoader: Failed to load and open the song file at '%s' (code %d)." % [ path, error ])
		return null
	
	var file_contents := file.get_as_text()
	var reader := SongFileReader.new(path, file_contents)
	
	# TODO: Add a validation step after loading, to update song data and remove invalid bits.
	
	if reader.get_version() == 1:
		return _load_v1(reader)
	if reader.get_version() == 2:
		return _load_v2(reader)
	if reader.get_version() == 3:
		return _load_v3(reader)
	if reader.get_version() == 4:
		return _load_v4(reader)
	
	printerr("SongLoader: The song file at '%s' has unsupported version %d, an empty song is created instead." % [ path, reader.get_version() ])
	return Song.create_default_song()


# Original release; due to a bug it never saved the instrument volume.
static func _load_v1(reader: SongFileReader) -> Song:
	var song := Song.new()
	song.format_version = reader.get_version()
	song.filename = reader.get_path()
	
	# Basic information.

	song.bpm = reader.read_int()
	song.pattern_size = reader.read_int()
	song.bar_size = reader.read_int()
	
	# Instruments.
	
	var instrument_count := reader.read_int()
	for i in instrument_count:
		var voice_index := reader.read_int()
		var voice_data := Controller.voice_manager.get_voice_data_at(voice_index)
		var instrument := Controller.instance_instrument_by_voice(voice_data)
		
		instrument.voice_index = voice_index
		reader.read_int() # Empty read, we can determine the type by voice data.
		reader.read_int() # Empty read, we use the color palette from reference data.
		instrument.lp_cutoff = reader.read_int()
		instrument.lp_resonance = reader.read_int()
		instrument.update_filter()
		
		song.instruments.push_back(instrument)
	
	# Patterns.
	
	var pattern_count := reader.read_int()
	for i in pattern_count:
		var pattern := Pattern.new()
		
		pattern.key = reader.read_int()
		pattern.scale = reader.read_int()
		pattern.instrument_idx = reader.read_int()
		reader.read_int() # Empty read, we can determine the color palette by the instrument.
		
		var note_amount := reader.read_int()
		for j in note_amount:
			var note_value := reader.read_int()
			var note_length := reader.read_int()
			var note_position := reader.read_int()
			reader.read_int() # Empty read, this value is unused.
			pattern.add_note(note_value, note_position, note_length, false)
		
		pattern.sort_notes()
		pattern.reindex_active_notes()
		
		pattern.record_instrument = (reader.read_int() == 1)
		if pattern.record_instrument:
			for j in 16: # Patterns can only go up to 16 notes in this version.
				pattern.recorded_instrument_values[j].x = reader.read_int() # Volume
				pattern.recorded_instrument_values[j].y = reader.read_int() # Cutoff
				pattern.recorded_instrument_values[j].z = reader.read_int() # Resonance
		
		song.patterns.push_back(pattern)
	
	# Arrangement.
	
	song.arrangement.timeline_length = reader.read_int()
	song.arrangement.loop_start = reader.read_int()
	song.arrangement.loop_end = reader.read_int()
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			channels[j] = reader.read_int()
		song.arrangement.timeline_bars[i] = channels
	
	var remainder := reader.get_read_remainder()
	if remainder > 0:
		printerr("SongLoader: Invalid song file at '%s' contains excessive data (%d)." % [ reader.get_path(), remainder ])
	
	return song


# Second version; includes instrument volume, global swing.
static func _load_v2(reader: SongFileReader) -> Song:
	var song := Song.new()
	song.format_version = reader.get_version()
	song.filename = reader.get_path()
	
	# Basic information.

	song.swing = reader.read_int()
	song.bpm = reader.read_int()
	song.pattern_size = reader.read_int()
	song.bar_size = reader.read_int()
	
	# Instruments.
	
	var instrument_count := reader.read_int()
	for i in instrument_count:
		var voice_index := reader.read_int()
		var voice_data := Controller.voice_manager.get_voice_data_at(voice_index)
		var instrument := Controller.instance_instrument_by_voice(voice_data)
		
		instrument.voice_index = voice_index
		reader.read_int() # Empty read, we can determine the type by voice data.
		reader.read_int() # Empty read, we use the color palette from reference data.
		instrument.lp_cutoff = reader.read_int()
		instrument.lp_resonance = reader.read_int()
		instrument.volume = reader.read_int()
		instrument.update_filter()
		
		song.instruments.push_back(instrument)
	
	# Patterns.
	
	var pattern_count := reader.read_int()
	for i in pattern_count:
		var pattern := Pattern.new()
		
		pattern.key = reader.read_int()
		pattern.scale = reader.read_int()
		pattern.instrument_idx = reader.read_int()
		reader.read_int() # Empty read, we can determine the color palette by the instrument.
		
		var note_amount := reader.read_int()
		for j in note_amount:
			var note_value := reader.read_int()
			var note_length := reader.read_int()
			var note_position := reader.read_int()
			reader.read_int() # Empty read, this value is unused.
			pattern.add_note(note_value, note_position, note_length, false)
		
		pattern.sort_notes()
		pattern.reindex_active_notes()
		
		pattern.record_instrument = (reader.read_int() == 1)
		if pattern.record_instrument:
			for j in 16: # Patterns can only go up to 16 notes in this version.
				pattern.recorded_instrument_values[j].x = reader.read_int() # Volume
				pattern.recorded_instrument_values[j].y = reader.read_int() # Cutoff
				pattern.recorded_instrument_values[j].z = reader.read_int() # Resonance
		
		song.patterns.push_back(pattern)
	
	# Arrangement.
	
	song.arrangement.timeline_length = reader.read_int()
	song.arrangement.loop_start = reader.read_int()
	song.arrangement.loop_end = reader.read_int()
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			channels[j] = reader.read_int()
		song.arrangement.timeline_bars[i] = channels
	
	var remainder := reader.get_read_remainder()
	if remainder > 0:
		printerr("SongLoader: Invalid song file at '%s' contains excessive data (%d)." % [ reader.get_path(), remainder ])
	
	return song


# Third version; includes global effects, patterns can go up to 32 notes (but recorded filter still only has 16 notes).
static func _load_v3(reader: SongFileReader) -> Song:
	var song := Song.new()
	song.format_version = reader.get_version()
	song.filename = reader.get_path()
	
	# Basic information.

	song.swing = reader.read_int()
	song.global_effect = reader.read_int()
	song.global_effect_power = reader.read_int()

	song.bpm = reader.read_int()
	song.pattern_size = reader.read_int()
	song.bar_size = reader.read_int()
	
	# Instruments.
	
	var instrument_count := reader.read_int()
	for i in instrument_count:
		var voice_index := reader.read_int()
		var voice_data := Controller.voice_manager.get_voice_data_at(voice_index)
		var instrument := Controller.instance_instrument_by_voice(voice_data)
		
		instrument.voice_index = voice_index
		reader.read_int() # Empty read, we can determine the type by voice data.
		reader.read_int() # Empty read, we use the color palette from reference data.
		instrument.lp_cutoff = reader.read_int()
		instrument.lp_resonance = reader.read_int()
		instrument.volume = reader.read_int()
		instrument.update_filter()
		
		song.instruments.push_back(instrument)
	
	# Patterns.
	
	var pattern_count := reader.read_int()
	for i in pattern_count:
		var pattern := Pattern.new()
		
		pattern.key = reader.read_int()
		pattern.scale = reader.read_int()
		pattern.instrument_idx = reader.read_int()
		reader.read_int() # Empty read, we can determine the color palette by the instrument.
		
		var note_amount := reader.read_int()
		for j in note_amount:
			var note_value := reader.read_int()
			var note_length := reader.read_int()
			var note_position := reader.read_int()
			reader.read_int() # Empty read, this value is unused.
			pattern.add_note(note_value, note_position, note_length, false)
		
		pattern.sort_notes()
		pattern.reindex_active_notes()
		
		pattern.record_instrument = (reader.read_int() == 1)
		if pattern.record_instrument:
			for j in 16: # Due to a bug, only first 16 notes record their advanced filter values.
				pattern.recorded_instrument_values[j].x = reader.read_int() # Volume
				pattern.recorded_instrument_values[j].y = reader.read_int() # Cutoff
				pattern.recorded_instrument_values[j].z = reader.read_int() # Resonance
		
		song.patterns.push_back(pattern)
	
	# Arrangement.
	
	song.arrangement.timeline_length = reader.read_int()
	song.arrangement.loop_start = reader.read_int()
	song.arrangement.loop_end = reader.read_int()
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			channels[j] = reader.read_int()
		song.arrangement.timeline_bars[i] = channels
	
	#var remainder := reader.get_read_remainder()
	#if remainder > 0:
		#printerr("SongLoader: Invalid song file at '%s' contains excessive data (%d)." % [ reader.get_path(), remainder ])
	
	## Starting MYTOOL
	load_global_parameters(reader)
	load_motif_nodes(reader,song)
	return song

static func _load_v4(reader: SongFileReader) -> Song:
	var song := Song.new()
	song.format_version = reader.get_version()
	song.filename = reader.get_path()
	
	# Basic information.

	song.swing = reader.read_int()
	song.global_effect = reader.read_int()
	song.global_effect_power = reader.read_int()

	song.bpm = reader.read_int()
	song.pattern_size = reader.read_int()
	song.bar_size = reader.read_int()
	
	# Instruments.
	
	var instrument_count := reader.read_int()
	for i in instrument_count:
		var voice_index := reader.read_int()
		var voice_data := Controller.voice_manager.get_voice_data_at(voice_index)
		var instrument := Controller.instance_instrument_by_voice(voice_data)
		
		instrument.voice_index = voice_index
		reader.read_int() # Empty read, we can determine the type by voice data.
		reader.read_int() # Empty read, we use the color palette from reference data.
		instrument.lp_cutoff = reader.read_int()
		instrument.lp_resonance = reader.read_int()
		instrument.volume = reader.read_int()
		instrument.update_filter()
		
		song.instruments.push_back(instrument)
	
	# Patterns.
	
	var pattern_count := reader.read_int()
	for i in pattern_count:
		var pattern := Pattern.new()
		
		pattern.key = reader.read_int()
		pattern.scale = reader.read_int()
		pattern.instrument_idx = reader.read_int()
		reader.read_int() # Empty read, we can determine the color palette by the instrument.
		
		var note_amount := reader.read_int()
		for j in note_amount:
			var note_value := reader.read_int()
			var note_length := reader.read_int()
			var note_position := reader.read_int()
			reader.read_int() # Empty read, this value is unused.
			pattern.add_note(note_value, note_position, note_length, false)
		
		pattern.sort_notes()
		pattern.reindex_active_notes()
		
		pattern.record_instrument = (reader.read_int() == 1)
		if pattern.record_instrument:
			for j in 16: # Due to a bug, only first 16 notes record their advanced filter values.
				pattern.recorded_instrument_values[j].x = reader.read_int() # Volume
				pattern.recorded_instrument_values[j].y = reader.read_int() # Cutoff
				pattern.recorded_instrument_values[j].z = reader.read_int() # Resonance
		
		song.patterns.push_back(pattern)
	
	# Arrangement.
	
	song.arrangement.timeline_length = reader.read_int()
	song.arrangement.loop_start = reader.read_int()
	song.arrangement.loop_end = reader.read_int()
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			channels[j] = reader.read_int()
		song.arrangement.timeline_bars[i] = channels
	
	#var remainder := reader.get_read_remainder()
	#if remainder > 0:
		#printerr("SongLoader: Invalid song file at '%s' contains excessive data (%d)." % [ reader.get_path(), remainder ])
	
	## Starting MYTOOL
	load_global_parameters(reader)
	
	var motif_nodes_size = reader.read_int()
	for i in Controller.graph.motif_nodes:
		i.free()
	Controller.graph.motif_nodes.clear()
	
	for i in range(motif_nodes_size):
		var new_node :MotifNode= load("res://myproject/GraphNode.tscn").instantiate()
		Controller.graph.create_motif_node(false,new_node)
		new_node.name = reader.read_string()
		new_node.position_offset.x = reader.read_int()
		new_node.position_offset.y = reader.read_int()
		
		new_node.graph_node_name_edit.text = reader.read_string()
		new_node.chord_progression_edit.text = reader.read_string()
		new_node.notes_edit.text = reader.read_string()
		
		var motif_controls_size = reader.read_int()
		for ii in range(motif_controls_size):
			var motif_control := new_node.add_motif_control()
			
			var pattern_index = reader.read_int()
			motif_control.leitmotifs_option.get_song_patterns(song)
			motif_control.leitmotifs_option.set_selected(pattern_index,song)
			
			motif_control.associated_pattern.motif_name = reader.read_string()
			motif_control.associated_pattern.time_signature = reader.read_string()
			
			motif_control.associated_pattern.motif_bpm = reader.read_int()
			motif_control.associated_pattern.pattern_length.x = reader.read_int()
			motif_control.associated_pattern.pattern_length.y = reader.read_int()
			motif_control.associated_pattern.key = reader.read_int()
			motif_control.associated_pattern.scale_mode = reader.read_int()
			
			motif_control.associated_pattern.additional_description = reader.read_string()
			
	## Later, once all nodes have been added...
	for i in Controller.graph.motif_nodes:
		for ii:MotifControl in i.motif_controls:
			var related_patterns_size = reader.read_int()
			for iii in range(related_patterns_size):
				var type = reader.read_int()
				#if type == 1:
					#var node_index = reader.read_int()
					#ii.associated_pattern.related_patterns.append(Controller.graph.motif_nodes[node_index])
				#elif type == 0:
					#var pattern_index = reader.read_int()
					#ii.associated_pattern.related_patterns.append(song.patterns[pattern_index])
				if type == 1:
					var node_index = Controller.graph.motif_nodes[reader.read_int()]
					if !ii.associated_pattern.related_patterns.has(node_index):
						ii.associated_pattern.related_patterns.append(node_index)
				elif type == 0:
					var pattern_index = song.patterns[reader.read_int()]
					if !ii.associated_pattern.related_patterns.has(pattern_index):
						ii.associated_pattern.related_patterns.append(pattern_index)
	return song

static func load_global_parameters(reader:SongFileReader):
	pass

static func load_motif_nodes(reader:SongFileReader,song:Song):
	var motif_nodes_size = reader.read_int()
	for i in Controller.graph.motif_nodes:
		i.free()
	Controller.graph.motif_nodes.clear()
	
	for i in range(motif_nodes_size):
		var new_node :MotifNode= load("res://myproject/GraphNode.tscn").instantiate()
		Controller.graph.create_motif_node(false,new_node)
		new_node.name = reader.read_string()
		new_node.position_offset.x = reader.read_int()
		new_node.position_offset.y = reader.read_int()
		
		new_node.graph_node_name_edit.text = reader.read_string()
		new_node.chord_progression_edit.text = reader.read_string()
		new_node.notes_edit.text = reader.read_string()
		
		var motif_controls_size = reader.read_int()
		for ii in range(motif_controls_size):
			var motif_control := new_node.add_motif_control()
			
			var pattern_index = reader.read_int()
			motif_control.leitmotifs_option.get_song_patterns(song)
			motif_control.leitmotifs_option.set_selected(pattern_index,song)
			
			motif_control.associated_pattern.motif_name = reader.read_string()
			motif_control.associated_pattern.time_signature = reader.read_string()
			
			motif_control.associated_pattern.motif_bpm = reader.read_int()
			motif_control.associated_pattern.pattern_length.x = reader.read_int()
			motif_control.associated_pattern.pattern_length.y = reader.read_int()
			motif_control.associated_pattern.key = reader.read_int()
			motif_control.associated_pattern.scale_mode = reader.read_int()
			
			motif_control.associated_pattern.additional_description = reader.read_string()
			
	## Later, once all nodes have been added...
	for i in Controller.graph.motif_nodes:
		for ii:MotifControl in i.motif_controls:
			var related_patterns_size = reader.read_int()
			for iii in range(related_patterns_size):
				var type = reader.read_int()
				#if type == 1:
					#var node_index = reader.read_int()
					#ii.associated_pattern.related_patterns.append(Controller.graph.motif_nodes[node_index])
				#elif type == 0:
					#var pattern_index = reader.read_int()
					#ii.associated_pattern.related_patterns.append(song.patterns[pattern_index])
				if type == 1:
					var node_index = Controller.graph.motif_nodes[reader.read_int()]
					if !ii.associated_pattern.related_patterns.has(node_index):
						ii.associated_pattern.related_patterns.append(node_index)
				elif type == 0:
					var pattern_index = song.patterns[reader.read_int()]
					if !ii.associated_pattern.related_patterns.has(pattern_index):
						ii.associated_pattern.related_patterns.append(pattern_index)

func old_v1_my_tool_load(reader,song):
	## TODO: first, just make variables of all the read_int() calls. Then figure out which ones can be assigned immediately and which need to be stored to variables.
	var motif_nodes_size = reader.read_int()
	
	for i in Controller.graph.motif_nodes:
		i.free()
	Controller.graph.motif_nodes.clear()
	
	for i in range(motif_nodes_size):
		var new_node :MotifNode= load("res://myproject/GraphNode.tscn").instantiate()

		Controller.graph.create_motif_node(false,new_node) ## TODO: Figure out best thing to do here to actually spawn them.
		new_node.name = reader.read_string()
		
		new_node.position_offset.x = reader.read_int()
		new_node.position_offset.y = reader.read_int()
		
		
		new_node.motif_name = reader.read_string()
		new_node.current_key = reader.read_int()
		new_node.current_mode = reader.read_int()
		#var time_signature : Vector2i
		#time_signature.x = reader.read_int()
		#time_signature.y = reader.read_int()
		new_node.bpm = reader.read_int()
		new_node.pattern_size.x = reader.read_int()
		new_node.pattern_size.y = reader.read_int()
		
		new_node.default_chord_progression = reader.read_string()
		new_node.additional_description = reader.read_string()
		
		var associated_pattern_index = reader.read_int()
		var associated_pattern_2_index = reader.read_int()
		new_node.associated_pattern = song.patterns[associated_pattern_index]
		new_node.associated_pattern_2 = song.patterns[associated_pattern_2_index]
		
		#var image_labels_size = reader.read_int()
		#for ii in range(image_labels_size):
			#var image_label :ImageLabel= load("res://myproject/image_label.tscn").instantiate()
			#new_node.image_label_container.add_child(image_label)
			#image_label.title = reader.read_string()
		
	var connections_size = reader.read_int()
	Controller.graph.connections_dict.clear()
	for i in range(connections_size):
		Controller.graph.connections_dict.append([reader.read_string(),reader.read_int(),reader.read_string(),reader.read_int()])
	#for integer in range(motif_nodes_size):
		#var i := MotifNode.new()
		#song.motif_nodes.append(i)
	#
		#for integer2 in range(image_labels_size):
			#i.image_labels.append(ImageLabel.new())
	
	Controller.graph.scroll_offset.x = reader.read_float()
	Controller.graph.scroll_offset.y = reader.read_float()
	Controller.graph.zoom = reader.read_float()


class SongFileReader extends RefCounted:
	const SEPARATOR := ","
	const STRING_SEPARATOR := "`"

	var _path: String = ""
	var _contents: String = ""
	var _version: int = -1

	var _offset: int = 0
	var _end_reached: bool = true
	var _next_value: String = ""
	
	
	func _init(path: String, contents: String) -> void:
		_path = path
		_contents = contents
		if _contents.length() > 0:
			_offset = 0
			_end_reached = false
		
		_version = read_int()
	
	
	func get_path() -> String:
		return _path
	
	
	func get_version() -> int:
		return _version
	
	
	func read_int() -> int:
		_next_value = ""
		
		while not _end_reached:
			var token := _contents[_offset]
			if token == SEPARATOR:
				break
			_next_value += token
			_offset += 1
			
			if _offset >= _contents.length():
				_end_reached = true
		
		if not _end_reached:
			_offset += 1 # Move past the separator.
			if _offset >= _contents.length():
				_end_reached = true
		
		return _next_value.to_int()
	
	func read_string() -> String:
		_next_value = ""
		
		while not _end_reached:
			var token := _contents[_offset] ## I think this gets the character at the index _offset.
			if token == STRING_SEPARATOR:
				break
			_next_value += token
			_offset += 1
			
			if _offset >= _contents.length():
				_end_reached = true
			
		if not _end_reached:
			_offset += 1
			if _offset >= _contents.length():
				_end_reached = true

		return _next_value

	func read_float() -> float:
		_next_value = ""
		
		while not _end_reached:
			var token := _contents[_offset]
			if token == SEPARATOR:
				break
			_next_value += token
			_offset += 1
			
			if _offset >= _contents.length():
				_end_reached = true
		
		if not _end_reached:
			_offset += 1 # Move past the separator.
			if _offset >= _contents.length():
				_end_reached = true
		
		return _next_value.to_float()
	
	func get_read_remainder() -> int:
		return _contents.length() - _offset
