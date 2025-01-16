extends GraphEdit

const MOTIF_NODE_PATH = "res://myproject/GraphNode.tscn"

@export var motif_nodes : Array[MotifNode] = []
var connections_dict : Array[Array]

func _ready() -> void:
	create_motif_node(true)
	Controller.song_loaded.connect(_on_song_loaded)

func create_motif_node(first_time = false,new_node = null):
	if new_node == null:
		new_node = load(MOTIF_NODE_PATH).instantiate()
	add_child(new_node,true)
	
	motif_nodes.append(new_node)
	new_node.my_delete_request.connect(_on_node_delete_request)
func _on_song_loaded():
	for i in connections_dict:
		connect_node(i[0], i[1], i[2], i[3])
	motif_nodes[0].selected = true

func _on_node_delete_request(which):
	_on_node_deleted(which)

func _on_node_deleted(which:MotifNode):
	for i in connections_dict:
		if i[0] == which.name or i[3] == which.name:
			connections_dict.erase(i)
	motif_nodes.erase(which)
	which.queue_free()

func on_pressed() -> void:
	create_motif_node()

func focus_on_graphnode(graphnode:MotifNode):
	scroll_offset = graphnode.position_offset
	


func _on_delete_unused_motifs_pressed() -> void:
	var patterns_to_delete : Array[Pattern]
	for i in Controller.current_song.patterns:
		patterns_to_delete.append(i)
	
	
	for i : Pattern in Controller.current_song.patterns:
		#print("Looping i")
		for ii : MotifNode in motif_nodes:
			#print("Looping ii")
			for iii in ii.motif_controls:
				#print("Looping iii")
				if i == iii.associated_pattern:
					patterns_to_delete.erase(i)
					print(i.motif_name + " has been erased.")
					#continue
				pass
			pass
	for i : Pattern in patterns_to_delete:
		print(i.motif_name)
		Controller.delete_pattern(i.index)
	pass # Replace with function body.
