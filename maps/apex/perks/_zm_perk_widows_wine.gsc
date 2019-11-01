#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("widows", "specialty_widows_wine_zombies");
	maps\apex\_zm_perks::register_perk_bottle("widows", undefined, undefined, 34);
	maps\apex\_zm_perks::register_perk_machine("widows", false, &"ZOMBIE_PERK_WIDOWSWINE", 2000, "p7_zm_vending_widows_wine", "p7_zm_vending_widows_wine_on", "perk_light_red");
	maps\apex\_zm_perks::register_perk_threads("widows", ::give_widows, ::take_widows);
	maps\apex\_zm_perks::register_perk_sounds("widows", "mus_perks_widows_sting", "mus_perks_widows_jingle", undefined);

	maps\apex\powerups\_zm_powerup_ww_grenade::include_powerup_for_level();

	level._effect["widows_wine_wrap" ] = LoadFX("sanchez/widows_wine/fx_widows_wine_zombie");
	level._effect["widows_wine_exp_1p" ] = LoadFX("sanchez/widows_wine/fx_widows_wine_explode");
	init_widows_wine();

	level.zombiemode_using_widows_perk = true;
	level._ZOMBIE_ACTOR_WIDOWS_WINE_WRAPPING = 2;
}

give_widows()
{
	lethal = self get_player_lethal_grenade();

	if(is_equal(level.w_widows_wine_grenade, lethal))
		return;

	self.w_widows_wine_prev_grenade = lethal;
	self maps\apex\_zm_weapons::weapon_take(self.w_widows_wine_prev_grenade);
	self maps\apex\_zm_weapons::give_weapon(level.w_widows_wine_grenade);
	self set_player_lethal_grenade(level.w_widows_wine_grenade);
	self.w_widows_wine_prev_knife = self get_player_melee_weapon();

	if(isdefined(self.widows_wine_knife_override))
		run_function(self, self.widows_wine_knife_override);
	else
	{
		self maps\apex\_zm_weapons::weapon_take(self.w_widows_wine_prev_knife);

		if(self.w_widows_wine_prev_knife == "bowie_knife_zm")
		{
			self maps\apex\_zm_weapons::give_weapon(level.w_widows_wine_bowie_knife);
			self set_player_melee_weapon(level.w_widows_wine_bowie_knife);
		}
		else if(self.w_widows_wine_prev_knife == "sickle_knife_zm")
		{
			self maps\apex\_zm_weapons::give_weapon(level.w_widows_wine_sickle_knife);
			self set_player_melee_weapon(level.w_widows_wine_sickle_knife);
		}
		else
		{
			self maps\apex\_zm_weapons::give_weapon(level.w_widows_wine_knife);
			self set_player_melee_weapon(level.w_widows_wine_knife);
		}
	}

	self.check_override_wallbuy_purchase = ::widows_wine_override_wallbuy_purchase;
	self.check_override_melee_wallbuy_purchase = ::widows_wine_override_melee_wallbuy_purchase;
}

take_widows(reason)
{
	self notify("stop_widows_wine");
	self endon("death");

	if(self maps\_laststand::player_is_in_laststand())
	{
		self waittill("player_revived");

		if(self has_perk("widows"))
			return;
	}

	self.check_override_wallbuy_purchase = undefined;
	self maps\apex\_zm_weapons::weapon_take(level.w_widows_wine_grenade);

	if(isdefined(self.w_widows_wine_prev_grenade))
	{
		self.lsgsar_lethal = self.w_widows_wine_prev_grenade;
		self maps\apex\_zm_weapons::give_weapon(self.w_widows_wine_prev_grenade);
		self set_player_lethal_grenade(self.w_widows_wine_prev_grenade);
	}
	else
		self init_player_lethal_grenade();

	grenade = self get_player_lethal_grenade();
	self GiveStartAmmo(grenade);

	if(self.w_widows_wine_prev_knife == "bowie_knife")
		self maps\apex\_zm_weapons::weapon_take(level.w_widows_wine_bowie_knife);
	else if(self.w_widows_wine_prev_knife == "sickle_knife_zm")
		self maps\apex\_zm_weapons::weapon_take(level.w_widows_wine_sickle_knife);
	else
		self maps\apex\_zm_weapons::weapon_take(level.w_widows_wine_knife);

	if(isdefined(self.w_widows_wine_prev_knife))
	{
		self maps\apex\_zm_weapons::give_weapon(self.w_widows_wine_prev_knife);
		self set_player_melee_weapon(self.w_widows_wine_prev_knife);
	}
	else
		self init_player_melee_weapon();
}

init_widows_wine()
{
	maps\_zombiemode_spawner::register_zombie_damage_callback(::widows_wine_zombie_damage_response);
	maps\_zombiemode_spawner::register_zombie_death_event_callback(::widows_wine_zombie_death_watch);
	maps\apex\_zm_perks::register_perk_damage_override_func(::widows_wine_damage_callback);
	//register_lethal_grenade_for_level("sticky_grenade_widows_wine_zm");
	level.w_widows_wine_grenade = "frag_grenade_zm";//"sticky_grenade_widows_wine_zm";
	//register_melee_weapon_for_level("knife_widows_wine_zm");
	level.w_widows_wine_knife = "knife_zm";//"knife_widows_wine_zm";
	//register_melee_weapon_for_level("bowie_knife_widows_wine_zm");
	level.w_widows_wine_bowie_knife = "bowie_knife_zm";//"bowie_knife_widows_wine_zm";
	// register_melee_weapon_for_level("sickle_knife_widows_wine_zm");
	level.w_widows_wine_sickle_knife = "sickle_knife_zm";
}

widows_wine_contact_explosion()
{
	grenade = self get_player_lethal_grenade();
	self MagicGrenadeType(grenade, self.origin + (0, 0, 48), (0, 0, 0), 0);
	self SetWeaponAmmoClip(grenade, self GetWeaponAmmoClip(grenade) - 1);
	set_client_system_state("widows_wine_1p_contact_explosion", "1", self);
}

widows_wine_zombie_damage_response(str_mod, str_hit_location, v_hit_origin, e_player, n_amount, w_weapon, direction_vec, tagName, modelName, partName, dFlags, inflictor, chargeLevel)
{
	if((isdefined(self.damageweapon) && self.damageweapon == level.w_widows_wine_grenade) || (is_equal(str_mod, "MOD_MELEE") && isdefined(e_player) && IsPlayer(e_player) && e_player has_perk("widows") && RandomFloat(1) <= 0.5))
	{
		if(!is_true(self.no_widows_wine))
		{
			self thread maps\apex\_zm_powerups::check_for_instakill(e_player, str_mod, str_hit_location);
			n_dist_sq = DistanceSquared(self.origin, v_hit_origin);

			if(n_dist_sq <= 10000)
				self thread widows_wine_cocoon_zombie(e_player);
			else
				self thread widows_wine_slow_zombie(e_player);

			if(!is_true(self.no_damage_points) && isdefined(e_player))
				e_player maps\_zombiemode_score::player_add_points("damage", str_mod, str_hit_location, false, undefined, w_weapon);

			return true;
		}
	}
	return false;
}

widows_wine_damage_callback(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(!self has_perk("widows"))
		return undefined;
	if(sWeapon == level.w_widows_wine_grenade)
		return 0;

	grenade = self get_player_lethal_grenade();

	if(grenade == level.w_widows_wine_grenade && self GetWeaponAmmoClip(grenade) > 0)
	{
		if(sMeansOfDeath == "MOD_MELEE" && IsAI(eAttacker))
		{
			self thread widows_wine_contact_explosion();
			return iDamage;
		}
	}
	return undefined;
}

widows_wine_zombie_death_watch(attacker)
{
	if((is_true(self.b_widows_wine_cocoon) || is_true(self.b_widows_wine_slow)) && !is_true(self.b_widows_wine_no_powerup))
	{
		if(isdefined(self.attacker) && IsPlayer(self.attacker) && self.attacker has_perk("widows"))
		{
			chance = 0.2;

			if(isdefined(self.damageweapon) && self.damageweapon == level.w_widows_wine_grenade)
				chance = 0.15;
			else if(isdefined(self.damageweapon) && (self.damageweapon == level.w_widows_wine_knife || self.damageweapon == level.w_widows_wine_bowie_knife || self.damageweapon == level.w_widows_wine_sickle_knife))
				chance = 0.25;

			if(RandomFloat(1) <= chance)
			{
				self.no_powerups = true;
				level._powerup_timeout_override = ::powerup_widows_wine_timeout;
				// Fix Issue: #5 - Power up dropping to low
				maps\apex\_zm_powerups::specific_powerup_drop("ww_grenade", self.origin + (0, 0, 40), self.attacker);
				level._powerup_timeout_override = undefined;
			}
		}
	}
}

powerup_widows_wine_timeout()
{
	self endon("powerup_grabbed");
	self endon("death");
	self endon("powerup_reset");
	self maps\apex\_zm_powerups::powerup_show(true);
	wait_time = 1;

	if(isdefined(level._powerup_timeout_custom_time))
	{
		time = [[level._powerup_timeout_custom_time ]](self);

		if(time == 0)
			return;

		wait_time = time;
	}

	wait wait_time;

	for(i = 20; i > 0; i--)
	{
		if(i % 2)
			self maps\apex\_zm_powerups::powerup_show(false);
		else
			self maps\apex\_zm_powerups::powerup_show(true);

		if(i > 15)
			wait 0.3;

		if(i > 10)
			wait 0.25;
		else if(i > 5)
			wait 0.15;
		else
			wait 0.1;
	}
	self notify("powerup_timedout");
}

widows_wine_cocoon_zombie_score(e_player, duration, max_score)
{
	self notify("widows_wine_cocoon_zombie_score");
	self endon("widows_wine_cocoon_zombie_score");
	self endon("death");
	start_time = GetTime();
	end_time = start_time + (duration * 1000);

	while(GetTime() < end_time)
	{
		e_player maps\_zombiemode_score::add_to_player_score(10);
		wait duration / max_score;
	}
}

widows_wine_cocoon_zombie(e_player)
{
	self notify("widows_wine_cocoon");
	self endon("widows_wine_cocoon");

	if(is_true(self.kill_on_wine_coccon))
		self DoDamage(self.health + 666, self.origin);

	if(!is_true(self.b_widows_wine_cocoon))
	{
		self.b_widows_wine_cocoon = true;
		self.e_widows_wine_player = e_player;

		if(isdefined(self.widows_wine_cocoon_fraction_rate))
			widows_wine_cocoon_fraction_rate = self.widows_wine_cocoon_fraction_rate;
		else
			widows_wine_cocoon_fraction_rate = 0.1;

		self.melee_anim_rate = widows_wine_cocoon_fraction_rate;
		self.moveplaybackrate = widows_wine_cocoon_fraction_rate;
		self.animplaybackrate = widows_wine_cocoon_fraction_rate;
		self.traverseplaybackrate = widows_wine_cocoon_fraction_rate;
		self SetClientFlag(level._ZOMBIE_ACTOR_WIDOWS_WINE_WRAPPING);
	}

	if(isdefined(e_player))
		self thread widows_wine_cocoon_zombie_score(e_player, 16, 10);

	self waittill_any_or_timeout(16, "death");

	if(!isdefined(self))
		return;

	self.melee_anim_rate = 1;
	self.moveplaybackrate = 1;
	self.animplaybackrate = 1;
	self.traverseplaybackrate = 1;
	self ClearClientFlag(level._ZOMBIE_ACTOR_WIDOWS_WINE_WRAPPING);

	if(IsAlive(self))
		self.b_widows_wine_cocoon = false;
}

widows_wine_slow_zombie(e_player)
{
	self notify("widows_wine_slow");
	self endon("widows_wine_slow");

	if(is_true(self.b_widows_wine_cocoon))
	{
		self thread widows_wine_cocoon_zombie(e_player);
		return;
	}

	if(isdefined(e_player))
		self thread widows_wine_cocoon_zombie_score(e_player, 12, 6);

	if(!is_true(self.b_widows_wine_slow))
	{
		if(isdefined(self.widows_wine_slow_fraction_rate))
			widows_wine_slow_fraction_rate = self.widows_wine_slow_fraction_rate;
		else
			widows_wine_slow_fraction_rate = 0.7;

		self.b_widows_wine_slow = true;
		self.melee_anim_rate = widows_wine_slow_fraction_rate;
		self.moveplaybackrate = widows_wine_slow_fraction_rate;
		self.animplaybackrate = widows_wine_slow_fraction_rate;
		self.traverseplaybackrate = widows_wine_slow_fraction_rate;
		self SetClientFlag(level._ZOMBIE_ACTOR_WIDOWS_WINE_WRAPPING);
	}

	self waittill_any_or_timeout(12, "death");

	if(!isdefined(self))
		return;

	self.melee_anim_rate = 1;
	self.moveplaybackrate = 1;
	self.animplaybackrate = 1;
	self.traverseplaybackrate = 1;
	self ClearClientFlag(level._ZOMBIE_ACTOR_WIDOWS_WINE_WRAPPING);

	if(IsAlive(self))
		self.b_widows_wine_slow = false;
}

widows_wine_override_wallbuy_purchase(weapon, wallbuy)
{
	if(is_lethal_grenade(weapon))
	{
		// ammo_cost = maps\apex\_zm_weapons::get_ammo_cost(weapon);
		ammo_cost = Int(level.zombie_weapons[weapon].cost / 2);

		if(self.score >= ammo_cost)
		{
			if(wallbuy.first_time_triggered == false)
				wallbuy maps\apex\_zm_weapons::show_all_weapon_buys();

			current_lethal_grenade = self get_player_lethal_grenade();

			if(self GetAmmoCount(current_lethal_grenade) < WeaponMaxAmmo(current_lethal_grenade))
			{
				self maps\_zombiemode_score::minus_to_player_score(ammo_cost);
				self play_sound_on_ent("purchase");
				self GiveMaxAmmo(current_lethal_grenade);
			}
		}
		else
		{
			wallbuy play_sound_on_ent("no_purchase");
			self maps\_zombiemode_audio::create_and_play_dialog("general", "no_money", undefined, 1);
		}
		return true;
	}
	return false;
}

widows_wine_override_melee_wallbuy_purchase(vo_dialog_id, flourish_weapon, weapon, ballistic_weapon, ballistic_upgraded_weapon, flourish_fn, wallbuy)
{
	/*if (zm_utility::is_melee_weapon(weapon))
	{
		if (self.w_widows_wine_prev_knife != weapon)
		{
			cost = wallbuy.stub.cost;

			if (self zm_score::can_player_purchase(cost))
			{
				if (wallbuy.first_time_triggered == false)
				{
					model = getent(wallbuy.target, "targetname");

					if (isdefined(model))
					{
						model thread zm_melee_weapon::melee_weapon_show(self);
					}
					else if (isdefined(wallbuy.clientFieldName))
					{
						level clientfield::set(wallbuy.clientFieldName, 1);
					}

					wallbuy.first_time_triggered = true;
					if (isdefined(wallbuy.stub))
					{
						wallbuy.stub.first_time_triggered = true;
					}

				}

				self zm_score::minus_to_player_score(cost);


				assert(weapon.name == "bowie_knife");
				self.w_widows_wine_prev_knife = weapon;
				if(self.w_widows_wine_prev_knife.name == "bowie_knife")
				{
					self thread zm_melee_weapon::give_melee_weapon(vo_dialog_id, flourish_weapon, weapon, ballistic_weapon, ballistic_upgraded_weapon, flourish_fn, wallbuy);
				}
			}
			else
			{
				zm_utility::play_sound_on_ent("no_purchase");
				self zm_audio::create_and_play_dialog("general", "outofmoney", 1);
			}
		}
		return true;
	}*/
	return false;
}