[_this select 0,
	{
		[_this select 0, "green", []] call BIS_fnc_initVehicle;

		(_this select 0) removeMagazinesTurret ["8Rnd_120mm_HE_shells_Tracer_Red", [0]];
//		(_this select 0) removeMagazinesTurret ["4Rnd_120mm_LG_cannon_missiles", [0]];

		(_this select 0) removeMagazines "200Rnd_338_Mag";

		(_this select 0) addMagazineTurret ["130Rnd_338_Mag", [0], 130];
		(_this select 0) addMagazineTurret ["130Rnd_338_Mag", [0], 130];
		(_this select 0) addMagazineTurret ["130Rnd_338_Mag", [0], 130];

		[_this select 0, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];

		(_this select 0) addMPEventHandler ["MPKilled", { if (local (_this select 0)) then { [_this select 0, 0.8, 1.0] call SPM_RemoveRandomAmmunition } }];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;