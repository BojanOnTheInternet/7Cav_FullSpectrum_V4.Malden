[_this select 0,
	{
		[_this select 0, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
		[_this select 0, 1.0] call JB_fnc_internalStorageInitContainer;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1000] call JB_fnc_respawnVehicleWhenAbandoned;