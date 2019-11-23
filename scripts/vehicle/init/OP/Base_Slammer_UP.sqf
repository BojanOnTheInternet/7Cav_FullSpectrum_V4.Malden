[_this select 0,
	{
		params ["_vehicle", "_oldVehicle"];

		[_vehicle, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
		_vehicle addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];

		_vehicle addMPEventHandler ["MPKilled", { if (local (_this select 0)) then { [_this select 0, 0.8, 1.0] call SPM_RemoveRandomAmmunition } }];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;
