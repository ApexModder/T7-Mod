#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	level.zombie_weapons = [];
	level.zombie_weapons_upgraded = [];
	include_weapons();
	maps\apex\_zm_melee_weapon::init();
	maps\apex\_zm_placeable_mine::init();
	load_weapons_for_level();
	maps\apex\_zm_lightning_chain::init();
	init_weapon_upgrade();
	OnPlayerSpawned_Callback(::player_spawned);
	level thread register_weapon_data_client_side();
}

include_weapons()
{
	add_weapon_include_callback("freezegun_zm",				maps\apex\weapons\_zm_weap_freezegun::include_weapon_for_level);
	add_weapon_include_callback("claymore_zm",				maps\apex\weapons\_zm_weap_claymore::include_weapon_for_level);
	add_weapon_include_callback("crossbow_explosive_zm",	maps\apex\weapons\_zm_weap_crossbow::include_weapon_for_level);
	add_weapon_include_callback("zombie_cymbal_monkey",		maps\apex\weapons\_zm_weap_cymbal_monkey::include_weapon_for_level);
	add_weapon_include_callback("tesla_gun_zm",				maps\apex\weapons\_zm_weap_tesla::include_weapon_for_level);
	add_weapon_include_callback("thundergun_zm",			maps\apex\weapons\_zm_weap_thundergun::include_weapon_for_level);
	add_weapon_include_callback("zombie_nesting_dolls",		maps\apex\weapons\_zm_weap_nesting_dolls::include_weapon_for_level);
	add_weapon_include_callback("zombie_black_hole_bomb",		maps\apex\weapons\_zm_weap_black_hole_bomb::include_weapon_for_level);
}

//============================================================================================
// Grenade Duds
//============================================================================================
player_spawned()
{
	self thread watchForGrenadeDuds();
	self thread watchForGrenadeLauncherDuds();
	self.staticWeaponStartTime = GetTime();
}

watchForGrenadeDuds()
{
	self endon("spawned_player");
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_fire", grenade, weapon);

		if(!is_equipment(weapon) && !is_placeable_mine(weapon))
		{
			grenade thread checkForGrenadeDud(weapon, true, self);
			grenade thread watchForScriptExplosion(weapon, true, self);
		}
	}
}

watchForGrenadeLauncherDuds()
{
	self endon("spawned_player");
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_launcher_fire", grenade, weapon);
		grenade thread checkForGrenadeDud(weapon, false, self);
		grenade thread watchForScriptExplosion(weapon, false, self);
	}
}

grenade_safe_to_throw(player, weapon)
{
	if(isdefined(level.grenade_safe_to_throw))
		return run_function(self, level.grenade_safe_to_throw, player, weapon);
	return true;
}

grenade_safe_to_bounce(player, weapon)
{
	if(isdefined(level.grenade_safe_to_bounce))
		return run_function(self, level.grenade_safe_to_bounce, player, weapon);
	return true;
}

makeGrenadeDudAndDestroy()
{
	self endon("death");
	self notify("grenade_dud");
	// self MakeGrenadeDud();
	wait 3;

	if(isdefined(self))
		self Delete();
}

checkForGrenadeDud(weapon, isThrownGrenade, player)
{
	self endon("death");
	player endon("zombify");

	if(!self grenade_safe_to_throw(player, weapon))
	{
		self thread makeGrenadeDudAndDestroy();
		return;
	}

	for(;;)
	{
		self waittill_any_or_timeout(.25, "grenade_bounce", "stationary");

		if(!self grenade_safe_to_bounce(player, weapon))
		{
			self thread makeGrenadeDudAndDestroy();
			return;
		}
	}
}

wait_explode()
{
	self endon("grenade_dud");
	self endon("done");
	self waittill("explode", origin);
	level.explode_position = origin;
	level.explode_position_valid = true;
	self notify("done");
}

wait_timeout(time)
{
	self endon("grenade_dud");
	self endon("done");
	wait time;
	self notify("done");
}

wait_for_explosion(time)
{
	level.explode_position = (0, 0, 0);
	level.explode_position_valid = false;
	self thread wait_explode();
	self thread wait_timeout(time);
	self waittill("done");
	self notify("death_or_explode", level.explode_position, level.explode_position_valid);
}

watchForScriptExplosion(weapon, isThrownGrenade, player)
{
	self endon("grenade_dud");

	if(is_lethal_grenade(weapon) /*|| is_grenade_launcher(weapon)*/)
	{
		self thread wait_for_explosion(20);
		self waittill("death_or_explode", origin, exploded);

		if(is_true(exploded))
			level notify("grenade_exploded", origin, 256, 300, 75);
	}
}

//============================================================================================
// Utils
//============================================================================================
get_nonalternate_weapon(altWeapon)
{
	if(WeaponInventoryType(altWeapon) == "altmode")
		return WeaponAltWeaponName(altWeapon);
	return altWeapon;
}

swicth_from_alt_weapon(current_weapon)
{
	alt = get_nonalternate_weapon(current_weapon);

	if(alt != current_weapon)
	{
		self SwitchToWeapon(alt);
		self waittill_any_or_timeout(1, "weapon_change_complete");
		return alt;
	}
	return current_weapon;
}

switch_back_primary_weapon(oldPrimary)
{
	if(self maps\_laststand::player_is_in_laststand())
		return;

	if(!isdefined(oldPrimary) || oldPrimary == "none" || maps\apex\_zm_melee_weapon::is_flourish_weapon(oldPrimary) || is_melee_weapon(oldPrimary) || is_placeable_mine(oldPrimary) || is_lethal_grenade(oldPrimary) || is_tactical_grenade(oldPrimary) || !self HasWeapon(oldPrimary))
		oldPrimary = undefined;

	primaryWeapons = self GetWeaponsListPrimaries();

	if(isdefined(oldPrimary) && IsInArray(primaryWeapons, oldPrimary))
		self SwitchToWeapon(oldPrimary);
	else if(primaryWeapons.size > 0)
		self SwitchToWeapon(primaryWeapons[0]);
	else
		self maps\apex\_zm_melee_weapon::give_fallback_weapon();
}

is_weapon_included(weapon_name)
{
	if(!isdefined(level.zombie_weapons))
		return false;
	return isdefined(level.zombie_weapons[weapon_name]);
}

is_weapon_or_base_included(weapon_name)
{
	if(!isdefined(level.zombie_weapons))
		return false;
	if(is_weapon_included(weapon_name))
		return true;

	base = get_base_weapon(weapon_name);
	return is_weapon_included(base);
}

get_base_weapon(upgradedweapon)
{
	upgradedweapon = get_nonalternate_weapon(upgradedweapon);

	if(isdefined(level.zombie_weapons_upgraded[upgradedweapon]))
		return level.zombie_weapons_upgraded[upgradedweapon];
	return upgradedweapon;
}

get_upgrade_weapon(weapon)
{
	weapon = get_nonalternate_weapon(weapon);
	weapon = ToLower(weapon);
	newWeapon = weapon;

	if(!is_weapon_upgraded(weapon))
		newWeapon = level.zombie_weapons[weapon].upgrade_name;
	return newWeapon;
}

can_upgrade_weapon(weaponname)
{
	if(!isdefined(weaponname) || weaponname == "")
		return false;

	weaponname = ToLower(weaponname);
	weaponname = get_nonalternate_weapon(weaponname);

	if(!is_weapon_upgraded(weaponname))
		return isdefined(level.zombie_weapons[weaponname].upgrade_name);
	return false;
}

is_weapon_upgraded(weaponname)
{
	if(!isdefined(weaponname) || weaponname == "")
		return false;

	weaponname = ToLower(weaponname);
	weaponname = get_nonalternate_weapon(weaponname);

	if(isdefined(level.zombie_weapons_upgraded[weaponname]))
		return true;
	return false;
}

has_upgrade(weaponname)
{
	has_upgrade = false;

	if(isdefined(level.zombie_weapons[weaponname]) && isdefined(level.zombie_weapons[weaponname].upgrade_name))
		has_upgrade = self HasWeapon(level.zombie_weapons[weaponname].upgrade_name);
	if(!has_upgrade && maps\apex\_zm_melee_weapon::is_ballistic_knife(weaponname))
		has_upgrade = self maps\apex\_zm_melee_weapon::has_upgraded_ballistic_knife();
	return has_upgrade;
}

has_weapon_or_upgrade(weaponname)
{
	has_weapon = false;

	if(is_weapon_included(weaponname))
		has_weapon = self HasWeapon(weaponname) || self has_upgrade(weaponname);
	if(!has_weapon && maps\apex\_zm_melee_weapon::is_ballistic_knife(weaponname))
		has_weapon = self maps\apex\_zm_melee_weapon::has_any_ballistic_knife();
	return has_weapon;
}

can_buy_weapon()
{
	if(isdefined(self.is_drinking) && self is_drinking())
		return false;
	if(self hacker_active())
		return false;

	current_weapon = self GetCurrentWeapon();

	if(is_placeable_mine(current_weapon) || is_equipment(current_weapon))
		return false;
	if(self in_revive_trigger())
		return false;
	if(current_weapon == "none")
		return false;
	return true;
}

weapon_is_dual_wield(name)
{
	if(maps\apex\_zm_melee_weapon::is_ballistic_knife(name))
		return true;
	return WeaponDualWieldWeaponName(name) != "none";
}

get_left_hand_weapon_model_name(name)
{
	// find 2nd knife model for ballistic knives
	if(maps\apex\_zm_melee_weapon::is_ballistic_knife(name))
	{
		if(isdefined(self) && IsPlayer(self))
			return GetWeaponModel(self get_player_melee_weapon());
		else
		{
			weapon = get_base_weapon(name);

			for(i = 0; i < level._melee_weapons.size; i++)
			{
				if(level._melee_weapons[i].ballistic_name == weapon)
					return GetWeaponModel(level._melee_weapons[i].weapon);
			}
			return GetWeaponModel(level.zombie_vars["zombie_melee_weapon_default"]);
		}
	}

	return GetWeaponModel(WeaponDualWieldWeaponName(name));
}

get_pack_a_punch_weapon_options(weapon)
{
	if(!isdefined(self.pack_a_punch_weapon_options_default))
		self.pack_a_punch_weapon_options_default = self CalcWeaponOptions(0);
	if(!isdefined(self.pack_a_punch_weapon_options))
		self.pack_a_punch_weapon_options = [];
	if(isdefined(self.pack_a_punch_weapon_options[weapon]))
		return self.pack_a_punch_weapon_options[weapon];

	if(!is_weapon_upgraded(weapon))
	{
		self.pack_a_punch_weapon_options[weapon] = self.pack_a_punch_weapon_options_default;
		return self.pack_a_punch_weapon_options[weapon];
	}

	reticle_index = RandomIntRange(0, 21);
	reticle_color_index = RandomIntRange(0, 6);

	if(weapon == "famas_upgraded_zm")
		reticle_index = 21;
	else
	{
		if(RandomInt(10) < 3)
			reticle_index = 0;
	}

	if(reticle_index == 8)
		reticle_color_index = 3;
	if(reticle_index == 2)
		reticle_color_index = 6;
	if(reticle_index == 7)
		reticle_color_index = 1;
	if(reticle_index == 22)
		reticle_color_index = 6;

	self.pack_a_punch_weapon_options[weapon] = self CalcWeaponOptions(15, RandomIntRange(0, 6), reticle_index, reticle_color_index);
	return self.pack_a_punch_weapon_options[weapon];
}

get_player_weapon_with_same_base(weapon)
{
	base_weapon = get_base_weapon(weapon);

	if(self HasWeapon(base_weapon))
		return base_weapon;
	return undefined;
}

//============================================================================================
// Weapon Model
//============================================================================================
attach_weapon_model(weapon_name, rh_tag, lh_tag, player)
{
	if(!isdefined(rh_tag))
		rh_tag = "tag_weapon";
	if(!isdefined(lh_tag))
		lh_tag = "tag_weapon_left";

	self Attach(GetWeaponModel(weapon_name), rh_tag);

	if(weapon_is_dual_wield(weapon_name))
		self Attach(get_left_hand_weapon_model_name(weapon_name), lh_tag);

	self UseWeaponHideTags(weapon_name);
}

detach_weapon_model(weapon_name, rh_tag, lh_tag, player)
{
	if(!isdefined(rh_tag))
		rh_tag = "tag_weapon";
	if(!isdefined(lh_tag))
		lh_tag = "tag_weapon_left";

	self Detach(GetWeaponModel(weapon_name), rh_tag);

	if(weapon_is_dual_wield(weapon_name))
		self Detach(player get_left_hand_weapon_model_name(weapon_name), lh_tag);
}

spawn_weapon_model(weapon_name, origin, angles, player)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return undefined;
	if(!isdefined(origin))
		return undefined;
	if(!isdefined(angles))
		angles = (0, 0, 0);

	model = spawn_model("tag_origin", origin, angles);
	model model_use_weapon_options(weapon_name, player);

	return model;
}

model_use_weapon_options(weapon_name, player)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return;
	if(!isdefined(player))
		player = level;

	self SetModel(GetWeaponModel(weapon_name));
	self UseWeaponHideTags(weapon_name);
	self.weapon_name = weapon_name;

	if(isdefined(self.lh_model))
	{
		if(weapon_is_dual_wield(weapon_name))
		{
			self.lh_model SetModel(player get_left_hand_weapon_model_name(weapon_name));
			self.lh_model UseWeaponHideTags(weapon_name);
			self.lh_model Show();
		}
		else
		{
			self.lh_model Hide();
			// self.lh_model Unlink();
			// self.lh_model Delete();
			// self.lh_model = undefined;
		}
	}
	else
	{
		if(weapon_is_dual_wield(weapon_name))
		{
			self.lh_model = spawn_model(player get_left_hand_weapon_model_name(weapon_name), self.origin + (3, 3, 3), self.angles);
			self.lh_model UseWeaponHideTags(weapon_name);
			self.lh_model LinkTo(self);
		}
	}
}

model_show_weapon()
{
	if(isdefined(self.lh_model))
		self.lh_model Show();
	self Show();
}

model_hide_weapon()
{
	if(isdefined(self.lh_model))
		self.lh_model Hide();
	self Hide();
}

delete_weapon_model()
{
	if(isdefined(self.lh_model))
	{
		self.lh_model Unlink();
		self.lh_model Delete();
		self.lh_model = undefined;
	}

	self Delete();
}

//============================================================================================
// Give
//============================================================================================
weapon_give(weapon, magic_box, nosound)
{
	primaryWeapons = self GetWeaponsListPrimaries();
	initial_current_weapon = self GetCurrentWeapon();
	current_weapon = self swicth_from_alt_weapon(initial_current_weapon);
	weapon_limit = self get_player_weapon_limit();

	if(is_equipment(weapon))
		self maps\_zombiemode_equipment::equipment_give(weapon);

	if(self HasWeapon(weapon))
	{
		if(maps\apex\_zm_melee_weapon::is_ballistic_knife(weapon))
			self notify("zmb_lost_knife");

		self GiveStartAmmo(weapon);

		if(!is_offhand_weapon(weapon))
			self SwitchToWeapon(weapon);

		self notify("weapon_give", weapon);
		return weapon;
	}

	if(is_melee_weapon(weapon))
		current_weapon = self maps\apex\_zm_melee_weapon::change_melee_weapon(weapon, current_weapon);
	else if(is_lethal_grenade(weapon))
	{
		self weapon_take(self get_player_lethal_grenade());
		self set_player_lethal_grenade(weapon);
	}
	else if(is_tactical_grenade(weapon))
	{
		self weapon_take(self get_player_tactical_grenade());
		self set_player_tactical_grenade(weapon);
	}
	else if(is_placeable_mine(weapon))
	{
		self weapon_take(self get_player_placeable_mine());
		self set_player_placeable_mine(weapon);
	}

	if(!is_offhand_weapon(weapon))
		self maps\apex\_zm_melee_weapon::take_fallback_weapon();

	if(primaryWeapons.size >= weapon_limit)
	{
		if(is_placeable_mine(current_weapon) || is_equipment(current_weapon))
			current_weapon = undefined;

		if(isdefined(current_weapon))
		{
			if(!is_offhand_weapon(weapon))
				self weapon_take(current_weapon);
		}
	}

	if(isdefined(level.zombiemode_offhand_weapon_give_override))
	{
		if(run_function(self, level.zombiemode_offhand_weapon_give_override, weapon))
		{
			self notify("weapon_give", weapon);
			return weapon;
		}
	}

	if(maps\apex\_zm_melee_weapon::is_ballistic_knife(weapon))
		weapon = maps\apex\_zm_melee_weapon::give_ballistic_knife(weapon, is_weapon_upgraded(weapon));
	else if(is_placeable_mine(weapon))
	{
		self thread maps\apex\_zm_placeable_mine::give_placeable_mine(weapon, true);

		if(!is_true(nosound))
			self play_weapon_vo(weapon, magic_box);

		self notify("weapon_give", weapon);
		return weapon;
	}

	if(isdefined(level.zombie_weapons_callbacks) && isdefined(level.zombie_weapons_callbacks[weapon]))
	{
		single_thread(self, level.zombie_weapons_callbacks[weapon]);

		if(!is_true(nosound))
			self play_weapon_vo(weapon, magic_box);

		self notify("weapon_give", weapon);
		return weapon;
	}

	if(!is_true(nosound))
		self play_sound_on_ent("purchase");

	self give_weapon(weapon);
	self notify("weapon_give", weapon);
	self GiveStartAmmo(weapon);

	if(!is_offhand_weapon(weapon))
	{
		if(!is_melee_weapon(weapon))
			self SwitchToWeapon(weapon);
		else
			self SwitchToWeapon(current_weapon);
	}

	if(!is_true(nosound))
		self play_weapon_vo(weapon, magic_box);
	return weapon;
}

weapon_take(weapon)
{
	if(!isdefined(weapon) || weapon == "none")
		return;

	self notify("weapon_take", weapon);

	if(maps\apex\_zm_melee_weapon::is_ballistic_knife(weapon))
		self notify("zmb_lost_knife");
	else if(is_lethal_grenade("none"))
		self set_player_lethal_grenade("none");
	else if(is_tactical_grenade(weapon))
		self set_player_tactical_grenade("none");
	else if(is_placeable_mine(weapon))
		self set_player_placeable_mine("none");

	if(self HasWeapon(weapon))
		self TakeWeapon(weapon);
}

take_all_weapons(weapons)
{
	if(!isdefined(weapons))
		weapons = self GetWeaponsList();

	for(i = 0 ; i < weapons.size; i++)
	{
		self weapon_take(weapons[i]);
	}
}

ammo_give(weapon)
{
	give_ammo = false;

	if(is_offhand_weapon(weapon))
	{
		if(self has_weapon_or_upgrade(weapon))
		{
			if(self GetAmmoCount(weapon) < WeaponMaxAmmo(weapon))
				give_ammo = true;
		}
	}
	else
	{
		stock_max = WeaponStartAmmo(weapon);
		clip_count = self GetWeaponAmmoClip(weapon);
		current_stock = self GetAmmoCount(weapon);

		if(current_stock - clip_count >= stock_max)
			give_ammo = false;
		else
			give_ammo =true;
	}

	if(give_ammo)
	{
		self play_sound_on_ent("purchase");
		self GiveMaxAmmo(weapon);

		alt_weap = WeaponAltWeaponName(weapon);

		if(alt_weap != "none")
			self GiveMaxAmmo(alt_weap);
	}
	return give_ammo;
}

give_weapon(weapon, model_index)
{
	if(!isdefined(model_index))
		model_index = 0;

	weapon_options = self get_pack_a_punch_weapon_options(weapon);
	self GiveWeapon(weapon, model_index, weapon_options);
}

register_zombie_weapon_callback(weapon_name, func)
{
	if(!isdefined(level.zombie_weapons_callbacks))
		level.zombie_weapons_callbacks = [];
	if(!isdefined(level.zombie_weapons_callbacks[weapon_name]))
		level.zombie_weapons_callbacks[weapon_name] = func;
}

//============================================================================================
// Weapon VOX
//============================================================================================
play_weapon_vo(weapon, magic_box)
{
	if(isdefined(level._audio_custom_weapon_check))
		type = run_function(self, level._audio_custom_weapon_check, weapon);
	else
		type = self weapon_type_check(weapon);

	self thread maps\_zombiemode_audio::create_and_play_dialog("weapon_pickup", type);
}

weapon_type_check(weapon)
{
	switch(self get_player_index())
	{
		case 0:
			if(weapon == "m16_zm")
				return "favorite";
			else if(weapon == "rottweil72_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 1:
			if(weapon == "fnfal_zm")
				return "favorite";
			else if(weapon == "hk21_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 2:
			if(weapon == "china_lake_zm")
				return "favorite";
			else if(weapon == "thundergun_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 3:
			if(weapon == "mp40_zm")
				return "favorite";
			else if(weapon == "crossbow_explosive_upgraded_zm")
				return "favorite_upgrade";
			break;
	}

	if(is_weapon_upgraded(weapon))
		return "upgrade";
	else
		return level.zombie_weapons[weapon].vox;
}

get_player_index()
{
	return self.entity_num;
}

//============================================================================================
// Wallbuys
//============================================================================================
init_weapon_upgrade()
{
	PrecacheModel("grenade_bag");
	set_zombie_var("zombie_weapons_upgrade_ammo_cost", 4500);

	spawn_list = GetStructArray("weapon_upgrade", "targetname");
	spawn_list = array_combine(spawn_list, GetStructArray("bowie_upgrade", "targetname"));
	spawn_list = array_combine(spawn_list, GetStructArray("sickle_upgrade", "targetname"));
	spawn_list = array_combine(spawn_list, GetStructArray("tazer_upgrade", "targetname"));
	spawn_list = array_combine(spawn_list, GetStructArray("claymore_purchase", "targetname"));
	spawn_list = array_combine(spawn_list, convert_legacy_wall_buys());

	if(!isdefined(spawn_list) || spawn_list.size == 0)
		return;

	for(i = 0; i < spawn_list.size; i++)
	{
		stub = spawn_list[i];
		weapon = stub.zombie_weapon_upgrade;

		if(!is_weapon_included(weapon))
			continue;

		if(isdefined(stub.model_override))
		{
			stub.model = stub.model_override;

			if(is_placeable_mine(weapon))
			{
				// legacy placeable mine models are weirdly offset
				stub.model.show_angles = stub.model.angles;
				stub.model.angles += (90, 0, 0);
				stub.model.origin += (0, 0, 4.5);
			}
		}
		else
			stub.model = spawn_model("tag_origin", stub.origin, stub.angles);

		if(is_lethal_grenade(weapon))
			stub.model SetModel("grenade_bag");
		else
		{
			stub.model SetModel(GetWeaponModel(weapon));
			stub.model UseWeaponHideTags(weapon);
		}

		stub.model Hide();

		stub.script_unitrigger_type = "playertrigger_radius_use";
		stub.radius = 20;
		stub.height = 20;
		stub.origin -= AnglesToRight(stub.angles) * 10;
		stub.weapon = weapon;
		stub.require_look_at = true;
		stub.first_time_triggered = false;
		stub.clientFieldName = stub.zombie_weapon_upgrade + "_" + stub.origin;
		stub.prompt_and_visibility_func = ::wall_weapon_update_prompt;
		register_playertrigger(stub, ::weapon_spawn_think);
	}
	level._spawned_wallbuys = spawn_list;
}

convert_legacy_wall_buys()
{
	converted = [];

	// Bowie
	triggers = GetEntArray("bowie_upgrade", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		trigger = triggers[i];
		model = GetEnt(trigger.target, "targetname");

		struct = SpawnStruct();
		struct.origin = trigger.origin;
		struct.angles = model.angles;
		struct.zombie_weapon_upgrade = "bowie_knife_zm";
		struct.model_override = model;

		converted[converted.size] = struct;

		// model Delete();
		trigger Delete();
	}

	// Sickle
	triggers = GetEntArray("sickle_upgrade", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		trigger = triggers[i];
		model = GetEnt(trigger.target, "targetname");

		struct = SpawnStruct();
		struct.origin = trigger.origin;
		struct.angles = model.angles;
		struct.zombie_weapon_upgrade = "sickle_knife_zm";
		struct.model_override = model;

		converted[converted.size] = struct;

		// model Delete();
		trigger Delete();
	}

	// Claymore
	triggers = GetEntArray("claymore_purchase", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		trigger = triggers[i];
		model = GetEnt(trigger.target, "targetname");

		struct = SpawnStruct();
		struct.origin = trigger.origin;
		struct.angles = model.angles - (0, 90, 0);
		struct.zombie_weapon_upgrade = "claymore_zm";
		struct.model_override = model;

		converted[converted.size] = struct;

		// model Delete();
		trigger Delete();
	}

	// Spikemore
	triggers = GetEntArray("spikemore_purchase", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		trigger = triggers[i];
		model = GetEnt(trigger.target, "targetname");

		struct = SpawnStruct();
		struct.origin = trigger.origin;
		struct.angles = model.angles - (0, 90, 0);
		struct.zombie_weapon_upgrade = "spikemore_zm";
		struct.model_override = model;

		converted[converted.size] = struct;

		// model Delete();
		trigger Delete();
	}

	// Wallbuys
	triggers = GetEntArray("weapon_upgrade", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		trigger = triggers[i];
		model = GetEnt(trigger.target, "targetname");

		struct = SpawnStruct();
		struct.origin = trigger.origin;
		struct.angles = model.angles;
		struct.zombie_weapon_upgrade = trigger.zombie_weapon_upgrade;
		struct.model_override = model;

		if(WeaponType(trigger.zombie_weapon_upgrade) == "grenade")
			struct.angles -= (0, 180, 0);

		converted[converted.size] = struct;

		// model Delete();
		trigger Delete();
	}

	return converted;
}

wall_weapon_update_prompt(player)
{
	self.hint_string = undefined;
	self.hint_param1 = undefined;
	self.hint_param2 = undefined;
	self.hint_param3 = undefined;
	self.hint_param4 = undefined;

	weapon = self.stub.weapon;

	if(!player can_buy_weapon())
		return false;
	if(is_placeable_mine(weapon) && player placeable_mine_can_buy_weapon_extra_check(weapon))
		return false;
	if(is_melee_weapon(weapon) && player melee_weapon_can_buy_weapon_extra_check(weapon))
		return false;

	if(is_offhand_weapon(weapon))
	{
		self.hint_string = &"ZOMBIE_DYN_WEAPONCOST";
		self.hint_param1 = level.zombie_weapons[weapon].display_name;
		self.hint_param2 = level.zombie_weapons[weapon].cost;
	}
	else
	{
		if(isdefined(level.func_override_wallbuy_prompt))
		{
			if(!run_function(self, level.func_override_wallbuy_prompt, player))
				return false;
		}

		cost = level.zombie_weapons[weapon].cost;
		self.hint_string = &"ZOMBIE_DYN_WEAPONCOST";
		self.hint_param1 = level.zombie_weapons[weapon].display_name;
		self.hint_param2 = cost;

		if(player has_weapon_or_upgrade(weapon))
		{
			self.hint_param3 = Int(cost / 2);

			if(can_upgrade_weapon(weapon))
			{
				self.hint_string = &"ZOMBIE_DYN_WEAPONCOSTAMMO_UPGRADE";
				self.hint_param4 = level.zombie_vars["zombie_weapons_upgrade_ammo_cost"];
			}
			else
				self.hint_string = &"ZOMBIE_DYN_WEAPONCOSTAMMO";
		}
	}
	return true;
}

placeable_mine_can_buy_weapon_extra_check(weapon)
{
	mine = self get_player_placeable_mine();

	if(isdefined(weapon) && is_equal(mine, weapon))
		return true;
	return false;
}

melee_weapon_can_buy_weapon_extra_check(weapon)
{
	melee_weapon = self get_player_melee_weapon();

	if(isdefined(weapon) && is_equal(melee_weapon, weapon))
		return true;
	return false;
}

weapon_spawn_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill("trigger", player);
		weapon = self.stub.weapon;
		cost = player get_wallbuy_cost(weapon, self.stub.hacked);

		if(isdefined(player.check_override_wallbuy_purchase))
		{
			if(run_function(player, player.check_override_wallbuy_purchase, weapon, self))
				continue;
		}

		if(player.score < cost)
		{
			self play_sound_on_ent("no_purchase");
			player maps\_zombiemode_audio::create_and_play_dialog("general", "no_money", undefined, 1);
			continue;
		}

		if(player has_weapon_or_upgrade(weapon))
		{
			if(player has_upgrade(weapon))
				success = player ammo_give(get_upgrade_weapon(weapon));
			else
				success = player ammo_give(weapon);
		}
		else
		{
			success = true;

			if(is_melee_weapon(weapon))
				player thread maps\apex\_zm_melee_weapon::give_melee_weapon(weapon);
			else
				player thread weapon_give(weapon, false, false);
		}

		if(success)
		{
			if(!is_true(self.stub.first_time_triggered))
				self.stub thread show_all_weapon_buys();

			player maps\_zombiemode_score::minus_to_player_score(cost);
		}
	}
}

get_wallbuy_cost(weapon, hacked)
{
	if(self has_weapon_or_upgrade(weapon))
	{
		if(is_true(hacked))
		{
			if(self has_upgrade(weapon))
				return Int(level.zombie_weapons[weapon].cost / 2);
			else
				return level.zombie_vars["zombie_weapons_upgrade_ammo_cost"];
		}
		else
		{
			if(self has_upgrade(weapon))
				return level.zombie_vars["zombie_weapons_upgrade_ammo_cost"];
			else
				return Int(level.zombie_weapons[weapon].cost / 2);
		}
	}
	else
		return level.zombie_weapons[weapon].cost;
}

show_all_weapon_buys()
{
	self show_weapon_buy();

	if(!is_true(level.dont_link_common_wallbuys) && isdefined(level._spawned_wallbuys))
	{
		for(i = 0; i < level._spawned_wallbuys.size; i++)
		{
			wallbuy = level._spawned_wallbuys[i];

			if(is_true(wallbuy.first_time_triggered))
				continue;
			if(is_equal(wallbuy, self))
				continue;
			if(is_equal(wallbuy.weapon, self.weapon))
				wallbuy show_weapon_buy();
		}
	}
}

show_weapon_buy()
{
	if(is_true(self.first_time_triggered))
		return;

	self.first_time_triggered = true;

	// if(isdefined(self.clientFieldName))
	// 	set_client_system_state(self.clientFieldName, "1");

	model = self.model;
	model_origin = model.origin;
	model_angles = model.angles;

	angles = VectortoAngles(self.origin - model_origin);
	yaw_diff = AngleClamp180(angles[1] - model_angles[1]);

	if(yaw_diff > 0)
		yaw = model_angles[1] - 90;
	else
		yaw = model_angles[1] + 90;

	if(is_placeable_mine(self.weapon))
		self.model.origin = model_origin - (AnglesToRight((0, yaw, 0)) * 8);
	else
		self.model.origin = model_origin + (AnglesToForward((0, yaw, 0)) * 8);

	wait .05;
	self.model Show();
	play_sound_at_pos("weapon_show", model_origin, self.model);
	self.model MoveTo(model_origin, 1);
}

//============================================================================================
// Weapon Loadout
//============================================================================================
create_loadout(weapons)
{
	loadout = SpawnStruct();
	loadout.weapons = [];

	for(i = 0; i < weapons.size; i++)
	{
		if(maps\apex\_zm_powerups::is_powerup_weapon(weapons[i]))
			continue;

		loadout.weapons[loadout.weapons.size] = get_default_weapondata(weapons[i]);

		if(!isdefined(loadout.current) || loadout.current == "none")
			loadout.current = weapons[i];
	}
	return loadout;
}

player_get_loadout()
{
	loadout = SpawnStruct();
	loadout.current = self GetCurrentWeapon();
	loadout.weapons = [];
	weapons = self GetWeaponsList();

	for(i = 0; i < weapons.size; i++)
	{
		if(maps\apex\_zm_powerups::is_powerup_weapon(weapons[i]))
			continue;
		loadout.weapons[loadout.weapons.size] = self get_player_weapondata(weapons[i]);
	}
	return loadout;
}

player_give_loadout(loadout, replace_existing)
{
	if(is_true(replace_existing))
		self take_all_weapons();

	for(i = 0; i < loadout.weapons.size; i++)
	{
		self weapondata_give(loadout.weapons[i]);
	}

	self switch_back_primary_weapon(loadout.current);
}

player_take_loadout(loadout)
{
	for(i = 0; i < loadout.weapons.size; i++)
	{
		self weapondata_take(loadout.weapons[i]);
	}
}

is_weapon_available_in_loadout(weapon, loadout)
{
	count = 0;
	upgrade_name = get_upgrade_weapon(weapon);

	if(isdefined(loadout) && isdefined(loadout.weapons))
	{
		for(i = 0; i < loadout.weapons.size; i++)
		{
			loadout_weapon = loadout.weapons[i]["name"];

			if(weapon == loadout_weapon || upgrade_name == loadout_weapon)
				count++;
		}
	}
	return count;
}

//============================================================================================
// Weapon Data
//============================================================================================
get_default_weapondata(weapon_name)
{
	weapondata = [];
	weapondata["name"] = weapon_name;
	weapondata["dw_name"] = WeaponDualWieldWeaponName(weapondata["name"]);
	weapondata["alt_name"] = WeaponAltWeaponName(weapondata["name"]);
	weapondata["clip"] = WeaponClipSize(weapondata["name"]);
	weapondata["stock"] = WeaponMaxAmmo(weapondata["name"]);

	if(weapondata["dw_name"] == "none")
		weapondata["lh_clip"] = 0;
	else
		weapondata["lh_clip"] = WeaponClipSize(weapondata["dw_name"]);

	if(weapondata["alt_name"] == "none")
	{
		weapondata["alt_clip"] = 0;
		weapondata["alt_stock"] = 0;
	}
	else
	{
		weapondata["alt_clip"] = WeaponClipSize(weapondata["alt_name"]);
		weapondata["alt_stock"] = WeaponMaxAmmo(weapondata["alt_name"]);
	}
	return weapondata;
}

get_player_weapondata(weapon)
{
	weapondata = [];

	if(isdefined(weapon))
		weapondata["name"] = weapon;
	else
		weapondata["name"] = self GetCurrentWeapon();

	weapondata["dw_name"] = WeaponDualWieldWeaponName(weapondata["name"]);
	weapondata["alt_name"] = WeaponAltWeaponName(weapondata["name"]);

	if(weapondata["name"] == "none")
	{
		weapondata["clip"] = 0;
		weapondata["stock"] = 0;
	}
	else
	{
		weapondata["clip"] = self GetWeaponAmmoClip(weapondata["name"]);
		weapondata["stock"] = self GetWeaponAmmoStock(weapondata["name"]);
	}

	if(weapondata["dw_name"] == "none")
		weapondata["lh_clip"] = 0;
	else
		weapondata["lh_clip"] = self GetWeaponAmmoClip(weapondata["dw_name"]);

	if(weapondata["alt_name"] == "none")
	{
		weapondata["alt_clip"] = 0;
		weapondata["alt_stock"] = 0;
	}
	else
	{
		weapondata["alt_clip"] = self GetWeaponAmmoClip(weapondata["alt_name"]);
		weapondata["alt_stock"] = self GetWeaponAmmoStock(weapondata["alt_name"]);
	}
	return weapondata;
}

weapon_is_better(left, right)
{
	if(left != right)
	{
		left_upgraded = is_weapon_upgraded(left);
		right_upgraded = is_weapon_upgraded(right);

		if(left_upgraded && right)
			return cointoss();
		else if(left_upgraded)
			return true;
	}
	return false;
}

merge_weapons(oldweapondata, newweapondata)
{
	weapondata = [];

	if(weapon_is_better(oldweapondata["name"], newweapondata["name"]))
		weapondata["name"] = oldweapondata["name"];
	else
		weapondata["name"] = newweapondata["name"];

	weapondata["dw_name"] = WeaponDualWieldWeaponName(weapondata["name"]);
	weapondata["alt_name"] = WeaponAltWeaponName(weapondata["name"]);

	if(weapondata["name"] == "none")
	{
		weapondata["clip"] = 0;
		weapondata["stock"] = 0;
	}
	else
	{
		weapondata["clip"] = newweapondata["clip"] + oldweapondata["clip"];
		weapondata["clip"] = Int(Min(weapondata["clip"], WeaponClipSize(weapondata["name"])));
		weapondata["stock"] = newweapondata["stock"] + oldweapondata["stock"];
		weapondata["stock"] = Int(Min(weapondata["stock"], WeaponMaxAmmo(weapondata["name"])));
	}

	if(weapondata["dw_name"] == "none")
		weapondata["lh_clip"] = 0;
	else
	{
		weapondata["lh_clip"] = newweapondata["lh_clip"] + oldweapondata["lh_clip"];
		weapondata["lh_clip"] = Int(Min(weapondata["lh_clip"], WeaponClipSize(weapondata["dw_name"])));
	}

	if(weapondata["alt_name"] == "none")
	{
		weapondata["alt_clip"] = 0;
		weapondata["alt_stock"] = 0;
	}
	else
	{
		weapondata["alt_clip"] = newweapondata["alt_clip"] + oldweapondata["alt_clip"];
		weapondata["alt_clip"] = Int(Min(weapondata["alt_clip"], WeaponClipSize(weapondata["alt_name"])));
		weapondata["alt_stock"] = newweapondata["alt_stock"] + oldweapondata["alt_stock"];
		weapondata["alt_stock"] = Int(Min(weapondata["alt_stock"], WeaponMaxAmmo(weapondata["alt_name"])));
	}
	return weapondata;
}

weapondata_give(weapondata)
{
	current = self get_player_weapon_with_same_base(weapondata["name"]);

	if(isdefined(current))
	{
		curweapondata = self get_player_weapondata(current);
		self weapon_take(current);
		weapondata = merge_weapons(curweapondata, weapondata);
	}

	self weapon_give(weapondata["name"], false, true);

	self SetWeaponAmmoStock(weapondata["name"], weapondata["stock"]);
	self SetWeaponAmmoClip(weapondata["name"], weapondata["clip"]);

	if(weapondata["dw_name"] != "none")
		self SetWeaponAmmoClip(weapondata["dw_name"], weapondata["lh_clip"]);

	if(weapondata["alt_name"] != "none")
	{
		self SetWeaponAmmoStock(weapondata["alt_name"], weapondata["alt_stock"]);
		self SetWeaponAmmoClip(weapondata["alt_name"], weapondata["alt_clip"]);
	}
}

weapondata_take(weapondata)
{
	self weapon_take(weapondata["name"]);
	self weapon_take(weapondata["dw_name"]);
	self weapon_take(weapondata["alt_name"]);
}

//============================================================================================
// Weapon Loading
//============================================================================================
load_weapons_for_level(weapons_list_table, stats_table)
{
	mapname = get_mapname();

	if(!isdefined(weapons_list_table))
		weapons_list_table = "gamedata/weapons/" + mapname + ".csv";
	if(!isdefined(stats_table))
		stats_table = "gamedata/weapons/stats.csv";

	/# PrintLn("Loading weapons for level '" + mapname + "' (" + weapons_list_table + ")"); #/
	weapons_list = load_weapons_list_for_level(weapons_list_table);

	for(i = 0; i < weapons_list.size; i++)
	{
		load_weapon_for_level(weapons_list[i]);
	}
}

load_weapon_for_level(weapon_name, stats_table)
{
	Assert(isdefined(weapon_name));
	Assert(!isdefined(level.zombie_weapons[weapon_name]));

	if(!isdefined(stats_table))
		stats_table = "gamedata/weapons/stats.csv";

	/# PrintLn("Loading weapon '" + weapon_name + "' (" + stats_table + ")"); #/

	// 0           1            2            3    4      5     6   7                8
	// weapon_name,upgrade_name,display_name,cost,in_box,limit,vox,is_wonder_weapon,offhand_type

	test = TableLookup(stats_table, 0, weapon_name, 0);

	if(!isdefined(test) || test != weapon_name)
	{
		/# PrintLn("Failed to load weapon '" + weapon_name + "', no stats defined for weapon in stats table (" + stats_table + ")"); #/
		return;
	}

	upgrade_name = TableLookup(stats_table, 0, weapon_name, 1);
	display_name = TableLookupIString(stats_table, 0, weapon_name, 2);
	cost = Int(TableLookup(stats_table, 0, weapon_name, 3));
	in_box = string_to_bool(TableLookup(stats_table, 0, weapon_name, 4));
	limit = Int(TableLookup(stats_table, 0, weapon_name, 5));
	vox = TableLookup(stats_table, 0, weapon_name, 6);
	is_wonder_weapon = string_to_bool(TableLookup(stats_table, 0, weapon_name, 7));
	offhand_type = TableLookup(stats_table, 0, weapon_name, 8);
	alt_weapon = WeaponAltWeaponName(weapon_name);
	lh_weapon = WeaponDualWieldWeaponName(weapon_name);

	struct = SpawnStruct();
	struct.upgrade_name = upgrade_name;
	struct.display_name = display_name;
	struct.cost = cost;
	struct.vox = vox;
	struct.is_wonder_weapon = is_wonder_weapon;
	struct.is_ballistic_knife = false;

	if(isdefined(limit) && limit >= 0)
		struct.limit = limit;

	PrecacheItem(weapon_name);
	PrecacheString(display_name);

	level.zombie_weapons[weapon_name] = struct;

	switch(offhand_type)
	{
		case "lethal":
			register_lethal_grenade_for_level(weapon_name);
			break;

		case "tactical":
			register_tactical_grenade_for_level(weapon_name);
			break;

		case "mine":
			maps\apex\_zm_placeable_mine::load_mine_for_level(weapon_name);
			break;

		case "melee":
			maps\apex\_zm_melee_weapon::load_melee_weapon(weapon_name);
			break;

		case "equipment":
			register_equipment_for_level(weapon_name);
			break;

		case "none":
		default:
			break;
	}

	if(is_true(in_box))
	{
		maps\apex\_zm_magicbox::add_weapon_to_magicbox(weapon_name);

		if(isdefined(limit) && limit > 0)
			maps\apex\_zm_magicbox::add_limited_weapon(weapon_name, limit);
	}

	if(isdefined(upgrade_name) && upgrade_name != "" && upgrade_name != "none")
	{
		PrecacheItem(upgrade_name);
		level.zombie_weapons_upgraded[upgrade_name] = weapon_name;
	}

	if(isdefined(alt_weapon) && alt_weapon != "" && alt_weapon != "none")
		PrecacheItem(alt_weapon);

	if(isdefined(lh_weapon) && lh_weapon != "" && lh_weapon != "none")
	{
		PrecacheItem(lh_weapon);
		PrecacheModel(GetWeaponModel(lh_weapon));
	}

	if(isdefined(level._zm_weapon_include_callbacks) && isdefined(level._zm_weapon_include_callbacks[weapon_name]))
		single_thread(level, level._zm_weapon_include_callbacks[weapon_name]);
}

// Stupid hack function to load a list of strings from stringtables
load_weapons_list_for_level(weapons_list_table)
{
	mapname = get_mapname();

	if(!isdefined(weapons_list_table))
		weapons_list_table = "gamedata/weapons/" + mapname + ".csv";

	/# PrintLn("Loading weapons list for level '" + mapname + "' (" + weapons_list_table + ")"); #/

	// Would use StrTok and store list in csv file per mapname
	// but it seems either StrTok or TableLookup has a hard string length limit
	// was not loading knife_ballistic_bowie_zm and others after it (in zombie_theater)
	// as string was too long
	//
	// changeed to put weapons per line and lookup a index rather than mapname
	// that way we dont hit the string length issue mentioed above
	// annoying little issue but thats what you get for modding a older game
	// return StrTok(TableLookup(weapons_list_table, 0, mapname, 1), "|");

	// 0     1
	// index,weapon_name

	weapons_list = [];
	i = 0;
	str = TableLookup(weapons_list_table, 0, i, 1);

	while(isdefined(str) && str != "" && str != "none")
	{
		weapons_list[weapons_list.size] = str;
		i++;
		str = TableLookup(weapons_list_table, 0, i, 1);
	}

	/# PrintLn("Loaded weapons list for level '" + mapname + "', Found " + weapons_list.size + " weapons"); #/

	return weapons_list;
}

register_weapon_data_client_side()
{
	flag_wait("all_players_connected");
	weapons_list = GetArrayKeys(level.zombie_weapons);

	for(i = 0; i < weapons_list.size; i++)
	{
		weapon_name = weapons_list[i];
		inventory_type = WeaponInventoryType(weapon_name);
		upgrade_name = get_upgrade_weapon(weapon_name);
		alt_weapon = WeaponAltWeaponName(weapon_name);
		lh_weapon = WeaponDualWieldWeaponName(weapon_name);
		in_box = maps\apex\_zm_magicbox::is_weapon_in_box(weapon_name);

		set_client_system_state("_zm_weapons", weapon_name + ",register," + inventory_type + "," + upgrade_name + "," + alt_weapon + "," + lh_weapon + "," + bool_to_string(in_box), level);
	}
}

add_weapon_include_callback(weapon_name, callback_func)
{
	if(!isdefined(level._zm_weapon_include_callbacks))
		level._zm_weapon_include_callbacks = [];
	if(!isdefined(level._zm_weapon_include_callbacks[weapon_name]))
		level._zm_weapon_include_callbacks[weapon_name] = callback_func;
}