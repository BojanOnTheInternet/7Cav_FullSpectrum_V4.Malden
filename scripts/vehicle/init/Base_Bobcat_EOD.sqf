// Catches explosives plus FuelExplosion, FuelExplosionBig, HelicopterExploSmall, HelicopterExploBig
Bobcat_DamageIsFromExplosion =
{
	(_this select 4) find "Explo" >= 0 || { (_this select 4) isKindOf "TimeBombCore" }
};

[_this select 0,
	{
		(_this select 0) setRepairCargo 0;
		(_this select 0) setFuelCargo 0;
		(_this select 0) setAmmoCargo 0;

		[_this select 0, 20.0] call JB_fnc_internalStorageInitContainer;
		[_this select 0, 0.0, 0.33, Bobcat_DamageIsFromExplosion] call JB_fnc_damagePulseInitObject;

		[_this select 0, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];

		[_this select 0] remoteExec ["Bobcat_AddActions", 0, true]; // JIP
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;