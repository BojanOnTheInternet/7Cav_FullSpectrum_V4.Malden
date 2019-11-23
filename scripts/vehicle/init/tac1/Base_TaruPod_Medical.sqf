[_this select 0,
	{
		(_this select 0) allowDamage false;
		[_this select 0, "black", []] call BIS_fnc_initVehicle;
		[_this select 0, 20] call JB_fnc_medicalInitAmbulance;
		[_this select 0] call SERVER_TaruPod_DoorManager;
		(_this select 0) setVariable ["ASL_DONOTSLING", true, true];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 120] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1000] call JB_fnc_respawnVehicleWhenAbandoned;