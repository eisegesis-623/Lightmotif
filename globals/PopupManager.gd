###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A tiny bespoke popup management system to avoid using viewports for simple panels.
class_name PopupManager extends CanvasLayer

enum Direction {
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
	TOP_RIGHT,
	TOP_LEFT,
	OMNI,
}

static var _instance: PopupManager = null

var _active_popups: Array[PopupControl] = []
var _blocking_popups: Array[PopupControl] = []
@onready var _click_catcher: Control = $ClickCatcher


func _init() -> void:
	if _instance:
		printerr("PopupManager: Only one instance of PopupManager is allowed.")
	
	_instance = self


func _ready() -> void:
	_click_catcher.visible = _active_popups.size() > 0
	_click_catcher.gui_input.connect(_handle_catcher_clicked)
	_click_catcher.draw.connect(_draw_catcher)


func _draw_catcher() -> void:
	_click_catcher.draw_rect(Rect2(Vector2.ZERO, _click_catcher.size), _click_catcher.get_theme_color("click_catcher_color", "PopupManager"))


# Popup management.

func _handle_catcher_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton && not event.is_pressed(): # Activate on mouse release.
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			PopupManager.hide_all_popups()
			_click_catcher.hide()
			return


func _handle_popup_clicked(popup: PopupControl) -> void:
	# Close all popups on top of the clicked one.
	for i in range(_active_popups.size() - 1, 0, -1):
		var active_popup := _active_popups[i]
		if active_popup == popup:
			break
		
		destroy_popup(active_popup)


func has_popup(popup: PopupControl) -> bool:
	return _active_popups.has(popup)


func fit_popup_to_screen(position: Vector2, size: Vector2, direction: Direction) -> Vector2:
	# Apply smart adjustments if the desired position + size would put the popup out of screen.
	# We trust the hardcoded direction, so the solution is to nudge it back in.
	var valid_position := position
	
	var effective_popup_rect := Rect2()
	effective_popup_rect.size.x = size.x
	effective_popup_rect.size.y = size.y
	
	match direction:
		Direction.BOTTOM_RIGHT:
			effective_popup_rect.position.x = position.x
			effective_popup_rect.position.y = position.y
		Direction.BOTTOM_LEFT:
			effective_popup_rect.position.x = position.x - size.x
			effective_popup_rect.position.y = position.y
		Direction.TOP_RIGHT:
			effective_popup_rect.position.x = position.x
			effective_popup_rect.position.y = position.y - size.y
		Direction.TOP_LEFT:
			effective_popup_rect.position.x = position.x - size.x
			effective_popup_rect.position.y = position.y - size.y
		Direction.OMNI:
			effective_popup_rect.position.x = position.x - size.x / 2.0
			effective_popup_rect.position.y = position.y - size.y / 2.0
	
	if effective_popup_rect.position.x < 0:
		valid_position.x -= effective_popup_rect.position.x
	elif effective_popup_rect.end.x > _click_catcher.size.x:
		valid_position.x -= effective_popup_rect.end.x - _click_catcher.size.x
	
	if effective_popup_rect.position.y < 0:
		valid_position.y -= effective_popup_rect.position.y
	elif effective_popup_rect.end.y > _click_catcher.size.y:
		valid_position.y -= effective_popup_rect.end.y - _click_catcher.size.y
	
	return valid_position


func _anchor_popup(popup: PopupControl) -> Control:
	# Add a node to align the popup against.
	var anchor := Control.new()
	anchor.name = "PopupAnchor"
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	
	# Anchor the popup to that node.
	popup.hide() # Avoid showing it until positioned.
	anchor.add_child(popup)
	_active_popups.push_back(popup)
	
	# Emit this after the node has been added to the tree, so theme is accessible.
	# Can be used to update the size of the popup.
	popup.about_to_popup.emit()
	
	return anchor


func _align_popup(popup: PopupControl, direction: Direction) -> void:
	match direction:
		Direction.BOTTOM_RIGHT:
			popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_END
			popup.grow_vertical = Control.GROW_DIRECTION_END
		Direction.BOTTOM_LEFT:
			popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			popup.grow_vertical = Control.GROW_DIRECTION_END
		Direction.TOP_RIGHT:
			popup.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_END
			popup.grow_vertical = Control.GROW_DIRECTION_BEGIN
		Direction.TOP_LEFT:
			popup.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			popup.grow_vertical = Control.GROW_DIRECTION_BEGIN
		Direction.OMNI:
			popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
			popup.grow_vertical = Control.GROW_DIRECTION_BOTH


func create_positioned_popup(popup: PopupControl, position: Vector2, direction: Direction, blocking: bool) -> void:
	if has_popup(popup):
		printerr("PopupManager: Popup %s is already shown." % [ popup ])
		return
	if popup.get_parent():
		printerr("PopupManager: Popup %s must be unparented before it can be shown." % [ popup ])
		return
	
	var anchor := _anchor_popup(popup)
	anchor.global_position = fit_popup_to_screen(position, popup.size, direction)
	
	_align_popup(popup, direction)
	
	popup.click_handled.connect(_handle_popup_clicked.bind(popup))
	popup.show()
	
	if blocking:
		_blocking_popups.push_back(popup)
		_click_catcher.visible = true


func create_anchored_popup(popup: PopupControl, anchor_position: Vector2, direction: Direction, blocking: bool) -> void:
	if has_popup(popup):
		printerr("PopupManager: Popup %s is already shown." % [ popup ])
		return
	if popup.get_parent():
		printerr("PopupManager: Popup %s must be unparented before it can be shown." % [ popup ])
		return
	
	var anchor := _anchor_popup(popup)
	anchor.anchor_left = anchor_position.x
	anchor.anchor_right = anchor_position.x
	anchor.anchor_top = anchor_position.y
	anchor.anchor_bottom = anchor_position.y
	
	_align_popup(popup, direction)
	
	popup.click_handled.connect(_handle_popup_clicked.bind(popup))
	popup.show()
	
	if blocking:
		_blocking_popups.push_back(popup)
		_click_catcher.visible = true


func translate_anchored_popup(popup: PopupControl, anchor_position: Vector2, direction: Direction) -> void:
	if not has_popup(popup):
		printerr("PopupManager: Popup %s is not shown." % [ popup ])
		return
	
	var anchor: Control = popup.get_parent()
	anchor.anchor_left = anchor_position.x
	anchor.anchor_right = anchor_position.x
	anchor.anchor_top = anchor_position.y
	anchor.anchor_bottom = anchor_position.y
	
	_align_popup(popup, direction)


func destroy_popup(popup: PopupControl) -> void:
	if not has_popup(popup):
		printerr("PopupManager: Popup %s is not shown." % [ popup ])
		return
	
	popup.click_handled.disconnect(_handle_popup_clicked)
	_active_popups.erase(popup)
	_blocking_popups.erase(popup)
	_click_catcher.visible = _blocking_popups.size() > 0
	
	popup.about_to_hide.emit()
	popup.hide()
	
	var anchor := popup.get_parent()
	anchor.remove_child(popup)
	anchor.get_parent().remove_child(anchor)
	anchor.queue_free()


# Public API.

static func fit_popup(popup: PopupControl, position: Vector2, direction: Direction) -> Vector2:
	if not _instance:
		return position
	
	return _instance.fit_popup_to_screen(position, popup.size, direction)


static func show_popup(popup: PopupControl, position: Vector2, direction: Direction, blocking: bool = true) -> void:
	if not _instance:
		return
	
	_instance.create_positioned_popup(popup, position, direction, blocking)


static func show_popup_anchored(popup: PopupControl, anchor_position: Vector2, direction: Direction, blocking: bool = true) -> void:
	if not _instance:
		return
	
	_instance.create_anchored_popup(popup, anchor_position, direction, blocking)


static func move_popup_anchored(popup: PopupControl, anchor_position: Vector2, direction: Direction) -> void:
	if not _instance:
		return
	
	_instance.translate_anchored_popup(popup, anchor_position, direction)


static func hide_popup(popup: PopupControl) -> void:
	if not _instance:
		return
	
	_instance.destroy_popup(popup)


static func hide_all_popups() -> void:
	if not _instance:
		return
	
	for i in range(_instance._active_popups.size() - 1, -1, -1):
		var active_popup := _instance._active_popups[i]
		_instance.destroy_popup(active_popup)


static func is_popup_shown(popup: PopupControl) -> bool:
	if not _instance:
		return false
	
	return _instance.has_popup(popup)


class PopupControl extends Control:
	signal click_handled()
	signal about_to_popup()
	signal about_to_hide()
	
	
	func mark_click_handled() -> void:
		click_handled.emit()
