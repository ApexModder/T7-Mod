#include clientscripts\_utility;
#include clientscripts\apex\_utility;

init()
{
	level._power_on = false;
	level flag_init("zm_power_state", false);
	add_level_notify_callback("ZPO", ::power_state_change, true);
	add_level_notify_callback("ZPOff", ::power_state_change, false);
}

power_state_change(clientnum, power_on)
{
	if(is_true(power_on))
	{
		if(!level flag("power_on"))
		{
			level._power_on = true;
			level flag_set("power_on");
			level notify("power_on");
			level notify("middle_door_open"); // TODO: Add powerables to csc
		}
	}
	else
	{
		if(level flag("power_on"))
		{
			level._power_on = false;
			level flag_clear("power_on");
			level notify("power_off");
		}
	}
}