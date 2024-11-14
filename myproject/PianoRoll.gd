###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

func _enter_tree() -> void:
	# Ensure that the minimum size of the UI is respected and the main window cannot go any lower.
	get_window().wrap_controls = true

func _ready() -> void:
	Controller.io_manager.initialize_song()
