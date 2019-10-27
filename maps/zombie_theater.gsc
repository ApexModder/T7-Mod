#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager;
//#include maps\_zombiemode_protips;

#include maps\zombie_theater_magic_box;
#include maps\zombie_theater_movie_screen;
#include maps\zombie_theater_quad;
#include maps\zombie_theater_teleporter;

main()
{
	level thread maps\zombie_theater_ffotd::main_start();

	maps\zombie_theater_fx::main();
	maps\zombie_theater_amb::main();

	PreCacheModel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");
	precacheShader("ac130_overlay_grain");
	precacheshellshock( "electrocution" );
	// ww: model used for ee rooms
	PreCacheModel( "zombie_theater_reelcase_obj" );
	PreCacheShader( "zom_icon_theater_reel" );
	// ww: viewmodel arms for the level
	PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen
	// DSM: models for light changing
	PreCacheModel("zombie_zapper_cagelight_on");
	precachemodel("zombie_zapper_cagelight");
	PreCacheModel("lights_hang_single");
	precachemodel("lights_hang_single_on_nonflkr");
	precachemodel("zombie_theater_chandelier1arm_off");
	precachemodel("zombie_theater_chandelier1arm_on");
	precachemodel("zombie_theater_chandelier1_off");
	precachemodel("zombie_theater_chandelier1_on");




	if(GetDvarInt( #"artist") > 0)
	{
		return;
	}

	level.dogs_enabled = true;
	level.random_pandora_box_start = true;

	level.zombie_anim_override = maps\zombie_theater::anim_override_func;

	// Animations needed for door initialization
	curtain_anim_init();

	level thread maps\_callbacksetup::SetupCallbacks();

	level.quad_move_speed = 35;
	level.quad_traverse_death_fx = maps\zombie_theater_quad::quad_traverse_death_fx;
	level.quad_explode = true;

	level.dog_spawn_func = maps\_zombiemode_ai_dogs::dog_spawn_factory_logic;

	// Special zombie types, engineer and quads.
	level.custom_ai_type = [];
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_quad::init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_dogs::init );

	level.door_dialog_function = maps\_zombiemode::play_door_dialog;
	level.first_round_spawn_func = true;
	//level.round_spawn_func = maps\zombie_theater_quad::Intro_Quad_Spawn;;

	setup_t7_mod();
	level._uses_retrievable_ballisitic_knives = true;
	precacheItem( "explosive_bolt_zm" );
	precacheItem( "explosive_bolt_upgraded_zm" );

	level.use_zombie_heroes = true;
	level.disable_protips = 1;

	// DO ACTUAL ZOMBIEMODE INIT
	maps\_zombiemode::main();
	maps\zombie_theater_teleporter::teleporter_init();
	// maps\_zombiemode_timer::init();

	// Turn off generic battlechatter - Steve G
	battlechatter_off("allies");
	battlechatter_off("axis");

	maps\_zombiemode_ai_dogs::enable_dog_rounds();

	init_zombie_theater();

	// Setup the levels Zombie Zone Volumes
	maps\_compass::setupMiniMap("menu_map_zombie_theater");
	level.ignore_spawner_func = ::theater_ignore_spawner;

	level.zone_manager_init_func = ::theater_zone_init;
	init_zones[0] = "foyer_zone";
	init_zones[1] = "foyer2_zone";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	level thread maps\_zombiemode_auto_turret::init();
    level thread set_rope_collision();

	// DCS: extracam screen stuff.
	level.extracam_screen = GetEnt("theater_extracam_screen", "targetname");
	level.extracam_screen Hide();
	clientnotify("camera_stop");

	init_sounds();
	level thread add_powerups_after_round_1();
	level thread zombie_dog_pathing_hack();
	level thread barricade_glitch_fix();

	visionsetnaked( "zombie_theater", 0 );
	maps\zombie_theater_teleporter::teleport_pad_hide_use();

	level thread maps\zombie_theater_ffotd::main_end();
}


#using_animtree( "generic_human" );
anim_override_func()
{
	level.scr_anim["zombie"]["walk7"] 	= %ai_zombie_walk_v8;	//goose step walk
}




//*****************************************************************************


#using_animtree( "zombie_theater" );
curtain_anim_init()
{
	level.scr_anim["curtains_move"] = %o_zombie_theatre_curtain;
	level.scr_anim["curtains_move_close"] = %o_zombie_theatre_curtain_close;
}

theater_playanim( animname )
{
	self UseAnimTree(#animtree);
	self animscripted(animname + "_done", self.origin, self.angles, level.scr_anim[animname],"normal", undefined, 2.0  );
}

//*****************************************************************************
// POWERUP FUNCTIONS
//*****************************************************************************
add_powerups_after_round_1()
{

	//want to precache all the stuff for these powerups, but we don't want them to be available in the first round
	level.zombie_powerup_array = array_remove (level.zombie_powerup_array, "nuke");
	level.zombie_powerup_array = array_remove (level.zombie_powerup_array, "fire_sale");

	while (1)
	{
		if (level.round_number > 1)
		{
			level.zombie_powerup_array = array_add(level.zombie_powerup_array, "nuke");
			level.zombie_powerup_array = array_add(level.zombie_powerup_array, "fire_sale");
			break;
		}
		wait (1);
	}
}

//*****************************************************************************

init_zombie_theater()
{
	flag_init( "curtains_done" );
	flag_init( "lobby_occupied" );
	flag_init( "dining_occupied" );
	flag_init( "special_quad_round" );

	// Setup the magic box map
	thread maps\zombie_theater_magic_box::magic_box_init();

	//setup the movie screen
	level thread maps\zombie_theater_movie_screen::initMovieScreen();

	// setup breakaway roofs
	thread maps\zombie_theater_quad::init_roofs();

	level thread teleporter_intro();
}

//*****************************************************************************
teleporter_intro()
{
	flag_wait( "all_players_spawned" );

	wait( 0.25 );

	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] SetTransported( 2 );
	}

	playsoundatposition( "evt_beam_fx_2d", (0,0,0) );
    playsoundatposition( "evt_pad_cooldown_2d", (0,0,0) );
}
//AUDIO

init_sounds()
{
	maps\_zombiemode_utility::add_sound( "wooden_door", "zmb_door_wood_open" );
	maps\_zombiemode_utility::add_sound( "fence_door", "zmb_door_fence_open" );
}


// *****************************************************************************
// Zone management
// *****************************************************************************

theater_zone_init()
{
	flag_init( "always_on" );
	flag_set( "always_on" );

	// foyer_zone
	add_adjacent_zone( "foyer_zone", "foyer2_zone", "always_on" );

	add_adjacent_zone( "foyer_zone", "vip_zone", "magic_box_foyer1" );
	add_adjacent_zone( "foyer2_zone", "crematorium_zone", "magic_box_crematorium1" );
	add_adjacent_zone( "foyer_zone", "crematorium_zone", "magic_box_crematorium1" );

	// vip_zone
	add_adjacent_zone( "vip_zone", "dining_zone", "vip_to_dining" );

	// crematorium_zone
	add_adjacent_zone( "crematorium_zone", "alleyway_zone", "magic_box_alleyway1" );

	// dining_zone
	add_adjacent_zone( "dining_zone", "dressing_zone", "dining_to_dressing" );

	// dressing_zone
	add_adjacent_zone( "dressing_zone", "stage_zone", "magic_box_dressing1" );

	// stage_zone
	add_adjacent_zone( "stage_zone", "west_balcony_zone", "magic_box_west_balcony2" );

	// theater_zone
	add_adjacent_zone( "theater_zone", "foyer2_zone", "power_on" );
	add_adjacent_zone( "theater_zone", "stage_zone", "power_on" );

	// west_balcony_zone
	add_adjacent_zone( "west_balcony_zone", "alleyway_zone", "magic_box_west_balcony1" );
}

theater_ignore_spawner( spawner )
{
	// no curtains, no quads
	if ( !flag( "curtains_done" ) )
	{
		if ( spawner.script_noteworthy == "quad_zombie_spawner" )
		{
			return true;
		}
	}

	// DCS: when special round happens, first half quads.
	if ( flag( "special_quad_round" ) )
	{
		if ( spawner.script_noteworthy != "quad_zombie_spawner" )
		{
			return true;
		}
	}

	if ( !flag( "lobby_occupied" ) )
	{
		if ( spawner.script_noteworthy == "quad_zombie_spawner" && spawner.targetname == "foyer_zone_spawners" )
		{
			return true;
		}
	}

	if ( !flag( "dining_occupied" ) )
	{
		if ( spawner.script_noteworthy == "quad_zombie_spawner" && spawner.targetname == "zombie_spawner_dining" )
		{
			return true;
		}
	}

	return false;
}

// *****************************************************************************
// 	DCS: random round change quad emphasis
// 	This should only happen in zones where quads spawn into
// 	and crawl down the wall.
//	potential zones: foyer_zone, theater_zone, stage_zone, dining_zone
// *****************************************************************************
quad_wave_init()
{
	level thread time_for_quad_wave("foyer_zone");
	level thread time_for_quad_wave("theater_zone");
	level thread time_for_quad_wave("stage_zone");
	level thread time_for_quad_wave("dining_zone");

	level waittill( "end_of_round" );
	flag_clear( "special_quad_round" );
}

time_for_quad_wave(zone_name)
{

	if(!IsDefined(zone_name))
	{
		return;
	}
	zone = level.zones[ zone_name ];

	//	wait for round change.
	level waittill( "between_round_over" );

	//avoid dog rounds.
	if ( IsDefined( level.next_dog_round ) && level.next_dog_round == level.round_number )
	{
		level thread time_for_quad_wave(zone_name);
		return;
	}

	// ripped from spawn script for accuracy.	-------------------------------------
	max = level.zombie_vars["zombie_max_ai"];
	multiplier = level.round_number / 5;
	if( multiplier < 1 )
	{
		multiplier = 1;
	}

	if( level.round_number >= 10 )
	{
		multiplier *= level.round_number * 0.15;
	}

	player_num = get_players().size;

	if( player_num == 1 )
	{
		max += int( ( 0.5 * level.zombie_vars["zombie_ai_per_player"] ) * multiplier );
	}
	else
	{
		max += int( ( ( player_num - 1 ) * level.zombie_vars["zombie_ai_per_player"] ) * multiplier );
	}
	// ripped from spawn script for accuracy.	-------------------------------------

	//percent chance.
	chance = 100;
	max_zombies = [[ level.max_zombie_func ]]( max );
	current_round = level.round_number;

	// every third round a chance of a quad wave.
	if((level.round_number % 3 == 0) && chance >= RandomInt(100))
	{
		if(zone.is_occupied)
		{
			flag_set( "special_quad_round" );
			maps\_zombiemode_zone_manager::reinit_zone_spawners();

			while( level.zombie_total < max_zombies /2 && current_round == level.round_number )
			{
				wait(0.1);
			}

			//level waittill( "end_of_round" );

			flag_clear( "special_quad_round" );
			maps\_zombiemode_zone_manager::reinit_zone_spawners();

		}
	}
	level thread time_for_quad_wave(zone_name);
}

set_rope_collision()
{
 techrope = getentarray("techrope01", "targetname");
 if(isdefined(techrope))
 {

   for( i = 0; i < techrope.size; i++ )
   {
    ropesetflag( techrope[i], "collide", 1 );
    ropesetflag( techrope[i], "no_lod", 1 );
   }
  }
}

zombie_dog_pathing_hack()
{
	PreCacheModel("collision_geo_64x64x128");
	PreCacheModel("collision_wall_128x128x10");
	wait(1);

	collision = spawn("script_model", (-391, 1194, 16));
	collision setmodel("collision_geo_64x64x128");
	collision.angles = (0, 301.8, 0);
	collision Hide();

	collision = spawn("script_model", (480, 1155, -16));
	collision setmodel("collision_geo_64x64x128");
	collision.angles = (0, 357, 0);
	collision Hide();

	//DCS: additional collision for theater turret platform
	collision = spawn("script_model", (-20, 957, 128));
	collision setmodel("collision_geo_64x64x128");
	collision.angles = (0, 0, 0);
	collision Hide();
	collision = spawn("script_model", (20, 957, 128));
	collision setmodel("collision_geo_64x64x128");
	collision.angles = (0, 0, 0);
	collision Hide();

	collision = spawn("script_model", (1458, -57, 342));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 0, 0);
	collision Hide();
}

barricade_glitch_fix()
{
	// dining room
	collision = spawn("script_model", (1891, 576, 48));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();

	// dressing room
	collision = spawn("script_model", (1538, 1288, 48));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();

	// upper room left
	collision = spawn("script_model", (-1099, 1120, 332));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();

	// alley north
	collision = spawn("script_model", (-1749, 552, 168));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();

	// theater left
	collision = spawn("script_model", (-763, 834, 96));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();

	// alley doubletap: 72246
	collision = spawn("script_model", (-1746, -378, 147));
	collision setmodel("collision_geo_64x64x128");
	collision.angles = (0, 0, 0);
	collision Hide();
}

//============================================================================================
// T7 Mod Setup
//============================================================================================
setup_t7_mod()
{
	level._zm_perk_includes = ::theater_include_perks;
	level._zm_powerup_includes = ::theater_include_powerups;
	level._zm_packapunch_include = maps\apex\_zm_packapunch::include_t7_packapunch;
	setup_extra_powerables();
}

//============================================================================================
// Extra Powerable
//============================================================================================
setup_extra_powerables()
{
	flag_init("theater_powered_on", false);

	maps\apex\_zm_power::add_powerable(false, ::theater_power_on, undefined);
}

theater_power_on()
{
	if(flag("theater_powered_on"))
		return;

	flag_set("theater_powered_on");
	chandelier = GetEntArray("theater_chandelier", "targetname");

	level.quads_per_round = 4 * GetPlayers().size;
	level notify("quad_round_can_end");
	level.delay_spawners = undefined;
	level thread quad_wave_init();

	for(i = 0; i < chandelier.size; i++)
	{
		if(chandelier[i].model == "zombie_theater_chandelier1arm_off")
			chandelier[i] SetModel("zombie_theater_chandelier1arm_on");
		else if(chandelier[i].model == "zombie_theater_chandelier1_off")
			chandelier[i] SetModel("zombie_theater_chandelier1_on");
	}
}

//============================================================================================
// T7 Mod Setup - Powerups
//============================================================================================
theater_include_powerups()
{
	// T4
	maps\apex\powerups\_zm_powerup_full_ammo::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_insta_kill::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_double_points::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_carpenter::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_nuke::include_powerup_for_level();

	// T5
	maps\apex\powerups\_zm_powerup_fire_sale::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_minigun::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_bonfire_sale::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_tesla::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_bonus_points::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_free_perk::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_random_weapon::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_empty_clip::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_lose_perk::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_lose_points::include_powerup_for_level();
}

//============================================================================================
// T7 Mod Setup - Perks
//============================================================================================
theater_include_perks()
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

	place_theater_perk_spawn_structs();
}

place_theater_perk_spawn_structs()
{
	// TODO: Remove later
	// These perks are here for testing
	// Wont be on kino on release
	maps\apex\_zm_perks::generate_perk_spawn_struct("tombstone", (0, 0, 0), (0, 0, 0));
	maps\apex\_zm_perks::generate_perk_spawn_struct("chugabud", (0, 128, 0), (0, 0, 0));
	maps\apex\_zm_perks::generate_perk_spawn_struct("widows", (0, 256, 0), (0, 0, 0));

	maps\apex\_zm_perks::generate_perk_spawn_struct("divetonuke", (-1130.9, 1261.31, -15.875), (0, 0, 0)); // xSanchez78 - Kino Mod Divetonuk Location
	maps\apex\_zm_perks::generate_perk_spawn_struct("marathon", (823.653, 1020.54, -15.875), (0, 0, 0)); // xSanchez78 - Kino Mod Marathon Location
	maps\apex\_zm_perks::generate_perk_spawn_struct("deadshot", (630.073, 1239.64, -15.875), (0, 90, 0)); // xSanchez78 - Kino Mod Deadshot Location
	// maps\apex\_zm_perks::generate_perk_spawn_struct("cherry", (600, -1012.48, 320.125), (0, 0, 0)); // xSanchez78 - Kino Mod Cherry Location
	maps\apex\_zm_perks::generate_perk_spawn_struct("cherry", (-846.159, -1042.2, 80.125), (0, 180, 0)); // xSanchez78 - Kino Mod - Chugabud Location
	maps\apex\_zm_perks::generate_perk_spawn_struct("vulture", (136.293, -462.601, 320.125), (0, 135, 0)); // xSanchez78 - Kino Mod Vulture Location
}