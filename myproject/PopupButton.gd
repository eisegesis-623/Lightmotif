extends Button

@export var popup : Popup
@export var focus_grabber : Control

func _ready() -> void:
	pressed.connect(_on_pressed)
	
func _on_pressed() -> void:
	popup.popup()
	popup.position = get_global_mouse_position() + Vector2(-25,-25)
	if focus_grabber:
		focus_grabber.grab_focus()
