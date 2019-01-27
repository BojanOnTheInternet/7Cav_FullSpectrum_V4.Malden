[_this select 0,
	{
		(_this select 0) removeMagazines "200Rnd_762x51_Belt_Yellow";
		(_this select 0) addMagazineTurret ["200Rnd_762x51_Belt_T_Red", [0], 200];
		(_this select 0) addMagazineTurret ["200Rnd_762x51_Belt_T_Red", [0], 200];

		(_this select 0) removeMagazinesTurret ["140Rnd_30mm_MP_shells_Tracer_Yellow", [0]];
		(_this select 0) addMagazineTurret ["140Rnd_30mm_MP_shells_Tracer_Red", [0], 140];

		(_this select 0) removeMagazinesTurret ["60Rnd_30mm_APFSDS_shells_Tracer_Yellow", [0]];
		(_this select 0) addMagazineTurret ["60Rnd_30mm_APFSDS_shells_Tracer_Red", [0], 60];
		(_this select 0) addMagazineTurret ["60Rnd_30mm_APFSDS_shells_Tracer_Red", [0], 60];

		// [_this select 0, [76/255,76/255,58/255,0.4]] call compile preprocessfile "scripts\vehicle\setunitcolor.sqf";
		{
			(_this select 0) setObjectTextureGlobal [_x, "a3\air_f_exp\vtol_01\data\vtol_01_ext02_olive_co.paa"];
		} forEach [0, 1];

		[_this select 0, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];

		(_this select 0) addMPEventHandler ["MPKilled", { if (local (_this select 0)) then { [_this select 0, 0.8, 1.0] call SPM_RemoveRandomAmmunition } }];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;