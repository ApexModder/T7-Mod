#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("tombstone", "specialty_tombstone_zombies");
	maps\apex\_zm_perks::register_perk_bottle("tombstone", undefined, undefined, 29);
	maps\apex\_zm_perks::register_perk_machine("tombstone", false, &"ZOMBIE_PERK_TOMBSTONE", 2000, "zombie_vending_tombstone", "zombie_vending_tombstone_on", "perk_light_green");
	maps\apex\_zm_perks::register_perk_threads("tombstone", ::give_tombstone, ::take_tombstone);
	maps\apex\_zm_perks::register_perk_sounds("tombstone", "mus_perks_tombstone_sting", "mus_perks_tombstone_jingle", undefined);

	maps\apex\_zm_powerups::powerup_set_can_pick_up_in_revive_trigger("tombstone", false);
	maps\apex\_zm_powerups::powerup_set_can_pick_up_in_last_stand("tombstone", false);
	maps\apex\_zm_powerups::powerup_set_prevent_pick_up_if_drinking("tombstone", true);
	// maps\apex\_zm_powerups::powerup_set_announcer_vox_type("tombstone", announcer_vox_type);
	maps\apex\_zm_powerups::register_basic_powerup("tombstone", "ch_tombstone1", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("tombstone", ::tombstone_powerup_setup, ::tombstone_powerup_grabbed, undefined, maps\apex\_zm_powerups::func_should_never_drop);

	level.zombiemode_using_tombstone_perk = true;
	OnPlayerLastStand_Callback(::on_laststand);
}

give_tombstone()
{
}

take_tombstone(reason)
{
}

save_tombstone_loadout()
{
	loadout = SpawnStruct();
	loadout.weapon_loadout = self maps\apex\_zm_weapons::player_get_loadout();
	loadout.perks = self get_player_obtained_perks();
	return loadout;
}

give_tombstone_loadout(loadout)
{
	self maps\apex\_zm_weapons::player_give_loadout(loadout.weapon_loadout, true);

	for(i = 0; i < loadout.perks.size; i++)
	{
		if(self has_perk(loadout.perks[i]))
			continue;

		self maps\apex\_zm_perks::give_perk(loadout.perks[i], false);
	}
}

on_laststand()
{
	if(self has_perk("tombstone"))
		maps\apex\_zm_powerups::specific_powerup_drop("tombstone", self.origin + (0, 0, 40), self, false);
}

tombstone_powerup_setup()
{
	self._can_be_grabbed = false;
	self.tombstone_owner = self.powerup_player;
	self.owner = self.tombstone_owner;
	self.powerup_player = undefined; // powerup player causes model to not be visible to other players
	self.powerup_wobble_func = ::tombstone_powerup_wobble;
	self.loadout = self.tombstone_owner save_tombstone_loadout();
	self thread tombstone_powerup_timeout();
	self thread tombstone_powerup_hide_when_reviving();
	self thread tombstone_powerup_delete();
}

tombstone_powerup_wobble()
{
	self endon("death");
	self endon("powerup_grabbed");
	self endon("powerup_timedout");
	self endon("powerup_cleanup");

	for(;;)
	{
		self RotateYaw(360, 3);
		wait 2.9;
	}
}

tombstone_powerup_timeout()
{
	self endon("death");
	self endon("powerup_grabbed");
	self endon("powerup_timedout");
	self endon("powerup_cleanup");
	self.tombstone_owner endon("player_revived");
	self.tombstone_owner endon("disconnect");
	self.tombstone_owner waittill("spawned_player");
	self._can_be_grabbed = true;
	self thread maps\apex\_zm_powerups::powerup_timeout_think();
}

tombstone_powerup_grabbed(player)
{
	if(!is_true(self._can_be_grabbed))
		return true;
	if(self.tombstone_owner != player)
		return true;

	self.tombstone_owner thread give_tombstone_loadout(self.loadout);
	return false;
}

tombstone_powerup_hide_when_reviving()
{
	self endon("death");
	self endon("powerup_grabbed");
	self endon("powerup_timedout");
	self endon("powerup_cleanup");
	self.tombstone_owner endon("spawned_player");
	self.tombstone_owner endon("player_revived");
	self.tombstone_owner endon("disconnect");

	self maps\apex\_zm_powerups::powerup_show(true);
	show = true;

	for(;;)
	{
		wait .05;

		if(isdefined(self.tombstone_owner.reviveTrigger) && is_true(self.tombstone_owner.reviveTrigger.beingRevived))
		{
			if(show)
			{
				show = false;
				self maps\apex\_zm_powerups::powerup_show(false);
			}
		}
		else
		{
			if(!show)
			{
				show = true;
				self maps\apex\_zm_powerups::powerup_show(true);
			}
		}
	}
}

tombstone_powerup_delete()
{
	self endon("death");
	self endon("powerup_grabbed");
	self endon("powerup_timedout");
	self endon("powerup_cleanup");
	self.tombstone_owner waittill_either("disconnect", "player_revived");
	self notify("powerup_cleanup");
}