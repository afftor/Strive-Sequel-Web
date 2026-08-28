extends Node

# Streams the large story/CG PNGs after the HTML5 build has started. The files
# are copied next to the export by web_export.ps1 and deliberately excluded
# from the main PCK.

signal texture_loaded(path, texture)
signal texture_failed(path, error)

const EXTERNAL_ASSET_ROOT = "http://localhost:8000/cg-assets/"
const STREAMED_ROOTS = [
	"res://assets/images/fullscreen scenes/",
	"res://assets/images/scenes/",
]
const MAX_CACHED_TEXTURES = 4

var texture_cache = {}
var cache_order = []
var pending_requests = {}

func is_streamed_path(path):
	if !OS.has_feature("HTML5") || typeof(path) != TYPE_STRING:
		return false
	for root in STREAMED_ROOTS:
		if path.begins_with(root):
			return true
	return false

func get_cached_texture(path):
	if texture_cache.has(path):
		_touch_cache(path)
		return texture_cache[path]
	return null

func load_texture(path):
	if !is_streamed_path(path):
		return load(path)
	if texture_cache.has(path):
		_touch_cache(path)
		yield(get_tree(), "idle_frame")
		return texture_cache[path]
	if !pending_requests.has(path):
		_start_request(path)
	while pending_requests.has(path):
		yield(self, "texture_loaded")
	if texture_cache.has(path):
		return texture_cache[path]
	return null

func _start_request(path):
	var request = HTTPRequest.new()
	add_child(request)
	pending_requests[path] = request
	request.connect("request_completed", self, "_on_request_completed", [path, request])
	var error = request.request(EXTERNAL_ASSET_ROOT + path.trim_prefix('res://').http_escape())
#	var error = request.request(EXTERNAL_ASSET_ROOT + path.substr(6).http_escape())
	if error != OK:
		pending_requests.erase(path)
		request.queue_free()
		emit_signal("texture_failed", path, error)
		emit_signal("texture_loaded", path, null)

func _on_request_completed(result, response_code, _headers, body, path, request):
	pending_requests.erase(path)
	request.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS || response_code != 200:
		emit_signal("texture_failed", path, response_code)
		emit_signal("texture_loaded", path, null)
		return
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		emit_signal("texture_failed", path, error)
		emit_signal("texture_loaded", path, null)
		return
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	texture_cache[path] = texture
	_touch_cache(path)
	emit_signal("texture_loaded", path, texture)

func _touch_cache(path):
	cache_order.erase(path)
	cache_order.append(path)
	while cache_order.size() > MAX_CACHED_TEXTURES:
		texture_cache.erase(cache_order.pop_front())
