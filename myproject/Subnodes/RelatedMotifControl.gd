extends VBoxContainer

var my_motif

@onready var label: Label = $HBoxContainer/Label

@onready var delete_button: Button = $HBoxContainer/DeleteButton
@onready var select_button: Button = $SelectButton

func set_pattern(motif):
	if motif is Pattern:
		select_button.text = "Pattern"
		label.text = motif.motif_name
	elif motif is GraphNode:
		select_button.text = "Node"
		label.text = motif.graph_node_name_edit.text
	else:
		select_button.text = "ERROR"
		label.text = "ERROR"
	my_motif = motif
	print("Pattern set!")

signal motif_selected(which)
signal motif_delete_request(which)
func _on_button_pressed() -> void:
	motif_selected.emit(self)
	#print("Pretend I selected the thing! Also if it's a GraphNode you should move the camera to focus on it.")


func _on_delete_button_pressed() -> void:
	motif_delete_request.emit(my_motif)
