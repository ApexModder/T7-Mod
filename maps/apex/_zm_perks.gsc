#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	include_perks();
	precache_perks();
	spawn_perk_machines();
	OnPlayerConnect_Callback(::player_connect);
}

player_connect()
{
	self.num_perks = 0;
	self._obtained_perks = [];

	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
	{
		perks = get_valid_perks_array();

		for(i = 0; i < perks.size; i++)
		{
			self SetClientDvars(
				"ui_zm_perk_" + perks[i] + "_x", 0,
				"ui_zm_perk_" + perks[i] + "_image", level._custom_perks[perks[i]].shader,
				"ui_zm_perk_" + perks[i] + "_alpha", 0
			);
		}
	}
}

include_perks()
{
	if(!isdefined(level._zm_perk_includes))
		level._zm_perk_includes = ::default_include_perks;

	set_zombie_var("zombie_perk_cost", 2000);
	set_zombie_var("zombie_perk_bottle", "zombie_perk_bottle");
	set_zombie_var("zombie_perk_hint", &"ZOMBIE_PERK_GENERIC");
	set_zombie_var("zombie_perk_limit", 4);
	set_zombie_var("zombie_perk_use_menu_hud", true);
	set_zombie_var("zombie_perk_collision_model", "collision_geo_64x64x256");

	run_function(level, level._zm_perk_includes);
}

default_include_perks()
{
	maps\apex\perks\_zm_perk_juggernog::include_perk_for_level();
	maps\apex\perks\_zm_perk_double_tap::include_perk_for_level();
	maps\apex\perks\_zm_perk_sleight_of_hand::include_perk_for_level();
	maps\apex\perks\_zm_perk_quick_revive::include_perk_for_level();

	maps\apex\perks\_zm_perk_divetonuke::include_perk_for_level();
	maps\apex\perks\_zm_perk_marathon::include_perk_for_level();
	maps\apex\perks\_zm_perk_deadshot::include_perk_for_level();
	maps\apex\perks\_zm_perk_additionalprimaryweapon::include_perk_for_level();

	maps\apex\perks\_zm_perk_tombstone::include_perk_for_level();
	maps\apex\perks\_zm_perk_chugabud::include_perk_for_level();
	maps\apex\perks\_zm_perk_electric_cherry::include_perk_for_level();
	maps\apex\perks\_zm_perk_vulture_aid::include_perk_for_level();

	maps\apex\perks\_zm_perk_widows_wine::include_perk_for_level();
}

precache_perks()
{
	perks = get_valid_perks_array();
	PrecacheItem(level.zombie_vars["zombie_perk_bottle"]);
	PrecacheString(level.zombie_vars["zombie_perk_hint"]);
	PrecacheModel(level.zombie_vars["zombie_perk_collision_model"]);

	level._effect["perk_light_yellow"]= LoadFX("misc/fx_zombie_cola_dtap_on");
	level._effect["perk_light_red"]= LoadFX("misc/fx_zombie_cola_jugg_on");
	level._effect["perk_light_blue"]= LoadFX("misc/fx_zombie_cola_revive_on");
	level._effect["perk_light_green"]= LoadFX("misc/fx_zombie_cola_on");

	for(i = 0; i < perks.size; i++)
	{
		PrecacheShader(level._custom_perks[perks[i]].shader);

		if(isdefined(level._custom_perks[perks[i]].hint))
			PrecacheString(level._custom_perks[perks[i]].hint);
		if(isdefined(level._custom_perks[perks[i]].bottle))
			PrecacheItem(level._custom_perks[perks[i]].bottle);
		if(isdefined(level._custom_perks[perks[i]].machine_on))
			PrecacheModel(level._custom_perks[perks[i]].machine_on);
		if(isdefined(level._custom_perks[perks[i]].machine_off))
			PrecacheModel(level._custom_perks[perks[i]].machine_off);
	}

	// in debug mode we remove the perk limit
	/# level.zombie_vars["zombie_perk_limit"] = perks.size; #/
}

//============================================================================================
// Power
//============================================================================================
perk_power_on()
{
	stub = self.playertrigger;
	perk = stub.script_noteworthy;

	if(isdefined(level._custom_perks[perk].machine_on))
		stub.machine SetModel(level._custom_perks[perk].machine_on);

	stub.machine Vibrate((0, -100, 0), .3, .4, 3);
	stub.machine PlaySound("zmb_perks_power_on");
	stub.machine thread perk_power_effects_think(perk);
	stub.power_on = true;
}

perk_power_off()
{
	stub = self.playertrigger;
	stub.power_on = false;
	perk = stub.script_noteworthy;

	if(isdefined(level._custom_perks[perk].machine_off))
		stub.machine SetModel(level._custom_perks[perk].machine_off);

	stub.machine notify("stop_perk_power_effects");
	stub.machine Vibrate((0, -100, 0), .3, .4, 3);
}

perk_power_effects_think(perk)
{
	ent = spawn_model("tag_origin", self.origin, self.angles);
	ent LinkTo(self);
	ent PlayLoopSound("zmb_perks_machine_loop");

	wait 3;

	if(isdefined(level._custom_perks[perk].light_fx))
		PlayFXOnTag(level._effect[level._custom_perks[perk].light_fx], ent, "tag_origin");

	self waittill("stop_perk_power_effects");
	ent StopLoopSound();
	ent Unlink();
	ent Delete();
}

//============================================================================================
// PlayerTrigger / Machines
//============================================================================================
generate_perk_spawn_struct(perk, origin, angles)
{
	struct = SpawnStruct();
	struct.origin = origin;
	struct.script_noteworthy = perk;

	if(isdefined(angles))
		struct.angles = angles + (0, 90, 0);
	else
		struct.angles = (0, 0, 0);

	if(!isdefined(level._generated_perk_machines))
		level._generated_perk_machines = [];
	level._generated_perk_machines[level._generated_perk_machines.size] = struct;
	return struct;
}

spawn_perk_machines()
{
	level._zm_perk_machines = [];
	structs = GetStructArray("zm_perk_machine", "targetname");
	convert_legacy_perk_machines();

	if(isdefined(level._generated_perk_machines))
		structs = array_merge(structs, level._generated_perk_machines);
	if(!isdefined(structs) || structs.size == 0)
		return;

	for(i = 0; i < structs.size; i++)
	{
		struct = structs[i];

		if(!isdefined(struct.origin) || !isdefined(struct.script_noteworthy))
			continue;
		if(!is_perk_valid(struct.script_noteworthy))
			continue;

		origin = struct.origin;
		perk = struct.script_noteworthy;
		angles = struct.angles;
		model = "zombie_vending_jugg";

		if(!isdefined(level._zm_perk_machines[perk]))
			level._zm_perk_machines[perk] = [];
		if(!isdefined(angles))
			angles = struct.angles;

		// Spawn perk machine
		if(isdefined(struct.machine_override))
		{
			struct.machine = struct.machine_override;
			model = struct.machine.model;
			angles = struct.machine.angles;
		}
		else
			struct.machine = spawn_model("tag_origin", origin, angles);

		if(isdefined(level._custom_perks[perk].machine_off))
			model = level._custom_perks[perk].machine_off;

		struct.machine.origin = origin;
		struct.machine.angles = angles;
		struct.machine SetModel(model);

		// Spawn perk collision
		if(isdefined(struct.clip_override))
			struct.clip = struct.clip_override;
		else
			struct.clip = Spawn("script_model", origin, 1);

		// struct.clip.origin = origin;
		struct.clip.angles = angles;
		struct.clip DisconnectPaths();
		struct.clip Hide();

		if(struct.clip.classname == "script_model")
			struct.clip SetModel(level.zombie_vars["zombie_perk_collision_model"]);

		// Spawn perk bump trigger
		struct.bump = Spawn("trigger_radius", origin, 0, 40, 50);
		struct.bump.angles = angles;
		struct.bump thread perk_audio_bump_trigger_think();

		// powerable
		struct.powerable = maps\apex\_zm_power::add_powerable(level._custom_perks[perk].ignore_power, ::perk_power_on, ::perk_power_off);
		struct.powerable.ignore_power = level._custom_perks[perk].ignore_power;
		struct.powerable.playertrigger = struct;

		// Setup spawn struct as a playertrigger stub
		struct.origin = origin + (0, 0, 60);
		struct.radius = 40;
		struct.height = 80;
		struct.script_unitrigger_type = "playertrigger_radius_use";
		struct.prompt_and_visibility_func = ::playertrigger_update_prompt;
		struct.power_on = false;

		if(isdefined(level._custom_perks[perk].jingle))
		{
			struct thread perk_machine_jingle_timer();
			struct thread play_random_broken_sounds();
		}

		register_playertrigger(struct, ::playertrigger_think);
		level._zm_perk_machines[perk][level._zm_perk_machines[perk].size] = struct;
	}
}

convert_legacy_perk_machines()
{
	triggers = GetEntArray("zombie_vending", "targetname");
	perks = get_valid_perks_array();

	for(i = 0; i < triggers.size; i++)
	{
		if(isdefined(triggers[i].script_noteworthy))
		{
			targets = GetEntArray(triggers[i].target, "targetname");
			perk = get_perk_from_speciality(triggers[i].script_noteworthy);

			if(!isdefined(perk))
				perk = triggers[i].script_noteworthy;

			if(is_perk_valid(perk))
			{
				machine = undefined;
				clip = undefined;

				for(j = 0; j < targets.size; j++)
				{
					if(is_equal(targets[j].script_noteworthy, "clip"))
					{
						if(!isdefined(clip))
						{
							clip = targets[j];
							continue;
						}
						targets[j] ConnectPaths();
					}
					else
					{
						if(!isdefined(machine))
						{
							machine = targets[j];
							continue;
						}
					}

					targets[j] Delete();
				}

				origin = triggers[i].origin;
				angles = triggers[i].angles;

				if(isdefined(machine))
				{
					origin = machine.origin;
					angles = machine.angles;
				}

				stub = generate_perk_spawn_struct(perk, origin, angles);
				stub.machine_override = machine;
				stub.clip_override = clip;
			}
			else
			{
				for(j = 0; j < targets.size; j++)
				{
					if(is_equal(targets[j].script_noteworthy, "clip"))
						targets[j] ConnectPaths();
					targets[j] Delete();
				}
			}
		}
		triggers[i] Delete();
	}
}

playertrigger_update_prompt(player)
{
	if(!self trigger_visible_to_player(player))
		return false;

	if(is_true(self.stub.power_on))
	{
		self.hint_string = get_perk_hint_string(self.stub.script_noteworthy);
		self.hint_param1 = player get_perk_cost(self.stub.script_noteworthy);
		// self maps\apex\_utility_code::playertrigger_set_hintstring();
		return true;
	}
	else
	{
		self.hint_string = &"ZOMBIE_NEED_POWER";
		// self maps\apex\_utility_code::playertrigger_set_hintstring();
		return true;
	}
}

playertrigger_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill("trigger", player);

		if(!is_true(self.stub.power_on))
			continue;

		player thread vending_trigger_give_perk(self.stub);
	}
}

trigger_visible_to_player(player)
{
	if(player has_perk(self.stub.script_noteworthy))
		return false;
	if(!self vending_trigger_can_player_use(player))
		return false;
	if(player in_revive_trigger())
		return false;

	weapon = player GetCurrentWeapon();

	if(is_equipment/*_that_blocks_purchase*/(weapon))
		return false;
	if(player hacker_active())
		return false;
	return true;
}

vending_trigger_can_player_use(player)
{
	if(player maps\_laststand::player_is_in_laststand() || is_true(player.intermission))
		return false;
	if(player in_revive_trigger())
		return false;
	if(!player maps\apex\_zm_weapons::can_buy_weapon())
		return false;
	if(player IsThrowingGrenade())
		return false;
	if(player IsSwitchingWeapons())
		return false;
	if(player is_drinking())
		return false;
	return true;
}

vending_trigger_give_perk(stub)
{
	self endon("disconnect");

	perk = stub.script_noteworthy;
	cost = self get_perk_cost(perk);
	perk_limit = self get_player_perk_purchase_limit();

	if(self.score < cost)
	{
		PlaySoundAtPosition("evt_perk_deny", stub.origin);
		self maps\_zombiemode_audio::create_and_play_dialog("general", "perk_deny", undefined, 0);
		return;
	}

	if(self.num_perks >= perk_limit)
	{
		PlaySoundAtPosition("evt_perk_deny", stub.origin);
		self maps\_zombiemode_audio::create_and_play_dialog("general", "sigh");
		return;
	}

	PlaySoundAtPosition("evt_bottle_dispense", stub.origin);
	self maps\_zombiemode_score::minus_to_player_score(cost);
	self.perk_purchased = perk;

	if(isdefined(level._custom_perks[perk].sting))
		stub.machine thread maps\_zombiemode_audio::play_jingle_or_stinger(level._custom_perks[perk].sting);

	self thread drink_and_give_perk(perk, true);
}

get_perk_machines(perk)
{
	if(!is_perk_valid(perk))
		return undefined;
	if(!isdefined(level._zm_perk_machines))
		return undefined;
	if(!isdefined(level._zm_perk_machines[perk]))
		return undefined;
	return level._zm_perk_machines[perk];
}

delete_perk_machines(perk)
{
	machines = get_perk_machines(perk);
	array_thread(machines, ::delete_perk_machines_think);
}

delete_perk_machines_think()
{
	unregister_playertrigger(self);

	if(is_true(self.hidden))
		return;

	self.power_on = false;
	self.hidden = true;
	self.powerable.ignore_power = true;
	self.machine notify("stop_perk_power_effects");

	origin = self.machine.origin;
	self.machine PlaySound("zmb_box_move");
	PlaySoundAtPosition("zmb_whoosh", origin);
	self.machine MoveTo(origin + (0, 0, 40), 3);

	if(isdefined(level.custom_vibrate_func))
		run_function(self.machine, level.custom_vibrate_func, self.machine);
	else
	{
		dir = origin;
		dir = (dir[1], dir[0], 0);

		if(dir[1] < 0 || (dir[0] > 0 && dir[1] > 0))
			dir = (dir[0], dir[1] * -1, 0);
		else if(dir[0] < 0)
			dir = (dir[0] * -1, dir[1], 0);

		self.machine Vibrate(dir, 10, .5, 5);
	}

	self.machine waittill("movedone");
	PlayFX(level._effect["poltergeist"], origin);
	PlaySoundAtPosition("zmb_box_poof", origin);
	self.machine Hide();
	self.machine NotSolid();
	self.clip ConnectPaths();
	self.clip trigger_off();
	self.bump trigger_off();
	self.machine.origin = origin;
}

reenable_perk_machines(perk)
{
	machines = get_perk_machines(perk);
	array_thread(machines, ::reenable_perk_machines_think);
}

reenable_perk_machines_think()
{
	if(!is_true(self.hidden))
		return;

	self.clip trigger_on();
	self.clip DisconnectPaths();
	self.machine Show();
	self.machine Solid();
	self.bump trigger_on();
	PlayFX(level._effect["poltergeist"], self.origin);
	PlaySoundAtPosition("zmb_box_poof", self.origin);
	self.hidden = false;

	if(maps\apex\_zm_power::is_power_on() || is_true(level._custom_perks[self.script_noteworthy].ignore_power))
	{
		self.powerable.power_on = true;
		self.powerable perk_power_on();
	}
	else
	{
		self.powerable.power_on = false;
		self.powerable perk_power_off();
	}

	if(!is_true(level._custom_perks[self.script_noteworthy].ignore_power))
		self.powerable.ignore_power = false;

	register_playertrigger(self, ::playertrigger_think);
}

// custom function to allow
// power on / off
perk_machine_jingle_timer()
{
	for(;;)
	{
		wait RandomFloatRange(31, 45);

		if(!is_true(self.power_on))
			continue;
		if(is_true(self.hidden))
			continue;
		if(RandomInt(100) < 15)
			self.machine thread maps\_zombiemode_audio::play_jingle_or_stinger(level._custom_perks[self.script_noteworthy].jingle);
	}
}

play_random_broken_sounds()
{
	for(;;)
	{
		wait RandomFloatRange(7, 18);

		if(!is_true(self.power_on))
			continue;
		if(is_true(self.hidden))
			continue;

		PlaySoundAtPosition("evt_electrical_surge", self.origin);

		if(self.script_noteworthy == "revive")
			PlaySoundAtPosition("zmb_perks_broken_jingle", self.origin);
	}
}

perk_audio_bump_trigger_think()
{
	self endon("death");

	in_trigger = [];
	extra_change = [];

	for(;;)
	{
		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			num = players[i] GetEntityNumber();

			if(is_true(in_trigger[num]))
			{
				if(is_true(extra_change[num]))
					continue;

				if(players[i] GetStance() == "prone")
				{
					extra_change[num] = true;
					players[i] maps\_zombiemode_score::add_to_player_score(100);
				}
			}

			if(players[i] IsTouching(self))
			{
				if(is_true(in_trigger[num]))
					continue;

				in_trigger[num] = true;
				players[i] PlaySound("fly_bump_bottle");
			}
			else
			{
				if(is_true(in_trigger[num]))
					in_trigger[num] = false;
			}
		}
		wait .05;
	}
}

//============================================================================================
// Perk Logic
//============================================================================================
perk_think(perk)
{
	perk_str = perk + "_stop";
	result = self waittill_any_return("fake_death", "death", "player_downed", perk_str);

	if(self should_ratain_perk(perk))
	{
		self thread perk_think(perk);
		return;
	}

	if(result != perk_str)
		self notify(perk_str);

	self._obtained_perks = array_remove_nokeys(self._obtained_perks, perk);
	self.num_perks--;

	if(isdefined(level._custom_perks[perk].specialties))
	{
		for(i = 0; i < level._custom_perks[perk].specialties.size; i++)
		{
			self UnSetPerk(level._custom_perks[perk].specialties[i]);
		}
	}

	if(isdefined(level._custom_perks[perk].take_func))
		single_thread(self, level._custom_perks[perk].take_func, result);

	self levelNotify("client_take_perk_" + perk);
	self perk_hud_destroy(perk);
	self.perk_purchased = undefined;

	if(isdefined(level.perk_lost_func))
		run_function(self, level.perk_lost_func, perk);

	self notify("perk_lost", perk);
}

should_ratain_perk(perk)
{
	if(!is_perk_valid(perk))
		return false;

	if(isdefined(level._custom_perks[perk].retain_func))
	{
		retain_perk = run_function(self, level._custom_perks[perk].retain_func);

		if(is_true(retain_perk))
			return true;
	}

	// retain all perks
	if(is_true(self._retain_perks))
		return true;
	// retain this specific perk
	if(isdefined(self._retain_perk_array) && is_true(self._retain_perk_array[perk]))
		return true;
	return false;
}

wait_give_perk(perk, bought)
{
	self endon("player_downed");
	self endon("disconnect");
	self endon("perk_abort_drinking");
	level endon("end_game");

	self waittill_any_or_timeout(.5, "burp");

	if(isdefined(level.perk_bought_func))
		run_function(self, level.perk_bought_func, perk);

	self give_perk(perk, bought);
}

//============================================================================================
// Perk Bottle Drink Anim
//============================================================================================
drink_from_perk_bottle(perk)
{
	gun = self do_perk_bottle_drink_start(perk);
	self waittill_any("fake_death", "death", "player_downed", "weapon_change_complete", "perk_abort_drinking");
	self do_perk_bottle_drink_end(perk, gun);
}

do_perk_bottle_drink_start(perk)
{
	self increment_is_drinking();
	self disable_player_move_states(true);
	bottle = get_perk_bottle(perk);
	weapon_options = self get_perk_bottle_weapon_options(perk);
	model_index = 0;
	gun = self GetCurrentWeapon();

	if(isdefined(level._custom_perks[perk].model_index))
		model_index = level._custom_perks[perk].model_index;

	self GiveWeapon(bottle, model_index, weapon_options);
	self SwitchToWeapon(bottle);
	return gun;
}

do_perk_bottle_drink_end(perk, gun)
{
	self enable_player_move_states();
	self maps\apex\_zm_weapons::weapon_take(get_perk_bottle(perk));

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	if(self is_multiple_drinking())
	{
		self decrement_is_drinking();
		return;
	}
	else
		self maps\apex\_zm_weapons::switch_back_primary_weapon(gun);

	self waittill("weapon_change_complete");

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	self decrement_is_drinking();
}

//============================================================================================
// Perk Hud
//============================================================================================
perk_hud_create(perk)
{
	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
		self perk_hud_create_menu(perk);
	else
		self perk_hud_create_legacy(perk);
}

perk_hud_destroy(perk)
{
	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
		self perk_hud_destroy_menu(perk);
	else
		self perk_hud_destroy_legacy(perk);
}

perk_hud_start_flash(perk)
{
	if(!self has_perk(perk))
		return;
	if(!isdefined(self.perk_hud_flash))
		self.perk_hud_flash = [];

	if(!is_true(self.perk_hud_flash[perk]))
	{
		self.perk_hud_flash[perk] = true;
		self perk_hud_flash(perk, true);

		if(isdefined(level._custom_perks[perk].flash))
			self PlayLocalSound(level._custom_perks[perk].flash);
	}
}

perk_hud_stop_flash(perk, taken)
{
	if(!self has_perk(perk))
		return;
	if(!isdefined(self.perk_hud_flash))
		self.perk_hud_flash = [];

	if(is_true(self.perk_hud_flash[perk]))
	{
		self.perk_hud_flash[perk] = false;
		self perk_hud_flash(perk, false);
	}
}

perk_hud_flash(perk, on_off)
{
	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
		self perk_hud_flash_menu(perk, on_off);
	else
		self perk_hud_flash_legacy(perk, on_off);
}

update_perk_hud()
{
	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
		self update_perk_hud_menu();
	else
		self update_perk_hud_legacy();
}

// Menu Hud
perk_hud_create_menu(perk)
{
	if(!isdefined(self.perk_hud))
		self.perk_hud = [];
	if(isdefined(self.perk_hud[perk]))
		return;

	x = self.perk_hud.size * 30;

	self SetClientDvars(
		"ui_zm_perk_" + perk + "_x", x,
		"ui_zm_perk_" + perk + "_alpha", 1
	);

	self.perk_hud[perk] = x;
}

perk_hud_destroy_menu(perk)
{
	if(!isdefined(self.perk_hud))
		return;
	if(!isdefined(self.perk_hud[perk]))
		return;

	self.perk_hud[perk] = undefined;

	self SetClientDvars(
		"ui_zm_perk_" + perk + "_x", 0,
		"ui_zm_perk_" + perk + "_alpha", 0
	);
}

update_perk_hud_menu()
{
	if(isdefined(self.perk_hud))
	{
		keys = GetArrayKeys(self.perk_hud);

		for(i = 0; i < keys.size; i++)
		{
			self SetClientDvar("ui_zm_perk_" + keys[i] + "_x", i * 30);
		}
	}
}

perk_hud_flash_menu(perk, on_off)
{
	if(!isdefined(self.perk_hud))
		self.perk_hud = [];
	if(!isdefined(self.perk_hud[perk]))
		return;

	if(is_true(on_off))
		self SetClientDvar("ui_zm_perk_" + perk + "_alpha", .333);
	else
		self SetClientDvar("ui_zm_perk_" + perk + "_alpha", 1);
}

// Legacy Hud
perk_hud_create_legacy(perk)
{
	if(!isdefined(self.perk_hud))
		self.perk_hud = [];
	if(isdefined(self.perk_hud[perk]))
		return;

	shader = level._custom_perks[perk].shader;
	hud = create_simple_hud(self);
	hud.foreground = true;
	hud.sort = 1;
	hud.hidewheninmenu = true;
	hud.alignX = "left";
	hud.alignY = "bottom";
	hud.horzAlign = "user_left";
	hud.vertAlign = "user_bottom";
	hud.x = self.perk_hud.size * 30;
	hud.y -= 70;
	hud.alpha = 1;
	hud SetShader(shader, 24, 24);
	self.perk_hud[perk] = hud;
}

perk_hud_destroy_legacy(perk)
{
	if(!isdefined(self.perk_hud))
		return;
	if(!isdefined(self.perk_hud[perk]))
		return;

	self.perk_hud[perk] destroy_hud();
	self.perk_hud[perk] = undefined;
}

perk_hud_flash_legacy(perk, on_off)
{
	if(!isdefined(self.perk_hud))
		self.perk_hud = [];
	if(!isdefined(self.perk_hud[perk]))
		return;

	if(is_true(on_off) && !is_true(self.perk_hud[perk].flash))
	{
		self.perk_hud[perk].flash = true;
		self.perk_hud[perk] ScaleOverTime(.05, 32, 32);
		wait .3;
		self.perk_hud[perk] ScaleOverTime(.05, 24, 24);
		wait .3;
		self.perk_hud[perk].flash = false;
	}
}

update_perk_hud_legacy()
{
	if(isdefined(self.perk_hud))
	{
		keys = GetArrayKeys(self.perk_hud);

		for(i = 0; i < keys.size; i++)
		{
			self.perk_hud[keys[i]].x = i * 30;
		}
	}
}

//============================================================================================
// Utilities
//============================================================================================
get_valid_perks_array()
{
	if(isdefined(level._zm_valid_perk_array_cache))
		return level._zm_valid_perk_array_cache; // only need to build this array once
	else
	{
		result = [];

		if(isdefined(level._custom_perks))
		{
			keys = GetArrayKeys(level._custom_perks);

			for(i = 0; i < level._custom_perks.size; i++)
			{
				if(is_perk_valid(keys[i]))
					result[result.size] = keys[i];
			}
		}

		level._zm_valid_perk_array_cache = result;
		return result;
	}
}

get_perk_from_speciality(specialty)
{
	perks = get_valid_perks_array();

	for(i = 0; i < perks.size; i++)
	{
		if(!isdefined(level._custom_perks[perks[i]].specialties) || level._custom_perks[perks[i]].specialties.size == 0)
			continue;
		if(IsInArray(level._custom_perks[perks[i]].specialties, specialty))
			return perks[i];
	}
	return undefined;
}

drink_and_give_perk(perk, bought)
{
	self endon("disconnect");
	level endon("end_game");
	self endon("perk_abort_drinking");

	gun = self do_perk_bottle_drink_start(perk);
	result = self waittill_any_return("fake_death", "death", "player_downed", "weapon_change_complete", "perk_abort_drinking");

	if(result == "weapon_change_complete")
		self thread wait_give_perk(perk, bought);

	self do_perk_bottle_drink_end(perk, gun);

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	self notify("burp");
	self.perk_purchased = undefined;
}

give_perk(perk, bought)
{
	if(!is_perk_valid(perk))
		return;
	if(self has_perk(perk))
		return;

	self._obtained_perks[self._obtained_perks.size] = perk;
	self.num_perks++;

	if(is_true(bought))
	{
		self thread maps\_zombiemode_audio::perk_vox(perk);
		self SetBlur(4, .1);
		wait .1;
		self SetBlur(0, .1);
		self notify("perk_bought", perk);
	}

	if(isdefined(level._custom_perks[perk].give_func))
		single_thread(self, level._custom_perks[perk].give_func);

	if(isdefined(level._custom_perks[perk].specialties))
	{
		for(i = 0; i < level._custom_perks[perk].specialties.size; i++)
		{
			self SetPerk(level._custom_perks[perk].specialties[i]);
		}
	}

	self levelNotify("client_give_perk_" + perk);
	self perk_hud_create(perk);
	self.stats["perks"]++;
	self thread perk_think(perk);
}

take_perk(perk)
{
	if(self has_perk(perk))
		self notify(perk + "_stop");
}

give_random_perk()
{
	perks = self get_player_unobtained_perks();

	if(!isdefined(perks) || perks.size == 0)
		return undefined;

	perk = random(perks);
	self give_perk(perk, false);
	return perk;
}

lose_random_perk()
{
	perks = self get_player_obtained_perks();

	if(!isdefined(perks) || perks.size == 0)
		return undefined;

	perk = random(perks);
	self take_perk(perk);
	return perk;
}

get_perk_cost(perk)
{
	if(!is_perk_valid(perk))
		return -1;

	cost = level.zombie_vars["zombie_perk_cost"];

	if(isdefined(level._custom_perks[perk].cost))
	{
		if(IsInt(level._custom_perks[perk].cost))
			cost = level._custom_perks[perk].cost;
		else
			cost = run_function(self, level._custom_perks[perk].cost);
	}
	return cost;
}

get_perk_hint_string(perk)
{
	hint_string = level.zombie_vars["zombie_perk_hint"];

	if(!is_perk_valid(perk))
		return hint_string;

	if(isdefined(level._custom_perks[perk].hint))
		hint_string = level._custom_perks[perk].hint;
	return hint_string;
}

get_perk_bottle(perk)
{
	bottle = level.zombie_vars["zombie_perk_bottle"];

	if(!is_perk_valid(perk))
		return bottle;
	if(isdefined(level._custom_perks[perk].bottle))
		bottle = level._custom_perks[perk].bottle;
	return bottle;
}

get_perk_bottle_weapon_options(perk)
{
	if(!isdefined(self._perk_bottle_weapon_options))
		self._perk_bottle_weapon_options = [];
	if(isdefined(self._perk_bottle_weapon_options[perk]))
		return self._perk_bottle_weapon_options[perk];

	camo_index = 0;

	if(is_perk_valid(perk) && isdefined(level._custom_perks[perk].camo_index))
		camo_index = level._custom_perks[perk].camo_index;

	self._perk_bottle_weapon_options[perk] = self CalcWeaponOptions(camo_index);
	return self._perk_bottle_weapon_options[perk];
}

award_free_solo_revive()
{
	if(!isdefined(level.solo_game_free_player_quickrevive))
		level.solo_game_free_player_quickrevive = 0;
	level.solo_game_free_player_quickrevive++;
}

//============================================================================================
// Perk Damager Overrides
//============================================================================================
register_perk_damage_override_func(func_damage_override)
{
	if(!isdefined(level.perk_damage_override))
		level.perk_damage_override = [];
	if(!IsInArray(level.perk_damage_override, func_damage_override))
		level.perk_damage_override[level.perk_damage_override.size] = func_damage_override;
}

process_player_perk_damage_override(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(isdefined(level.perk_damage_override))
	{
		for(i = 0; i < level.perk_damage_override.size; i++)
		{
			// too many args for run_function
			// n_damage = run_function(self, level.perk_damage_override[i], eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			n_damage = self [[level.perk_damage_override[i]]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

			if(isdefined(n_damage))
				iDamage = n_damage;
		}
	}
	return iDamage;
}

//============================================================================================
// Registry
//============================================================================================
is_perk_valid(perk)
{
	if(!isdefined(level._custom_perks))
		return false;
	if(!isdefined(level._custom_perks[perk]))
		return false;
	return is_true(level._custom_perks[perk].valid);
}

_register_undefined_perk(perk)
{
	if(!isdefined(level._custom_perks))
		level._custom_perks = [];
	if(isdefined(level._custom_perks[perk]))
		return;

	level._custom_perks[perk] = SpawnStruct();
}

register_perk(perk, shader)
{
	_register_undefined_perk(perk);

	level._custom_perks[perk].shader = shader;
	level._custom_perks[perk].valid = true;
}

add_perk_specialty(perk, specialty)
{
	_register_undefined_perk(perk);

	if(!isdefined(level._custom_perks[perk].specialties))
		level._custom_perks[perk].specialties = [];
	if(!IsInArray(level._custom_perks[perk].specialties, specialty))
		level._custom_perks[perk].specialties[level._custom_perks[perk].specialties.size] = specialty;
}

register_perk_bottle(perk, bottle, model_index, camo_index)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].bottle = bottle;
	level._custom_perks[perk].model_index = model_index;
	level._custom_perks[perk].camo_index = camo_index;
}

register_perk_machine(perk, ignore_power, hint, cost, machine_off, machine_on, light_fx)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].ignore_power = ignore_power;
	level._custom_perks[perk].hint = hint;
	level._custom_perks[perk].cost = cost;
	level._custom_perks[perk].machine_off = machine_off;
	level._custom_perks[perk].machine_on = machine_on;
	level._custom_perks[perk].light_fx = light_fx;
}

register_perk_threads(perk, give_func, take_func, retain_func)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].give_func = give_func;
	level._custom_perks[perk].take_func = take_func;
	level._custom_perks[perk].retain_func = retain_func;
}

register_perk_sounds(perk, sting, jingle, flash)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].sting = sting;
	level._custom_perks[perk].jingle = jingle;
	level._custom_perks[perk].flash = flash;
}