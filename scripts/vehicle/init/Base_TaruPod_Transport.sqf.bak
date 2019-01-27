[_this select 0,
	{
		(_this select 0) allowDamage false;
		[_this select 0, "black", []] call BIS_fnc_initVehicle;
		[_this select 0, "B_Parachute", 0] call JB_fnc_setBackpackCargoGlobal;
		[_this select 0] call SERVER_TaruPod_DoorManager;
		[_this select 0] remoteExec ["Parachute_SetupClient", 0, true]; // JIP
		(_this select 0) setVariable ["ASL_DONOTSLING", true, true];
		[_this select 0, 4.0] call JB_fnc_internalStorageInitContainer;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 120] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;