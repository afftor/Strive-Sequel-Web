extends Control
#mb we should dissect this script in two for clarity reasons

var data
var order
var materials
var target_node
var target_function

#signal mouse_exited_custom

func get_drag_data(position):
	if data == null:
		return null
	var preview = self.duplicate()
#	var preview = get_node("icon").duplicate()
#	preview.rect_size = Vector2(64, 64)
	set_drag_preview(preview)
	return {data = data, materials = materials}

func can_drop_data(position, dragdata):
	if dragdata.materials != materials:
		return false
	return dragdata != null

func drop_data(position, dropdata):
	if str(data) == str(dropdata.data):
		print(data)
		return
	target_node.call(target_function, dropdata.data, order, materials)
	#get_parent().get_parent().get_parent().get_parent().change_order()

#func _ready():
#	connect("mouse_exited", self, 'check_mouse_exit')
#
#func check_mouse_exit():
#	if !get_global_rect().has_point(get_global_mouse_position()):
#		emit_signal("mouse_exited_custom")
