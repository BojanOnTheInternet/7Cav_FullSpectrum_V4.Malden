[_this select 0,
	{
		[_this select 0, 4.0] call JB_fnc_internalStorageInitContainer;
		[_this select 0, SERVER_LightParaDrop] call JB_fnc_paradropSlungCargo;
		[_this select 0] remoteExec ["Parachute_SetupClient", 0, true]; //JIP
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 2];
		[_this select 0, "B_Parachute", 0] call JB_fnc_setBackpackCargoGlobal;
		[_this select 0] call SERVER_Ghosthawk_DoorManager;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;