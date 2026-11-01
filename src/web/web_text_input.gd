extends Node

# Phones get no keyboard in the HTML5 build (the export's experimental virtual keyboard is
# off), so a text field tapped with a finger asks for its text through the browser's own
# prompt dialog. A mouse click still types in place, as on the desktop.

#the mouse events Godot makes from a touch carry this device id
const TOUCH_MOUSE_DEVICE = -1

var pending = null


func _ready():
	if !OS.has_feature("HTML5") or !OS.has_feature("JavaScript"):
		return
	get_tree().connect("node_added", self, "_on_node_added")
	_hook_tree(get_tree().root)


func _hook_tree(node):
	_on_node_added(node)
	for child in node.get_children():
		_hook_tree(child)


func _on_node_added(node):
	if !(node is LineEdit or node is TextEdit):
		return
	if !node.is_connected("gui_input", self, "_on_field_input"):
		node.connect("gui_input", self, "_on_field_input", [node])


#on the release, as a click: a press may still turn into a scroll
func _on_field_input(event, field):
	if !(event is InputEventMouseButton) or event.pressed or event.button_index != BUTTON_LEFT:
		return
	if event.device != TOUCH_MOUSE_DEVICE or pending != null:
		return
	if field is LineEdit and !field.editable:
		return
	if field is TextEdit and field.readonly:
		return
	pending = field
	#once the tap is handled, so the dialog does not cut into the field's own input
	call_deferred("_ask", field)


func _ask(field):
	pending = null
	if !is_instance_valid(field) or !field.is_visible_in_tree():
		return
	var multiline = field is TextEdit
	var current = field.text
	#the dialog has one line: line breaks travel as \n and come back
	if multiline:
		current = current.replace("\n", "\\n")
	var label = "" if multiline else tr(field.placeholder_text)
	var result = JavaScript.eval("window.prompt(%s, %s)" % [to_json(label), to_json(current)], true)
	if typeof(result) != TYPE_STRING: #cancelled
		field.release_focus()
		return
	if multiline:
		field.text = result.replace("\\n", "\n")
		field.emit_signal("text_changed")
	else:
		if field.max_length > 0:
			result = result.substr(0, field.max_length)
		field.text = result
		field.caret_position = result.length()
		#OK in the dialog is typing the text and pressing Enter
		field.emit_signal("text_changed", result)
		field.emit_signal("text_entered", result)
	field.release_focus()
