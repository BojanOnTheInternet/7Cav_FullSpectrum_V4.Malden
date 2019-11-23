[_this select 0,
	{
		(_this select 0) removeMagazinesTurret ["96Rnd_40mm_G_belt", [0]];
		(_this select 0) removeWeaponTurret ["GMG_40mm", [0]];
		(_this select 0) addMagazineTurret ["32Rnd_40mm_G_belt", [0]];
		(_this select 0) addWeaponTurret ["GMG_40mm", [0]];

		[_this select 0, 2.0] call JB_fnc_internalStorageInitContainer;

		(_this select 0) addMPEventHandler ["MPKilled", { if (local (_this select 0)) then { [_this select 0, 0.8, 1.0] call SPM_RemoveRandomAmmunition } }];
	}] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;