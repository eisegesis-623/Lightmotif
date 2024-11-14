extends VBoxContainer

@onready var option_button: OptionButton = $OptionButton
@onready var check_button: CheckButton = $HBoxContainer/CheckButton

func _ready() -> void:
	set_check_button_text()

func _on_option_button_pressed() -> void:
	set_appropriate_options()

func set_appropriate_options():
	option_button.clear()
	
	if check_button.button_pressed:
		for i in Controller.graph.motif_nodes:
			var new_text = i.graph_node_name_edit.text
			if new_text == "":
				new_text = "(Unnamed Node)"
			option_button.add_item(new_text)
	else:
		for i in Controller.current_song.patterns:
			option_button.add_item(i.motif_name)

func _on_check_button_toggled(toggled_on: bool) -> void:
	set_appropriate_options()
	set_check_button_text()

func set_check_button_text():
	if check_button.button_pressed:
		check_button.text = "Nodes"
	else:
		check_button.text = "Patterns"

signal motif_chosen(type,index)
func _on_ok_button_pressed() -> void:
	motif_chosen.emit(check_button.button_pressed,option_button.selected)
	get_parent().visible = false
