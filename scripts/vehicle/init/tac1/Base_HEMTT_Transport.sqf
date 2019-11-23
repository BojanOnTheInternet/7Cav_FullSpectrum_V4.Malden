[_this select 0,
	{
		[_this select 0, 8.0] call JB_fnc_internalStorageInitContainer;
	}] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1000] call JB_fnc_respawnVehicleWhenAbandoned;