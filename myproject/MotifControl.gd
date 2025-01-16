extends HBoxContainer
class_name MotifControl

@export var associated_pattern : Pattern

@onready var order_up_button: Button = %OrderUp
@onready var select_button: Button = %SelectButton
@onready var order_down_button: Button = %OrderDown

@onready var leitmotifs_option: OptionButton = %LeitmotifsOption
@onready var motif_name_edit: LineEdit = %MotifNameEdit
@onready var time_signature_edit: LineEdit = %TimeSignatureEdit
@onready var key_option: OptionButton = %KeyOption
@onready var mode_option: OptionButton = %ModeOption
@onready var bpm_spin_box: SpinBox = %BPMSpinBox
@onready var pattern_size_1_spin_box: SpinBox = %PatternSize1SpinBox
@onready var pattern_size_2_spin_box: SpinBox = %PatternSize2SpinBox

@onready var additional_description: TextEdit = %AdditionalDescription
@onready var delete_button: Button = %DeleteButton

signal motif_selected(motif_control:MotifControl, motif_pattern:Pattern)
signal motif_order_change_requested(motif_control:MotifControl,up:bool)

func _ready() -> void:
	leitmotifs_option.leitmotif_item_selected.connect(_on_item_selected)
	leitmotifs_option.pressed.connect(_on_leitmotifs_option_pressed)
	motif_name_edit.text_changed.connect(_on_motif_name_edit_text_changed)
	
	
	select_button.pressed.connect(_on_select_button_pressed)
	order_down_button.pressed.connect(_on_order_button_pressed.bind(false))
	order_up_button.pressed.connect(_on_order_button_pressed.bind(true))


	#time_signature_edit.text_changed.connect(_on_time_signature_edit_text_changed)
	#key_option.item_selected.connect(_on_key_option_item_selected)
	#mode_option.item_selected.connect(_on_mode_option_item_selected)
	bpm_spin_box.value_changed.connect(_on_bpm_spin_box_value_changed)
	pattern_size_1_spin_box.value_changed.connect(_on_pattern_size_1_spin_box_changed)
	pattern_size_2_spin_box.value_changed.connect(_on_pattern_size_2_spin_box_changed)

func _process(delta: float) -> void:
	if associated_pattern.index == Controller.current_pattern_index:
		modulate = Color(0,1,0,1)
	else:
		modulate = Color.WHITE
	match_control_to_pattern()
	
	for i in associated_pattern.related_patterns:
		if !is_instance_valid(i):
			associated_pattern.related_patterns.erase(i)
	
	$Index_Visual.text = "Index: " + str(associated_pattern.index)



func _on_order_button_pressed(up:bool):
	if up:
		motif_order_change_requested.emit(self,true)
	else:
		motif_order_change_requested.emit(self,false)


func _on_pattern_size_1_spin_box_changed(value:float):
	if associated_pattern.index == Controller.current_pattern_index:
		Controller.set_song_bar_size(value)
	associated_pattern.pattern_length.x = value
	pass
func _on_pattern_size_2_spin_box_changed(value:float):
	if associated_pattern.index == Controller.current_pattern_index:
		Controller.set_song_pattern_size(value)
	associated_pattern.pattern_length.y = value
	pass
func _on_bpm_spin_box_value_changed(value:float):
	if associated_pattern.index == Controller.current_pattern_index:
		Controller.set_song_bpm(value)
	associated_pattern.motif_bpm = value
	pass
#func _on_mode_option_item_selected(index:int):
	#pass
#func _on_key_option_item_selected(index:int):
	#pass
#func _on_time_signature_edit_text_changed(new_text:String):
	#pass


func _on_select_button_pressed():
	switch_to_pattern()
	pass

func switch_to_pattern():
	Controller.edit_pattern(associated_pattern.index)
	
	set_pattern_as_only_first(-1)
	set_pattern_as_only_first(associated_pattern.index)
	
	Controller.set_song_bar_size(pattern_size_1_spin_box.value)
	Controller.set_song_pattern_size(pattern_size_2_spin_box.value)
	Controller.set_song_bpm(bpm_spin_box.value)
	pass

func set_pattern_as_only_first(which):
	## I believe if which = -1, it means delete, and any positive value means "add pattern of this index."
	var current_arrangement = Controller.current_song.arrangement
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	arrangement_state.add_setget_property(current_arrangement, "pattern", which,
		# Getter.
		func() -> int:
			return current_arrangement.get_pattern(0, 0)
			,
		# Setter.
		func(value: int) -> void:
			if value == -1:
				current_arrangement.clear_pattern(0, 0)
			else:
				current_arrangement.set_pattern(0, 0, value)
	)
	Controller.state_manager.commit_state_change(arrangement_state)




func set_associated_pattern(pattern,song:=Controller.current_song):
	if pattern is Pattern:
		associated_pattern = pattern
		#leitmotifs_option.selected = Controller.current_song.patterns.find(pattern)
		#leitmotifs_option.get_song_patterns()
		#leitmotifs_option.selected = leitmotifs_option.index
	elif pattern is int:
		associated_pattern = song.patterns[pattern]
		#leitmotifs_option.selected = pattern
		#leitmotifs_option.get_song_patterns()
		#leitmotifs_option.selected = pattern
	#match_control_to_pattern()
	



func _on_item_selected(item:int,song):
	set_associated_pattern(item,song)

func _on_motif_name_edit_text_changed(new_text:String):
	associated_pattern.motif_name = new_text


func _on_leitmotifs_option_pressed():
	leitmotifs_option.get_song_patterns()


func _on_time_signature_edit_text_changed(new_text: String) -> void:
	associated_pattern.time_signature = new_text


func _on_key_option_item_selected(index: int) -> void:
	associated_pattern.key = index
	if associated_pattern.index == Controller.current_pattern_index:
		get_tree().get_first_node_in_group("PatternEditor")._key_picker.my_custom_select(index)


func _on_mode_option_item_selected(index: int) -> void:
	associated_pattern.scale_mode = index

func _on_additional_description_text_changed() -> void:
	associated_pattern.additional_description = additional_description.text


func match_control_to_pattern():
	if !motif_name_edit.has_focus():
		motif_name_edit.text = associated_pattern.motif_name
	if !time_signature_edit.has_focus():
		time_signature_edit.text = associated_pattern.time_signature
	if !additional_description.has_focus():
		additional_description.text = associated_pattern.additional_description
	
	bpm_spin_box.value = associated_pattern.motif_bpm
	pattern_size_1_spin_box.value = associated_pattern.pattern_length.x
	pattern_size_2_spin_box.value = associated_pattern.pattern_length.y
	key_option.selected = associated_pattern.key
	mode_option.selected = associated_pattern.scale_mode
	


signal motif_delete_request(which_motif:MotifControl)
func _on_delete_button_pressed() -> void:
	motif_delete_request.emit(self)

@onready var related_motifs_container: GridContainer = %RelatedMotifsContainer
func _on_related_patterns_popup_button_pressed() -> void:
	set_related_motifs_gui()

func set_related_motifs_gui():
	for i in related_motifs_container.get_children():
		if i != related_motifs_container.get_node("AddButton"):
			i.free()
	for i in associated_pattern.related_patterns:
		var new_node = load("res://myproject/Subnodes/RelatedMotifControl.tscn").instantiate()
		related_motifs_container.add_child(new_node)
		new_node.set_pattern(i)
		new_node.motif_selected.connect(_on_related_motif_selected)
		new_node.motif_delete_request.connect(_on_related_motif_delete)


func _on_related_motif_delete(which):
	if associated_pattern.related_patterns.has(which):
		associated_pattern.related_patterns.erase(which)
		set_related_motifs_gui.call_deferred()

func _on_related_motif_selected(which):
	if which.my_motif is Pattern:
		print("Selected a pattern!")
	elif which.my_motif is GraphNode:
		Controller.graph.focus_on_graphnode(which.my_motif)

func _on_related_motif_chooser_motif_chosen(type: Variant, index: Variant) -> void:
	var new_motif
	if type:
		new_motif = Controller.graph.motif_nodes[index]
	else:
		new_motif = Controller.current_song.patterns[index]
	if !associated_pattern.related_patterns.has(new_motif):
		associated_pattern.related_patterns.append(new_motif)
	set_related_motifs_gui()
