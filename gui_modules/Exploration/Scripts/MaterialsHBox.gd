extends HBoxContainer


var mainnode

func _ready():
	globals.connect("hour_tick", self, "update")

func update():
	var dungeon = false
	var selected_location = input_handler.active_location
	input_handler.ClearContainer(self)
	if selected_location == null:
		return
#	var location = ResourceScripts.world_gen.get_location_from_code(selected_location)
	if selected_location.type == "quest_location":
		return
	
	for r_task in ['recruit_easy', 'recruit_hard']:
		if selected_location.has('tags') and selected_location.tags.has(r_task):
			var newbutton = input_handler.DuplicateContainerTemplate(self)
			var jobdata = tasks.tasklist[r_task]
			newbutton.get_node("TextureRect").texture = load(jobdata.production_icon)
			var max_workers_count = jobdata.base_workers
			var current_workers_count = 0
			var task_id = ResourceScripts.game_res.check_location_job('recruiting', selected_location.id, r_task)
			if task_id != null:
				var task = ResourceScripts.game_res.tasks_progresses[task_id]
				current_workers_count = task.workers.size()
			newbutton.get_node("Label").text = str(max_workers_count - current_workers_count) + "/" + str(max_workers_count)
			globals.connecttexttooltip(newbutton, jobdata.descript)
	
	var gatherable_resources
	if selected_location.type in ["dungeon",'encounter']:
		dungeon = true
		if !selected_location.has('gather_limit_resources') or selected_location.gather_limit_resources.empty():
			self.visible = false
			gatherable_resources = null
#			if selected_location.completed:
		else:
			self.visible = true
			gatherable_resources = selected_location.gather_limit_resources
	else:
		if selected_location.has("category"):
			if selected_location.category != "capital":
				gatherable_resources = selected_location.gather_resources
		else:
			gatherable_resources = selected_location.gather_resources
		self.visible = true
	
	if gatherable_resources != null:
		for i in gatherable_resources:
			var item = Items.materiallist[i]
			if ResourceScripts.game_progress.can_gather_item(i) or dungeon:
				var newbutton = input_handler.DuplicateContainerTemplate(self)
				newbutton.get_node("TextureRect").texture = Items.materiallist[i].icon
				newbutton.set_meta("exploration", true)
				if dungeon:
					newbutton.get_node("Label").text = str(gatherable_resources[i])
					var gather_mod = Items.get_loot().get_gather_mod_from_loc(selected_location, i)
					newbutton.set_meta("gather_mod", round(gather_mod * 100))
				else:
					var task_id = ResourceScripts.game_res.add_gathering_res_temp(i, selected_location.id)
					var task = ResourceScripts.game_res.tasks_progresses[task_id]
					var current_workers_count = task.workers.size()
					var max_workers_count = task.max_workers
					newbutton.set_meta("max_workers", max_workers_count)
					newbutton.set_meta("current_workers", current_workers_count)
					newbutton.get_node("Label").text = str(max_workers_count - current_workers_count) + "/" + str(max_workers_count)
				globals.connectmaterialtooltip(newbutton, item)
			else:
				continue
		for i in gatherable_resources:
			var item = Items.materiallist[i]
			if ResourceScripts.game_progress.can_gather_item(i) or dungeon:
				continue
			else:
				var newbutton = input_handler.DuplicateContainerTemplate(self)
				newbutton.get_node("TextureRect").texture = load("res://assets/Textures_v2/Travel/placer_travel_question.png")
				newbutton.get_node("Label").text = ""
				globals.connecttexttooltip(newbutton, tr('TOOLTIPHIDDENRESOURCE'))
