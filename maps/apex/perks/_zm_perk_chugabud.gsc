#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("chugabud", "minimap_icon_chugabud");
	maps\apex\_zm_perks::register_perk_bottle("chugabud", undefined, undefined, 30);
	maps\apex\_zm_perks::register_perk_machine("chugabud", false, &"ZOMBIE_PERK_CHUGABUD", 2000, "p6_zm_vending_chugabud", "p6_zm_vending_chugabud_on", "perk_light_green");
	maps\apex\_zm_perks::register_perk_threads("chugabud", ::give_chugabud, ::take_chugabud);
	maps\apex\_zm_perks::register_perk_sounds("chugabud", "mus_perks_whoswho_sting", "mus_perks_whoswho_jingle", undefined);

	level._effect["chugabud_revive_fx"] = LoadFX("apex/weapon/quantum_bomb/fx_player_position_effect");
	level._effect["chugabud_bleedout_fx"] = LoadFX("apex/weapon/quantum_bomb/fx_player_position_effect");

	PrecacheShader("waypoint_revive");

	level.chugabud_laststand = ::chugabud_laststand;
	level.zombiemode_using_chugabud_perk = true;
	maps\apex\_zm_magicbox::add_custom_limited_weapon_check(::is_weapon_available_in_chugabud_corpse);
}

give_chugabud()
{
	self.lives = 1;
	self notify("perk_chugabud_activated");
}

take_chugabud(reason)
{
}

chugabud_laststand()
{
	self endon("disconnect");
	self endon("chugabud_bleedout");
	self increment_downed_stat();

	// if(self has_powerup_weapon() && isdefined(self._current_powerup_weapon))
	// 	maps\apex\_zm_powerups\_zm_powerup_weapon::remove_powerup_weapon(self._current_powerup_weapon);

	self.ignore_insta_kill = true;
	self.health = self.maxhealth;
	loadout_chugabud = self chugabud_save_loadout();
	self chugabud_fake_death();
	wait 3;

	create_corpse = true;

	if(isdefined(level._chugabug_reject_corpse_override_func))
	{
		reject_corpse = run_function(self, level._chugabud_reject_node_override_func, self.origin);

		if(is_true(reject_corpse))
			create_corpse = false;
	}

	corpse = undefined;

	if(create_corpse)
	{
		self thread activate_chugabud_effects_and_audio();
		corpse = self chugabud_spawn_corpse();
		corpse.loadout_chugabud = loadout_chugabud;
		corpse thread chugabud_corpse_revive_icon();
		self.e_chugabud_corpse = corpse;
		corpse thread chugabud_corpse_cleanup_on_spectator(self);
	}

	self chugabud_fake_revive();
	wait .1;
	self.ignore_insta_kill = undefined;

	if(!create_corpse)
	{
		self notify("chugabud_effects_cleanup");
		return;
	}

	bleedout_time = GetDvarFloat(#"player_lastStandBleedoutTime");
	self thread chugabud_bleed_timeout(bleedout_time, corpse);
	self thread chugabud_handle_multiple_instances(corpse);
	corpse waittill("player_revived", e_reviver);
	self perk_abort_drinking(.1);
	self set_player_max_health(true, false);
	self SetOrigin(corpse.origin);
	self SetPlayerAngles(corpse.angles);

	if(self maps\_laststand::player_is_in_laststand())
	{
		self thread chugabud_laststand_cleanup(corpse, "player_revived");
		self EnableWeaponCycling();
		self EnableOffhandWeapons();
		self maps\_laststand::auto_revive(self, true);
		return;
	}

	self chugabud_laststand_cleanup(corpse, undefined);
}

chugabud_laststand_cleanup(corpse, str_notify)
{
	if(isdefined(str_notify))
		self waittill(str_notify);

	self chugabud_give_loadout(corpse);
	self chugabud_corpse_cleanup(corpse, true);
}

chugabud_bleed_timeout(delay, corpse)
{
	self endon("disconnect");
	corpse endon("death");

	wait delay;

	while(is_true(corpse.reviveTrigger.beingRevived))
	{
		wait .05;
	}

	if(IsInArray(corpse.loadout_chugabud.perks, "revive") && flag("solo_game"))
	{
		corpse.loadout_chugabud.perks = array_remove_nokeys(corpse.loadout_chugabud.perks, "revive");
		corpse notify("player_revived", self);
		return;
	}

	self chugabud_corpse_cleanup(corpse, false);
}

chugabud_corpse_cleanup(corpse, was_revived)
{
	self notify("chugabud_effects_cleanup");

	if(is_true(was_revived))
	{
		PlaySoundAtPosition("evt_ww_appear", corpse.origin);
		PlayFX(level._effect["chugabud_revive_fx"], corpse.origin);
	}
	else
	{
		PlaySoundAtPosition("evt_ww_disapper", corpse.origin);
		PlayFX(level._effect["chugabud_bleedout_fx"], corpse.origin);
		self notify("chugabud_bleedout");
	}

	if(isdefined(corpse.reviveTrigger))
	{
		corpse notify("disconnect");
		corpse.reviveTrigger Delete();
		corpse.reviveTrigger = undefined;
	}

	if(isdefined(corpse.revive_hud_elem))
	{
		corpse.revive_hud_elem Destroy();
		corpse.revive_hud_elem = undefined;
	}

	corpse.loadout_chugabud = undefined;
	wait .1;
	corpse Delete();
	self.e_chugabud_corpse = undefined;
}

chugabud_handle_multiple_instances(corpse)
{
	corpse endon("death");
	self waittill("perk_chugabud_activated");
	self chugabud_corpse_cleanup(corpse, false);
}

chugabud_spawn_corpse()
{
	trace_start = self.origin;
	trace_end = self.origin - (0, 0, 500);
	corpse_trace = PlayerPhysicsTrace(trace_start, trace_end);
	corpse = maps\apex\_zm_clone::spawn_player_clone(self, corpse_trace, undefined, self.whos_who_shader);
	corpse.angles = self.angles;
	corpse maps\apex\_zm_clone::clone_give_weapon("m1911_zm", self);
	corpse maps\apex\_zm_clone::clone_animate("laststand");
	corpse.revive_hud = self.revive_hud;
	corpse thread maps\_laststand::revive_trigger_spawn();
	return corpse;
}

chugabud_save_loadout()
{
	loadout_chugabud = SpawnStruct();
	loadout_chugabud.player = self;
	loadout_chugabud.loadout = self maps\apex\_zm_weapons::player_get_loadout();
	loadout_chugabud.perks = self get_player_obtained_perks();
	loadout_chugabud.score = self.score;
	return loadout_chugabud;
}

chugabud_give_loadout(corpse)
{
	loadout = corpse.loadout_chugabud;
	self maps\apex\_zm_weapons::player_give_loadout(loadout.loadout, true);

	for(i = 0; i < loadout.perks.size; i++)
	{
		if(self has_perk(loadout.perks[i]))
			continue;
		if(loadout.perks[i] == "revive" && is_solo_game())
			level.solo_game_free_player_quickrevive = true;
		if(loadout.perks[i] == "chugabud")
			continue;

		self maps\apex\_zm_perks::give_perk(loadout.perks[i], false);
	}

	if(self.score < loadout.score)
		self maps\_zombiemode_score::add_to_player_score(loadout.score - self.score);
	else if(self.score > loadout.score)
		self maps\_zombiemode_score::minus_to_player_score(self.score - loadout.score);
}

chugabud_fake_death()
{
	self notify("fake_death");
	self TakeAllWeapons();
	self disable_player_move_states(false);
	self.ignoreme = true;
	self EnableInvulnerability();
	wait .1;
	self FreezeControls(true);
	wait .9;
}

chugabud_fake_revive()
{
	PlaySoundAtPosition("evt_ww_disapper", self.origin);
	PlayFX(level._effect["chugabud_revive_fx"], self.origin);

	spawnpoint = chugabud_get_spawnpoint();

	if(isdefined(level._chugabud_post_respawn_override_func))
		run_function(self, level._chugabud_post_respawn_override_func, spawnpoint.origin);

	if(isdefined(level.chugabud_force_corpse_position))
	{
		if(isdefined(self.e_chugabud_corpse))
			self.e_chugabud_corpse.origin = level.chugabud_force_corpse_position;

		level.chugabud_force_corpse_position = undefined;
	}

	if(isdefined(level.chugabud_force_player_position))
	{
		spawnpoint.origin = level.chugabud_force_player_position;
		level.chugabud_force_player_position = undefined;
	}

	self SetOrigin(spawnpoint.origin);
	self SetPlayerAngles(spawnpoint.angles);
	PlaySoundAtPosition("evt_ww_appear", spawnpoint.origin);
	PlayFX(level._effect["chugabud_revive_fx"], spawnpoint.origin);
	self enable_player_move_states();
	self.ignoreme = false;
	self SetStance("stand");
	self FreezeControls(false);

	if(isdefined(level._chugabud_give_custom_loadout))
		run_function(self, level._chugabud_give_custom_loadout);
	else
	{
		knife = self get_player_melee_weapon();
		grenade = self get_player_lethal_grenade();
		mine = self get_player_placeable_mine();

		if(!isdefined(grenade) || grenade == "none")
			grenade = level.zombie_lethal_grenade_player_init;
		if(!isdefined(knife) || knife == "none")
			knife = level.zombie_melee_weapon_player_init;

		self maps\apex\_zm_weapons::give_weapon("m1911_zm");
		self SwitchToWeapon("m1911_zm");
		self GiveStartAmmo("m1911_zm");
		self maps\apex\_zm_melee_weapon::change_melee_weapon(knife, "m1911_zm");
		self maps\apex\_zm_weapons::give_weapon(grenade);
		self SetWeaponAmmoClip(grenade, 2);

		if(isdefined(mine) && mine != "none")
		{
			self maps\apex\_zm_weapons::give_weapon(mine);
			self maps\apex\_zm_placeable_mine::give_placeable_mine(mine, true);
		}
	}

	wait 1;
	self DisableInvulnerability();
}

chugabud_get_spawnpoint()
{
	spawnpoint = undefined;

	if(get_chugabud_spawn_point_from_nodes(self.origin, 500, 700, 64, true))
		spawnpoint = level.chugabud_spawn_struct;

	if(!isdefined(spawnpoint))
	{
		if(get_chugabud_spawn_point_from_nodes(self.origin, 100, 400, 64, true))
			spawnpoint = level.chugabud_spawn_struct;
	}

	if(!isdefined(spawnpoint))
	{
		if(get_chugabud_spawn_point_from_nodes(self.origin, 50, 400, 256, true))
			spawnpoint = level.chugabud_spawn_struct;
	}

	if(!isdefined(spawnpoint))
		spawnpoint = maps\_zombiemode::check_for_valid_spawn_near_team(self, true);
	if(!isdefined(spawnpoint))
		spawnpoint = self.spectator_respawn;
	return spawnpoint;
}

get_chugabud_spawn_point_from_nodes(v_origin, min_radius, max_radius, max_height, ignore_targetted_nodes)
{
	if(!isdefined(level.chugabud_spawn_struct))
		level.chugabud_spawn_struct = SpawnStruct();

	found_node = undefined;
	a_nodes = GetNodesInRadiusSorted(v_origin, max_radius, min_radius, max_height, "pathnodes");

	if(isdefined(a_nodes) && a_nodes.size > 0)
	{
		a_player_volumes = GetEntArray("player_volume", "script_noteworthy");

		for(i = a_nodes.size - 1; i >= 0; i--)
		{
			n_node = a_nodes[i];

			if(is_true(ignore_targetted_nodes))
			{
				if(isdefined(n_node.target))
					continue;
			}

			if(!PositionWouldTelefrag(n_node.origin))
			{
				if(check_point_in_active_zone(n_node.origin))
				{
					v_start = (n_node.origin[0], n_node.origin[1], n_node.origin[2] + 30);
					v_end = (n_node.origin[0], n_node.origin[1], n_node.origin[2] - 30);
					trace = BulletTrace(v_start, v_end, false, undefined);

					if(trace["fraction"] < 1)
					{
						override_abort = false;

						if(isdefined(level._chugabud_reject_node_override_func))
							override_abort = run_function(level, level._chugabud_reject_node_override_func, v_origin, n_node);

						if(!is_true(override_abort))
						{
							found_node = n_node;
							break;
						}
					}
				}
			}
		}
	}

	if(isdefined(found_node))
	{
		level.chugabud_spawn_struct.origin = found_node.origin;
		v_dir = VectorNormalize(v_origin - level.chugabud_spawn_struct.origin);
		level.chugabud_spawn_struct.angles = VectortoAngles(v_dir);
		return true;
	}
	return false;
}

force_corpse_respawn_position(forced_corpse_position)
{
	level.chugabud_force_corpse_position = forced_corpse_position;
}

force_player_respawn_position(forced_player_position)
{
	level.chugabud_force_player_position = forced_player_position;
}

player_has_chugabud_corpse()
{
	if(isdefined(self.e_chugabud_corpse))
		return true;
	return false;
}

chugabud_corpse_cleanup_on_spectator(player)
{
	self endon("death");
	player endon("disconnect");

	for(;;)
	{
		if(player.sessionstate == "spectator")
			break;
		wait .05;
	}

	player chugabud_corpse_cleanup(self, false);
}

chugabud_corpse_revive_icon(player)
{
	self endon("death");

	height_offset = 30;

	hud_elem = NewHudElem();
	hud_elem.x = self.origin[0];
	hud_elem.y = self.origin[1];
	hud_elem.z = self.origin[2] + height_offset;
	hud_elem.alpha = .05;
	hud_elem.archived = true;
	hud_elem SetShader("waypoint_revive", 5, 5);
	hud_elem SetWayPoint(true);
	hud_elem.hidewheninmenu = true;
	self.revive_hud_elem = hud_elem;

	for(;;)
	{
		if(!isdefined(self.revive_hud_elem))
			return;

		hud_elem.x = self.origin[0];
		hud_elem.y = self.origin[1];
		hud_elem.z = self.origin[2] + height_offset;
		wait .05;
	}
}

activate_chugabud_effects_and_audio()
{
	if(!isdefined(self.whos_who_effects_active))
	{
		self.whos_who_effects_active = true;
		self SetClientDvars(
			"r_waterSheetingFX_magnitude", .01,
			"r_waterSheetingFX_distortionScaleFactor", ".3 1 0 0",
			"r_waterSheetingFX_fadeDuration", 3
		);
		self SetWaterSheeting(true);
		self levelNotify("chugabud_effects_enable");
		self thread deactivate_chugabud_effects_and_audio();
	}
}

deactivate_chugabud_effects_and_audio()
{
	self waittill_either("death", "chugabud_effects_cleanup");

	if(is_true(self.whos_who_effects_active))
	{
		self SetClientDvars(
			"r_waterSheetingFX_magnitude", .0655388,
			"r_waterSheetingFX_distortionScaleFactor", ".021961 1 0 0",
			"r_waterSheetingFX_fadeDuration", 2
		);
		self SetWaterSheeting(false);
		self levelNotify("chugabud_effects_disable");
	}
	self.whos_who_effects_active = undefined;
}

is_weapon_available_in_chugabud_corpse(weapon, player_to_check)
{
	count = 0;
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		if(!players[i] player_has_chugabud_corpse())
			continue;
		if(isdefined(player_to_check) && players[i] != player_to_check)
			continue;

		 loadout = players[i].e_chugabud_corpse.loadout_chugabud;
		 count += maps\apex\_zm_weapons::is_weapon_available_in_loadout(weapon, loadout.loadout);
	}

	return count;
}