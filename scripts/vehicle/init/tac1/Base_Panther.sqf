[_this select 0,
	{
		(_this select 0) removeMagazinesTurret ["96Rnd_40mm_G_belt", [0,0]];
		(_this select 0) removeMagazinesTurret ["500Rnd_127x99_mag_Tracer_Red", [0,0]];
		(_this select 0) removeWeapon "HMG_127_APC";
		(_this select 0) removeWeapon "GMG_40mm";
		(_this select 0) setObjectTextureGlobal [2, ""];

		{
			(_this select 0) setObjectTextureGlobal [_x, "a3\air_f_exp\vtol_01\data\vtol_01_ext02_olive_co.paa"];
		} forEach [0, 1];

		[_this select 0, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];

		private _ammo = [];
		if (isNull (_this select 1)) then
		{
			_ammo = SERVER_Ammo_Artillery apply { [_x select 0, (_x select 1) * 2] };
		};

		[_this select 0, 4000, [2, AmmoFilter_TransferToAny], _ammo] call JB_fnc_ammoInit;

		(_this select 0) addMPEventHandler ["MPKilled", { if (local (_this select 0)) then { [_this select 0, 0.8, 1.0] call SPM_RemoveRandomAmmunition } }];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 450] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1000] call JB_fnc_respawnVehicleWhenAbandoned;