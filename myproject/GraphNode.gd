extends GraphNode
class_name MotifNode

#@export var motifs : Array[Pattern]
#@export var graph_node_name := ""
#@export var notes := ""
@export var motif_controls : Array[MotifControl]:
	get:
		var _motif_controls : Array[MotifControl]
		for i in motif_holder.get_children():
			if i is MotifControl:
				_motif_controls.append(i)
		return _motif_controls

@onready var motif_holder: VBoxContainer = %MotifHolder
@onready var add_motif_button: Button = %AddMotifButton

@onready var graph_node_name_edit: LineEdit = %GraphNodeNameEdit
@onready var chord_progression_edit: LineEdit = %ChordProgressionEdit
@onready var notes_edit: TextEdit = %NotesEdit


func _ready() -> void:
	#set_default_motif_control_pattern.call_deferred() ## TODO this is not good, will need to change later, only here temporarily.
	add_motif_button.pressed.connect(_on_add_motif_button_pressed)

func set_default_motif_control_pattern():
	for i in motif_holder.get_children():
		#####i.leitmotifs_option.set_default_selected()
		#i.set_associated_pattern(0)
		i.leitmotifs_option.set_selected(0)

func _on_add_motif_button_pressed() -> void:
	if get_tree().get_node_count_in_group("MotifControl") > 0:
		var motif_control = add_motif_control()
		assign_new_pattern_to_motif_control(motif_control)
	else:
		var motif_control = add_motif_control()
		motif_control.leitmotifs_option.get_song_patterns()
		motif_control.leitmotifs_option.set_selected(0)#motif_control.set_associated_pattern(0)
		motif_control.switch_to_pattern()

func add_motif_control()->MotifControl:
	## Add the new control.
	var motif_control :MotifControl= load("res://myproject/MotifControl.tscn").instantiate()
	motif_holder.add_child(motif_control)
	#motif_controls.append(motif_control)
	## Misc.
	motif_control.motif_order_change_requested.connect(_on_motif_order_change_requested)
	motif_control.motif_delete_request.connect(_on_motif_delete_requested)
	return motif_control

func assign_new_pattern_to_motif_control(motif_control):
	## Handle the pattern side of things.
	Controller.create_pattern()
	motif_control.leitmotifs_option.get_song_patterns()
	motif_control.leitmotifs_option.set_selected(Controller.current_song.patterns.size() - 1)#(Controller.current_song.patterns[Controller.current_song.patterns.size() - 1]) #motif_control.set_associated_pattern(Controller.current_song.patterns[Controller.current_song.patterns.size() - 1])
	motif_control.switch_to_pattern()
	

func _on_motif_order_change_requested(which:MotifControl,up:bool):
	print("I got moved :D")
	if up:
		motif_holder.move_child(which,which.get_index()-1)

	else:
		motif_holder.move_child(which,which.get_index()+1)

#func change_array_order(array:Array,what, new_distance:int):
	#var current_index = array.find(what)
	#var new_index = current_index + new_distance
	#var former_inhabitant = array[new_index]
	#array[new_index] = what
	#array[current_index] = former_inhabitant

func _on_motif_delete_requested(which:MotifControl):
	#motif_controls.erase(which)
	which.queue_free()
	await which.tree_exited
	size.y = 0

signal my_delete_request(which)
func _on_delete_button_pressed() -> void:
	my_delete_request.emit(self)
