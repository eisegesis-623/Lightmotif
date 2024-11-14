###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name SongSaver extends RefCounted


static func save(song: Song, path: String) -> bool:
	if path.get_extension() != Song.FILE_EXTENSION:
		printerr("SongSaver: The song file must have a .%s extension." % [ Song.FILE_EXTENSION ])
		return false
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("SongSaver: Failed to open the file at '%s' for writing (code %d)." % [ path, error ])
		return false
	
	var writer := SongFileWriter.new(path)
	_write(writer, song)

	# Try to write the file with the new contents.
	
	file.store_string(writer.get_file_string())
	error = file.get_error()
	if error != OK:
		printerr("SongSaver: Failed to write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	song.filename = path
	return true


static func _write(writer: SongFileWriter, song: Song) -> void:
	# Basic information.
	
	song.format_version = Song.FILE_FORMAT # Bump the version as we save the song in the modern format.
	writer.write_int(song.format_version)
	
	writer.write_int(song.swing)
	writer.write_int(song.global_effect)
	writer.write_int(song.global_effect_power)
	
	writer.write_int(song.bpm)
	writer.write_int(song.pattern_size)
	writer.write_int(song.bar_size)
	
	# Instruments.
	
	writer.write_int(song.instruments.size())
	
	for instrument in song.instruments:
		writer.write_int(instrument.voice_index)
		writer.write_int(instrument.type) # For compatibility, but not actually needed.
		writer.write_int(instrument.color_palette)
		writer.write_int(instrument.lp_cutoff)
		writer.write_int(instrument.lp_resonance)
		writer.write_int(instrument.volume)
	
	# Patterns.
	
	writer.write_int(song.patterns.size())
	
	for pattern in song.patterns:
		writer.write_int(pattern.key)
		writer.write_int(pattern.scale)
		writer.write_int(pattern.instrument_idx)
		writer.write_int(0) # Empty write, the color palette is determined by the instrument.
		
		writer.write_int(pattern.note_amount)
		for i in pattern.note_amount:
			writer.write_int(pattern.notes[i].x) # Note value
			writer.write_int(pattern.notes[i].z) # Note length
			writer.write_int(pattern.notes[i].y) # Note position
			writer.write_int(0) # Empty write, this value is not used.
		
		writer.write_int(1 if pattern.record_instrument else 0)
		if pattern.record_instrument:
			# FIXME: Format v3 only handles the first 16 notes, but patterns can contain up to 32. Requires v4.
			for i in 16:
				writer.write_int(pattern.recorded_instrument_values[i].x) # Volume
				writer.write_int(pattern.recorded_instrument_values[i].y) # Cutoff
				writer.write_int(pattern.recorded_instrument_values[i].z) # Resonance
	
	# Arrangement.
	
	writer.write_int(song.arrangement.timeline_length)
	writer.write_int(song.arrangement.loop_start)
	writer.write_int(song.arrangement.loop_end)
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			writer.write_int(channels[j])

	## Starting MYTOOL
	save_global_parameters(writer,song)
	save_motif_nodes(writer,song)

static func save_global_parameters(writer:SongFileWriter,song:Song):
	pass

static func save_motif_nodes(writer:SongFileWriter,song:Song):
	writer.write_int(Controller.graph.motif_nodes.size())
	for i:MotifNode in Controller.graph.motif_nodes:
		writer.write_string(i.name)
		writer.write_int(i.position_offset.x)
		writer.write_int(i.position_offset.y)
		
		writer.write_string(i.graph_node_name_edit.text)
		writer.write_string(i.chord_progression_edit.text)
		writer.write_string(i.notes_edit.text)
		
		writer.write_int(i.motif_controls.size())
		for ii :MotifControl in i.motif_controls:
			writer.write_int(ii.associated_pattern.index)
			writer.write_string(ii.associated_pattern.motif_name)
			writer.write_string(ii.associated_pattern.time_signature)
			writer.write_int(ii.associated_pattern.motif_bpm)
			writer.write_int(ii.associated_pattern.pattern_length.x)
			writer.write_int(ii.associated_pattern.pattern_length.y)
			writer.write_int(ii.associated_pattern.key)
			writer.write_int(ii.associated_pattern.scale_mode)
			writer.write_string(ii.associated_pattern.additional_description)
		pass
	## Starting another loop just to make things easier to keep track of with SongLoader, which requires another loop.
	for i:MotifNode in Controller.graph.motif_nodes:
		for ii :MotifControl in i.motif_controls:
			writer.write_int(ii.associated_pattern.related_patterns.size())
			for iii in ii.associated_pattern.related_patterns:
				if iii is GraphNode:
					writer.write_int(1)
					writer.write_int(Controller.graph.motif_nodes.find(iii))
				elif iii is Pattern:
					writer.write_int(0)
					writer.write_int(iii.index)
				#writer.write_int()
	pass



func old_v1_my_tool_save_(writer,song):
	#(This is entirely demo stuff for now, just getting a feel for it.)
	writer.write_int(Controller.graph.motif_nodes.size())
	for i in Controller.graph.motif_nodes:
		writer.write_string(i.name)
		
		
		writer.write_int(i.position_offset.x)
		writer.write_int(i.position_offset.y)
		
		
		writer.write_string(i.motif_name)
		
		writer.write_int(i.current_key)
		writer.write_int(i.current_mode)
		#writer.write_int(i.time_signature.x)
		#writer.write_int(i.time_signature.y)
		writer.write_int(i.bpm)
		writer.write_int(i.pattern_size.x)
		writer.write_int(i.pattern_size.y)
		
		writer.write_string(i.default_chord_progression)
		## TODO something something additional categories
		writer.write_string(i.additional_description)
		
		writer.write_int(song.patterns.find(i.associated_pattern))
		
		if is_instance_valid(i.associated_pattern_2):
			writer.write_int(song.patterns.find(i.associated_pattern_2))
		else:
			writer.write_int(-1)
		
	writer.write_int(Controller.graph.connections_dict.size())
	for ii in Controller.graph.connections_dict.size():
		writer.write_string(Controller.graph.connections_dict[ii][0])
		writer.write_int(Controller.graph.connections_dict[ii][1])
		writer.write_string(Controller.graph.connections_dict[ii][2])
		writer.write_int(Controller.graph.connections_dict[ii][3])
		#writer.write_int(i.image_labels.size())
		#for ii : ImageLabel in i.image_labels:
			#writer.write_string(ii.title)
	
	writer.write_float(Controller.graph.scroll_offset.x)
	writer.write_float(Controller.graph.scroll_offset.y)
	writer.write_float(Controller.graph.zoom)

class SongFileWriter extends RefCounted:
	const SEPARATOR := ","
	const STRING_SEPARATOR := "`"
	
	var _path: String = ""
	var _contents: String = ""
	
	
	func _init(path: String) -> void:
		_path = path
	
	
	func get_path() -> String:
		return _path
	
	
	func get_file_string() -> String:
		return _contents
	
	
	func write_int(value: int) -> void:
		_contents += ("%d" % value) + SEPARATOR
	
	func write_float(value:float)->void:
		print(value)
		#_contents += ("%d"%value) + SEPARATOR
		_contents += (str(value)) + SEPARATOR

	func write_string(value:String)->void:
		value = value.replace("`","")
		_contents += (value) + STRING_SEPARATOR
