
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager;
//#include maps\_zombiemode_protips;

main()
{
	level thread maps\zombie_cosmodrome_ffotd::main_start();

	// viewmodel arms for the level
	PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen


	// Light model cacheing for Gantry

	PreCacheModel("p_rus_rb_lab_warning_light_01");
  PreCacheModel("p_rus_rb_lab_warning_light_01_off");
  PreCacheModel("p_rus_rb_lab_light_core_on");
  PreCacheModel("p_rus_rb_lab_light_core_off");


	//needs to be first for create fx
	maps\zombie_cosmodrome_fx::main();
	maps\zombie_cosmodrome_amb::main();

	PreCacheModel("zombie_lander_crashed");
	cosmodrome_precache();

	//DCS 110210: precache on screen for lander control.
	PreCacheModel("p_zom_cosmo_lunar_control_panel_dlc_on");

	//maps\_zombiemode_powercell::powercell_precache();

	if(GetDvarInt( #"artist") > 0)
	{
		return;
	}

	//test stuff, etc...
	//precachemodel("t5_veh_jet_mig17");
	precachemodel("tag_origin");

	level.player_out_of_playable_area_monitor = true;
	level.player_out_of_playable_area_monitor_callback = ::zombie_cosmodrome_player_out_of_playable_area_monitor_callback;
	maps\zombie_cosmodrome_ai_monkey::init();

	// Setup global_funcs
	maps\zombie_cosmodrome_traps::init_funcs();

	// Set pay turret cost
	level.pay_turret_cost = 1000;
	level.lander_cost	= 250;


	level.random_pandora_box_start = false;

	level thread maps\_callbacksetup::SetupCallbacks();
	setup_t7_mod();

	level.quad_move_speed = 35;

	level.dog_spawn_func = maps\_zombiemode_ai_dogs::dog_spawn_factory_logic;

	// Special zombie types, engineer and quads.
	level.custom_ai_type = [];
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_monkey::init );

	level.door_dialog_function = maps\_zombiemode::play_door_dialog;

	level.use_zombie_heroes = true;

	// Jluyties(02/22/10) added new lunar landing for intro of level.
	// MMaestas - this needs to be defined about _zombiemode::main
	level.round_prestart_func = maps\zombie_cosmodrome_lander::new_lander_intro;

	level.zombiemode_precache_player_model_override = ::precache_player_model_override;
	level.zombiemode_give_player_model_override = ::give_player_model_override;
	level.zombiemode_player_set_viewmodel_override = ::player_set_viewmodel_override;

	level.monkey_prespawn = maps\zombie_cosmodrome_ai_monkey::monkey_cosmodrome_prespawn;
	level.monkey_zombie_failsafe = maps\zombie_cosmodrome_ai_monkey::monkey_cosmodrome_failsafe;
	level.max_perks = 5;
	level.max_solo_lives = 3;

	// WW (01/14/11) - Start introscreen client notify
	level thread cosmodrome_fade_in_notify();

	// DO ACTUAL ZOMBIEMODE INIT
	maps\_zombiemode::main();

	// Turn off generic battlechatter - Steve G
	battlechatter_off("allies");
	battlechatter_off("axis");


	level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_MONKEY_LANDER_FX = 12;

	// Init tv screens
	level maps\zombie_cosmodrome_magic_box::magic_box_init();

	// Setup the levels Zombie Zone Volumes

	level.zone_manager_init_func = ::cosmodrome_zone_init;
	init_zones[0] = "centrifuge_zone";
	init_zones[1] = "centrifuge_zone2";

	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	level thread maps\_zombiemode_auto_turret::init();
	level thread maps\zombie_cosmodrome_lander::init();
	level thread maps\zombie_cosmodrome_traps::init_traps();
	level thread setup_water_physics();
	level thread centrifuge_jumpup_fix();
	level thread centrifuge_jumpdown_fix();
	level thread centrifuge_init();

	// -- WWILLIAMS: CONTROLS THE PACK A PUNCH RISING SITUATION
	level thread maps\zombie_cosmodrome_pack_a_punch::pack_a_punch_main();

	level thread maps\zombie_cosmodrome_achievement::init();

	level thread maps\zombie_cosmodrome_eggs::init();

	// Set the CosmoDrome Vision Set
	level.zombie_visionset = "zombie_cosmodrome_nopower";
	level thread fx_for_power_path();

	level thread spawn_life_brushes();
	level thread spawn_kill_brushes();

	init_sounds();

	level thread maps\zombie_cosmodrome_ffotd::main_end();
}


spawn_life_brushes()
{
	// the rubble by the entrance to the platform lander
	maps\_zombiemode::spawn_life_brush( (-1415, 1540, 0), 180, 100 ); // centrifuge
}


spawn_kill_brushes()
{
	// inside the two walls in the corner by the box on the lander platform
	maps\_zombiemode::spawn_kill_brush( (-1800, 2116, -60), 15, 100 );
	maps\_zombiemode::spawn_kill_brush( (-1872, 2156, -20), 15, 100 );

	// under the 4 landers positions
	maps\_zombiemode::spawn_kill_brush( (-672, -152, -552), 110, 55 ); // centrifuge
	maps\_zombiemode::spawn_kill_brush( (-2272, 1768, -136), 110, 55 ); // platform
	maps\_zombiemode::spawn_kill_brush( (160, -2320, -136), 110, 55 ); // storage
	maps\_zombiemode::spawn_kill_brush( (1760, 1256, 280), 110, 55 ); // catwalk

	// above the 4 landers positions
	maps\_zombiemode::spawn_kill_brush( (-672, -152, 0), 200, 1000 ); // centrifuge
	maps\_zombiemode::spawn_kill_brush( (-2272, 1768, 130), 200, 1000 ); // platform
	maps\_zombiemode::spawn_kill_brush( (160, -2320, 50), 400, 1000 ); // storage
	maps\_zombiemode::spawn_kill_brush( (1760, 1256, 490), 400, 1000 ); // catwalk


// These have been replaced by the "above the 4 lander positions,
// since if we kill the player before the lander starts moving laterally,
// they have no way to fall off onto inaccessible rooftops
//	// low roof by the storage area door (opposite staminup)
//	maps\_zombiemode::spawn_kill_brush( (0, -425, -10), 400, 100 );
//
//	// glass roof of power building
//	maps\_zombiemode::spawn_kill_brush( (-532, 1200, 382), 500, 100 );
//
//	// roof next to railing next to spawn closet on small catwalk above the lander platform
//	maps\_zombiemode::spawn_kill_brush( (-1600, 1200, 25), 30, 100 );
//
//	// small overhang crossing above the entrance to the lander platform
//	maps\_zombiemode::spawn_kill_brush( (-1820, 1815, 130), 330, 100 );
}


zombie_cosmodrome_player_out_of_playable_area_monitor_callback()
{
	if ( is_true( self.lander ) || is_true( self.on_lander_last_stand ) )
	{
		return false;
	}

	return true;
}


//------------------------------------------------------------------------------
setup_water_physics()
{
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	for (i = 0; i < players.size; i++)
  {
		players[i] SetClientDvars("phys_buoyancy",1);
	}
}

//------------------------------------------------------------------------------
fx_for_power_path()
{
	self endon ("power_on");

	// trying out an fx at the end of the cable
	while( 1 )
	{
		PlayFX(level._effect["dangling_wire"], ( -1066, 1024, -72), (0, 0, 1)  ); // first
		wait (0.3 + RandomFloat(0.5));
		PlayFX(level._effect["dangling_wire"], ( -900, 1446, -96), (0, 0, 1)  ); // second, perfect
		wait (0.3 + RandomFloat(0.5));
		PlayFX(level._effect["dangling_wire"], ( -895, 1442, -52), (0, 0, 1)  ); // second, perfect
		wait (0.3 + RandomFloat(0.5));
		//wait (0.3 + RandomFloat(1.5));
	}

}
//------------------------------------------------------------------------------
centrifuge_jumpup_fix()
{
	jumpblocker = GetEnt("centrifuge_jumpup", "targetname");

	if(!IsDefined(jumpblocker))
	return;

	jump_pos = jumpblocker.origin;
	centrifuge_occupied = false;

	while(true)
	{
		if(level.zones["centrifuge_zone"].is_occupied && centrifuge_occupied == false)
		{
			jumpblocker MoveX(jump_pos[0] + 64, 0.1);
			jumpblocker DisconnectPaths();
			centrifuge_occupied = true;
		}
		else if(!level.zones["centrifuge_zone"].is_occupied && centrifuge_occupied == true)
		{
			jumpblocker MoveTo(jump_pos, 0.1);
			jumpblocker ConnectPaths();
			centrifuge_occupied = false;
		}
		wait(1);
	}
}
centrifuge_jumpdown_fix()
{
	jumpblocker = GetEnt("centrifuge_jumpdown", "targetname");

	if(!IsDefined(jumpblocker))
	return;

	jump_pos = jumpblocker.origin;
	centrifuge2_occupied = true;

	while(true)
	{
		if(level.zones["centrifuge_zone2"].is_occupied && centrifuge2_occupied == false)
		{
			jumpblocker MoveX(jump_pos[0] + 64, 0.1);
			jumpblocker DisconnectPaths();
			centrifuge2_occupied = true;
		}
		else if(!level.zones["centrifuge_zone2"].is_occupied && centrifuge2_occupied == true)
		{
			jumpblocker MoveTo(jump_pos, 0.1);
			jumpblocker ConnectPaths();
			centrifuge2_occupied = false;
		}
		wait(1);
	}
}

//
//	ZOMBIEMODE OVERRIDES
//
// magic_box_override()
// {
// 	flag_wait( "all_players_connected" );

// 	players = get_players();
// 	level.chest_min_move_usage = players.size;

// 	chest = level.chests[level.chest_index];
// 	while ( level.chest_accessed < level.chest_min_move_usage )
// 	{
// 		chest waittill( "chest_accessed" );
// 	}

// 	// Okay it's been accessed, now we need to fake move it.
// 	chest disable_trigger();

// 	// SAMANTHA IS BACK!
// 	chest.chest_lid maps\apex\_zm_weapons::treasure_chest_lid_open();
// //	self.chest_user thread maps\apex\_zm_weapons::treasure_chest_move_vo();
// 	chest thread maps\apex\_zm_weapons::treasure_chest_move();

// 	wait 0.5;	// we need a wait here before this notify
// 	level notify("weapon_fly_away_start");
// 	wait 2;
// // 	model MoveZ(500, 4, 3);
// // 	model waittill("movedone");
// // 	model delete();
// 	chest notify( "box_moving" );
// 	level notify("weapon_fly_away_end");
// 	level.chest_min_move_usage = undefined;
// }


//*****************************************************************************
// ZONE INIT
//*****************************************************************************
cosmodrome_zone_init()
{
	// Set flags here for your starting zone if there are any zones that need to be connected from the beginning.
	// For instance, if your
	flag_init( "centrifuge" );
	flag_set( "centrifuge" );

	// Special init for the graveyard
	//add_adjacent_zone( "graveyard_zone",	"graveyard_lander",	"no_mans_land" );


	//############################################
	// GROUPS: Defining self-contained areas that will always connect when activated
	//	Do not put zones that connect through doorways here.
	//	YOU SHOULD NOT BE CALLING add_zone_flags in this section.
	//############################################

	// Base entrance lander
	add_adjacent_zone( "access_tunnel_zone",	"base_entry_zone",			"base_entry_group" );

	// Storage area
	add_adjacent_zone( "storage_zone",			"storage_zone2",			"storage_group" );

	// Power Building
	add_adjacent_zone( "power_building",		"base_entry_zone2",			"power_group" );

	// Drop-off connection - top of stairs in north path (one way drop)
	add_adjacent_zone( "north_path_zone",  "roof_connector_zone",			"roof_connector_dropoff" );

	// open blast doors.
	add_adjacent_zone( "north_path_zone",		"under_rocket_zone",		"rocket_group" );
	add_adjacent_zone( "control_room_zone",		"under_rocket_zone",		"rocket_group" );

	//############################################
	//	Now set the connections that need to be made based on doors being open
	//	Use add_zone_flags to connect any zones defined above.
	//############################################
	add_adjacent_zone( "centrifuge_zone",	"centrifuge_zone2",		"centrifuge" );

	// Centrifuge door 1st floor towards power
	add_adjacent_zone( "centrifuge_zone",	"centrifuge2power_zone",		"centrifuge2power" );
	//add_adjacent_zone( "centrifuge_zone2",	"centrifuge2power_zone",		"centrifuge2power" );


	// Door at 1st floor of power building
	add_adjacent_zone( "base_entry_zone2",	"centrifuge2power_zone",		"power2centrifuge" );
	add_zone_flags(	"power2centrifuge",										"power_group" );

	// Side Tunnel to Centrifuge
	add_adjacent_zone( "access_tunnel_zone",	"centrifuge_zone",			"tunnel_centrifuge_entry" );
	add_zone_flags(	"tunnel_centrifuge_entry",								"base_entry_group" );

	// Base Entrance
	add_adjacent_zone( "base_entry_zone",		"base_entry_zone2",			"base_entry_2_power" );
	add_zone_flags(	"base_entry_2_power",									"base_entry_group" );
	add_zone_flags(	"base_entry_2_power",									"power_group" );

	// Power Building
 	add_adjacent_zone( "power_building",		"power_building_roof",		"power_interior_2_roof" );
	add_zone_flags(	"power_interior_2_roof",								"power_group" );

	// Door from catwalks to connector zone
	add_adjacent_zone( "north_catwalk_zone3",	"roof_connector_zone",		"catwalks_2_shed" );
	add_zone_flags(	"catwalks_2_shed",										"roof_connector_dropoff" );

	// Tunnel to Storage
	add_adjacent_zone( "access_tunnel_zone",	"storage_zone",				"base_entry_2_storage" );
	add_adjacent_zone( "access_tunnel_zone",	"storage_zone2",			"base_entry_2_storage" );
	add_zone_flags(	"base_entry_2_storage",									"storage_group" );
	add_zone_flags(	"base_entry_2_storage",									"base_entry_group" );

	// Storage Lander
	add_adjacent_zone( "storage_lander_zone",	"storage_zone",				"storage_lander_area" );
	add_adjacent_zone( "storage_lander_zone",	"storage_zone2",			"storage_lander_area" );
	//add_adjacent_zone( "storage_lander_zone",	"access_tunnel_zone",		"storage_lander_area" );

	// Northern passageway to rocket
	add_adjacent_zone( "north_path_zone",		"base_entry_zone2",			"base_entry_2_north_path" );
	add_zone_flags(	"base_entry_2_north_path",								"power_group" );
	add_zone_flags(	"base_entry_2_north_path",								"roof_connector_dropoff" );
	//add_zone_flags(	"base_entry_2_north_path",								"control_room" );

	// Power Building to Catwalks
	add_adjacent_zone( "power_building_roof",	"roof_connector_zone",		"power_catwalk_access" );
	add_zone_flags(	"power_catwalk_access",									"roof_connector_dropoff" );

}

//
////*****************************************************************************
//// PRO TIPS INIT
////*****************************************************************************
//
//protips_init()
//{
////	addProTipTime(	1, 8, "zm_pt_zombie_breakout" );
//
////	AddProTipFlag(	1, 2, "no_mans_land_pro_tip", "zm_pt_enter_nml" );
//
////	addProTipFunction(  1, 2, ::power_cell_pickup, "zm_pt_power_cells" );
////	addProTipPosAngle( 2, 1, (-359, -820, 0), 0.4, 42*5, "zm_pt_facility_entrance" );
////	addProTipPosAngle( 2, 1, (-498, 1838, -107), 0.0, 42*8, "zm_pt_base_entry_zone2" );
//}
//
//
////*****************************************************************************
//// POWERCELL INIT
////*****************************************************************************
//
//powercell_init()
//{
//// 	pack_trigger = GetEnt( "zombie_vending_upgrade", "targetname" );
//// 	pack_trigger trigger_off();
////
//// 	// hide the batteries
//// 	for ( i = 1; i <= 4; i++ )
//// 	{
//// 		battery = GetEnt( "pack_battery_0" + i, "targetname" );
//// 		battery hide();
//// 	}
////
//// 	level.packBattery = 0;
////
//// 	//MM - Pack on power on
//// 	flag_wait( "power_on" );
////
//// 	level notify( "powercell_done" );
//// 	level notify( "Pack_A_Punch_on" );
////
//// 	door_r = GetEnt( "pack_door_r", "targetname" );
//// 	door_l = GetEnt( "pack_door_l", "targetname" );
////
//// 	door_r RotateYaw( 160, 5, 0 );
//// 	door_l RotateYaw( -160, 5, 0 );
////
//// 	pack_trigger = GetEnt( "zombie_vending_upgrade", "targetname" );
//// 	pack_trigger trigger_on();
//}

//*****************************************************************************
// POWERCELL DROPOFF
//*****************************************************************************

powercell_dropoff()
{
	level.packBattery++;
	battery = GetEnt( "pack_battery_0" + level.packBattery, "targetname" );
	battery show();

	battery.fx = Spawn( "script_model", battery.origin );
	battery.fx.angles = battery.angles;
	battery.fx SetModel( "tag_origin" );

	playfxontag(level._effect["powercell"],battery.fx,"tag_origin");

// 	if ( level.packBattery == 4 )
// 	{
// 		level notify( "powercell_done" );
// 		level notify( "Pack_A_Punch_on" );
//
// 		door_r = GetEnt( "pack_door_r", "targetname" );
// 		door_l = GetEnt( "pack_door_l", "targetname" );
//
// 		door_r RotateYaw( 160, 5, 0 );
// 		door_l RotateYaw( -160, 5, 0 );
//
// 		pack_trigger = GetEnt( "zombie_vending_upgrade", "targetname" );
// 		pack_trigger trigger_on();
// 	}
}

////////////////////////////////////////////////////////////////////////////

// custom_pandora_show_func( anchor, anchorTarget, pieces )
// {
// 	level.pandora_light.angles = (-90, anchorTarget.angles[1] + 180, 0);
// 	level.pandora_light moveto(anchorTarget.origin, 0.05);
// 	wait(1);
// 	playfx( level._effect["lght_marker_flare"],level.pandora_light.origin );
// }

// custom_pandora_fx_func()
// {
// 	// Hacked to get it to the start location. DCS
// 	start_chest = GetEnt("start_chest", "script_noteworthy");
// 	anchor = GetEnt(start_chest.target, "targetname");
// 	anchorTarget = GetEnt(anchor.target, "targetname");

// 	level.pandora_light = Spawn( "script_model", anchorTarget.origin );
// 	level.pandora_light.angles = anchorTarget.angles + (-90, 0, 0);
// 	level.pandora_light SetModel( "tag_origin" );
// 	playfxontag(level._effect["lght_marker"], level.pandora_light, "tag_origin");
// }

//*****************************************************************************
// rotating centrifuge (will cause damage later)
//*****************************************************************************
centrifuge_init()
{
	centrifuge = GetEnt("centrifuge", "targetname");
	if(IsDefined(centrifuge))
	{
		//centrifuge link_centrifuge_pieces(); //currently no attachments
		centrifuge centrifuge_rotate();
	}
}

link_centrifuge_pieces()
{
	pieces = getentarray( self.target, "targetname" );
	if(IsDefined(pieces))
	{
		for ( i = 0; i < pieces.size; i++ )
		{
			pieces[i] linkto( self );
		}
	}
	self thread centrifuge_rotate();
}

centrifuge_rotate()
{
	while(true)
	{
		self rotateyaw( 360, 20 );
		self waittill("rotatedone");
	}
}

cosmodrome_precache()
{
	PreCacheModel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");

	// ww: therse pieces are used for the magic box televisions. the models are changed in csc
	PreCacheModel( "p_zom_monitor_csm" );
	PreCacheModel( "p_zom_monitor_csm_screen_catwalk" );
	PreCacheModel( "p_zom_monitor_csm_screen_centrifuge" );
	PreCacheModel( "p_zom_monitor_csm_screen_enter" );
	PreCacheModel( "p_zom_monitor_csm_screen_fsale1" );
	PreCacheModel( "p_zom_monitor_csm_screen_fsale2" );
	PreCacheModel( "p_zom_monitor_csm_screen_labs" );
	PreCacheModel( "p_zom_monitor_csm_screen_logo" );
	PreCacheModel( "p_zom_monitor_csm_screen_obsdeck" );
	PreCacheModel( "p_zom_monitor_csm_screen_off" );
	PreCacheModel( "p_zom_monitor_csm_screen_on" );
	PreCacheModel( "p_zom_monitor_csm_screen_warehouse" );
	PreCacheModel( "p_zom_monitor_csm_screen_storage" );
	PreCacheModel( "p_zom_monitor_csm_screen_topack" );

	//DCS; screens for rocket launch
	PreCacheModel("p_zom_key_console_01");
	PreCacheModel("p_zom_rocket_sign_02");
	PreCacheModel("p_zom_rocket_sign_03");
	PreCacheModel("p_zom_rocket_sign_04");

	PreCacheRumble( "damage_heavy" ); // rumble for centrifuge
}

precache_player_model_override()
{
	mptype\player_t5_zm_cosmodrome::precache();
}

give_player_model_override( entity_num )
{
	if( IsDefined( self.zm_random_char ) )
	{
		entity_num = self.zm_random_char;
	}

	switch( entity_num )
	{
		case 0:
			character\c_usa_dempsey_dlc2::main();// Dempsy
			break;
		case 1:
			character\c_rus_nikolai_dlc2::main();// Nikolai
			break;
		case 2:
			character\c_jap_takeo_dlc2::main();// Takeo
			break;
		case 3:
			character\c_ger_richtofen_dlc2::main();// Richtofen
			break;
	}
}

player_set_viewmodel_override( entity_num )
{
	switch( self.entity_num )
	{
		case 0:
			// Dempsey
			self SetViewModel( "viewmodel_usa_pow_arms" );
			break;
		case 1:
			// Nikolai
			self SetViewModel( "viewmodel_rus_prisoner_arms" );
			break;
		case 2:
			// Takeo
			self SetViewModel( "viewmodel_vtn_nva_standard_arms" );
			break;
		case 3:
			// Richtofen
			self SetViewModel( "viewmodel_usa_hazmat_arms" );
			break;
	}
}

init_sounds()
{
	maps\_zombiemode_utility::add_sound( "electric_metal_big", "zmb_heavy_door_open" );
	maps\_zombiemode_utility::add_sound( "gate_swing", "zmb_door_fence_open" );
	maps\_zombiemode_utility::add_sound( "electric_metal_small", "zmb_lab_door_slide" );
	maps\_zombiemode_utility::add_sound( "gate_slide", "zmb_cosmo_gate_slide" );
	maps\_zombiemode_utility::add_sound( "door_swing", "zmb_cosmo_door_swing" );
}

// WW (01/14/11): Watches for notify of screen fade in from _zombiemode_until. After recieving the notify from server a clientnotify is
// broadcast so the slients know when to start changing their beginning vision set
cosmodrome_fade_in_notify()
{
	// wait for fade_in function to finish
	level waittill("fade_in_complete");

	// notify client -- "Zombie Introscreen Done"
	level ClientNotify( "ZID" );

	wait_network_frame();
}

//============================================================================================
// T7 Mod Setup
//============================================================================================
setup_t7_mod()
{
	level._zm_perk_includes = ::cosmodrome_include_perks;
	level._zm_powerup_includes = ::cosmodrome_include_powerups;
	level._zm_packapunch_include = maps\apex\_zm_packapunch::include_t7_packapunch;
	setup_extra_powerables();
}

//============================================================================================
// Extra Powerable
//============================================================================================
setup_extra_powerables()
{
	flag_init("cosmodrome_powered_on", false);

	maps\apex\_zm_power::add_powerable(false, ::cosmodrome_power_on, undefined);
}

cosmodrome_power_on()
{
	PlaySoundAtPosition("zmb_poweron_front", (0, 0, 0));
	level thread maps\zombie_cosmodrome_amb::play_cosmo_announcer_vox( "vox_ann_power_switch" );
	exploder(5401);

	if(flag("cosmodrome_powered_on"))
		return;

	flag_set("lander_power");
	flag_set("cosmodrome_powered_on");
	level thread maps\zombie_cosmodrome_amb::power_clangs();
}

//============================================================================================
// T7 Mod Setup - Powerups
//============================================================================================
cosmodrome_include_powerups()
{
	// T4
	maps\apex\powerups\_zm_powerup_full_ammo::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_insta_kill::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_double_points::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_carpenter::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_nuke::include_powerup_for_level();

	// T5
	maps\apex\powerups\_zm_powerup_fire_sale::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_minigun::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_bonfire_sale::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_tesla::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_bonus_points::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_free_perk::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_random_weapon::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_empty_clip::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_lose_perk::include_powerup_for_level();
	// maps\apex\powerups\_zm_powerup_lose_points::include_powerup_for_level();
}

//============================================================================================
// T7 Mod Setup - Perks
//============================================================================================
cosmodrome_include_perks()
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

	place_cosmodrome_perk_spawn_structs();
}

place_cosmodrome_perk_spawn_structs()
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