extends VBoxContainer
class_name ImageLabel

@export var title : String = ""
@export var image : CompressedTexture2D

func _ready() -> void:
	$LineEdit.text = title

func _on_button_pressed() -> void:
	## TODO open file browser, change image.
	pass # Replace with function body.


func _on_line_edit_text_submitted(new_text: String) -> void:
	title = new_text


func _on_button_2_pressed() -> void:
	queue_free()
