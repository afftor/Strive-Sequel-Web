extends Reference
var data = {
	kuro_seaside_leisure_start = {
		image = null, music = "kuro_theme", tags = ['dialogue_scene','master_translate'],
		scene_type = "unlocked_gallery_seq",
		unlocked_gallery_seq = "kuro_seaside",
		character = '$kuro',
		reqs = [
			{type = 'unique_available', name = 'kuro', check = true, negative = 'repeat_next_day'},
			{type = 'quest_completed', name = 'kuro_tome_quest', check = true, negative = 'repeat_next_day'},
			{type = 'real_date_range', start = [1, 6], end = [30, 8], negative = 'repeat_next_day'},
			],
		text = [ {text = "KURO_SEASIDE_START", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_office_2', reqs = [], text = tr("KURO_SEASIDE_OPTION_BUSY"), type = 'next_dialogue', dialogue_argument = 1
		}, {
			code = 'kuro_seaside_leisure_office_2', reqs = [], text = tr("KURO_SEASIDE_OPTION_WEATHER"), type = 'next_dialogue', dialogue_argument = 2
		}, {
			code = 'kuro_seaside_leisure_office_2', reqs = [], text = tr("KURO_SEASIDE_OPTION_WORRIED"), type = 'next_dialogue', dialogue_argument = 3
		} ]
	},

	kuro_seaside_leisure_office_2 = {
		image = null, tags = ['dialogue_scene','master_translate'],
		character = '$kuro',
		reqs = [],
		text = [ {text = "KURO_SEASIDE_OFFICE_2_1", reqs = [], previous_dialogue_option = 1},
		{text = "KURO_SEASIDE_OFFICE_2_2", reqs = [], previous_dialogue_option = 2},
		{text = "KURO_SEASIDE_OFFICE_2_3", reqs = [], previous_dialogue_option = 3}, ],
		options = [ {
			code = 'kuro_seaside_leisure_accept', reqs = [], text = tr("KURO_SEASIDE_OPTION_ACCEPT"), type = 'next_dialogue', dialogue_argument = 1
		}, {
			code = 'kuro_seaside_leisure_refuse', reqs = [], text = tr("KURO_SEASIDE_OPTION_REFUSE"), type = 'next_dialogue', dialogue_argument = 2
		} ]
	},

	kuro_seaside_leisure_accept = {
		image = null, tags = ['dialogue_scene','master_translate'],
		character = '$kuro',
		reqs = [],
		text = [ {text = "KURO_SEASIDE_ACCEPT_1", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_accept_2', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_accept_2 = {
		image = null,tags = ['dialogue_scene','master_translate'],
		character = '$kuro',
		reqs = [],
		text = [ {text = "KURO_SEASIDE_ACCEPT_2", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_resort', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_refuse = {
		image = null, tags = ['dialogue_scene','master_translate'],
		character = '$kuro',
		reqs = [],
		text = [ {text = "KURO_SEASIDE_REFUSE_1", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_refuse_2', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_refuse_2 = {
		image = null,tags = ['dialogue_scene','master_translate'],
		character = '$kuro',
		reqs = [],
		text = [ {text = "KURO_SEASIDE_REFUSE_2", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_resort', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_resort = {
		image = null, music = "exploration", tags = ['dialogue_scene','master_translate','blackscreen_transition_slow'],
		character = 'kuro_beach',
		reqs = [],
		text = [ {text = "KURO_SEASIDE_RESORT_ARRIVAL", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_reveal', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_reveal = {
		image = null, tags = ['dialogue_scene','master_translate'],
		character = 'kuro_beach',
		unlocked_char_sprites = {kuro = ["beach", "beach_lewd", "beach_nude"]},
		reqs = [],
		text = [ {text = "KURO_SEASIDE_REVEAL", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_thanks', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_thanks = {
		image = null, tags = ['dialogue_scene','master_translate','blackscreen_transition_common'],
		reqs = [],
		custom_background = "beach_day",
		text = [ {text = "KURO_SEASIDE_THANKS", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_thanks_glad', reqs = [], text = tr("KURO_SEASIDE_OPTION_GLAD"), type = 'next_dialogue', dialogue_argument = 1
		}, {
			code = 'kuro_seaside_leisure_thanks_refused', reqs = [], text = tr("KURO_SEASIDE_OPTION_SATISFY"), type = 'next_dialogue', dialogue_argument = 2
		} ]
	},

	kuro_seaside_leisure_thanks_glad = {
		image = null, tags = ['dialogue_scene','master_translate'],
		custom_background = "beach_day",
		reqs = [],
		text = [ {text = "KURO_SEASIDE_THANKS_GLAD", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_evening', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_thanks_refused = {
		image = null, tags = ['dialogue_scene','master_translate'],
		custom_background = "beach_day",
		reqs = [],
		text = [ {text = "KURO_SEASIDE_THANKS_REFUSED", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_evening', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_evening = {
		image = null, 
		music = 'intimate', tags = ['dialogue_scene','master_translate','blackscreen_transition_common'],
		custom_background = "beach_evening",
		save_scene_to_gallery = true,
		reqs = [],
		text = [ {text = "KURO_SEASIDE_EVENING", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_end_company', reqs = [], text = tr("KURO_SEASIDE_OPTION_COMPANY"), type = 'next_dialogue', dialogue_argument = 1,
			bonus_effects = [{code = 'affect_unique_character', name = 'kuro', type = 'stat', stat = 'affection', value = 20}],
		}, {
			code = 'kuro_seaside_leisure_end_leave', reqs = [], text = tr("KURO_SEASIDE_OPTION_LEAVE"), type = 'next_dialogue', dialogue_argument = 2
		}, {
			code = 'kuro_seaside_leisure_wits', reqs = [{type = 'master_check', value = [{code = 'stat', stat = 'wits', operant = 'gte', value = 100}]}],
			text = tr("KURO_SEASIDE_OPTION_WITS"), type = 'next_dialogue', dialogue_argument = 3
		}, {
			code = 'kuro_seaside_leisure_wits', disabled = true, reqs = [{type = 'master_check', value = [{code = 'stat', stat = 'wits', operant = 'lt', value = 100}]}],
			text = tr("KURO_SEASIDE_WITS_HIDDEN"), type = 'next_dialogue', dialogue_argument = 3
		} ]
	},

	kuro_seaside_leisure_wits = {
		image = null, tags = ['dialogue_scene','master_translate'],
		custom_background = "beach_evening",
		reqs = [],
		text = [ {text = "KURO_SEASIDE_WITS_1", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_wits_2', reqs = [], text = tr("KURO_SEASIDE_OPTION_PLEASURE"), type = 'next_dialogue', dialogue_argument = 1
		}, {
			code = 'kuro_seaside_leisure_wits_2', reqs = [], text = tr("KURO_SEASIDE_OPTION_USUAL"), type = 'next_dialogue', dialogue_argument = 2
		} ]
	},

	kuro_seaside_leisure_wits_2 = {
		image = null, tags = ['dialogue_scene','master_translate'],
		custom_background = "beach_evening",
		reqs = [],
		text = [ {text = "KURO_SEASIDE_WITS_PLEASURE", reqs = [], previous_dialogue_option = 1},
		{text = "KURO_SEASIDE_WITS_USUAL", reqs = [], previous_dialogue_option = 2}, ],
		options = [ {
			code = 'kuro_seaside_leisure_wits_converge', reqs = [], text = tr("DIALOGUECONTINUE"), type = 'next_dialogue', dialogue_argument = 1
		} ]
	},

	kuro_seaside_leisure_wits_converge = {
		image = null, tags = ['dialogue_scene','master_translate'],
		custom_background = "beach_evening",
		reqs = [],
		text = [ {text = "KURO_SEASIDE_WITS_CONVERGE", reqs = []} ],
		options = [ {
			code = 'kuro_seaside_leisure_end_company', reqs = [], text = tr("KURO_SEASIDE_OPTION_COMPANY"), type = 'next_dialogue', dialogue_argument = 1,
			bonus_effects = [{code = 'affect_unique_character', name = 'kuro', type = 'stat', stat = 'affection', value = 20}],
		}, {
			code = 'kuro_seaside_leisure_end_leave', reqs = [], text = tr("KURO_SEASIDE_OPTION_LEAVE"), type = 'next_dialogue', dialogue_argument = 2
		} ]
	},

	kuro_seaside_leisure_end_company = {
		image = null, tags = ['dialogue_scene','master_translate'],
		custom_background = "beach_evening",
		reqs = [],
		text = [ {text = "KURO_SEASIDE_END_COMPANY", reqs = []} ],
		options = [ {
			code = 'close', reqs = [], text = tr("DIALOGUECLOSE"), type = 'next_dialogue', dialogue_argument = 1,
			bonus_effects = [{code = 'update_city'}],
		} ]
	},

	kuro_seaside_leisure_end_leave = {
		image = null, tags = ['dialogue_scene','master_translate'],
		custom_background = "beach_evening",
		reqs = [],
		text = [ {text = "KURO_SEASIDE_END_LEAVE", reqs = []} ],
		options = [ {
			code = 'close', reqs = [], text = tr("DIALOGUECLOSE"), type = 'next_dialogue', dialogue_argument = 1,
			bonus_effects = [{code = 'update_city'}],
		} ]
	},
}
