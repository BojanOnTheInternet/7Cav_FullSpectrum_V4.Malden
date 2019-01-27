[_this select 0,
	{
		(_this select 0) allowDamage false;
		(_this select 0) setRepairCargo 0;
		[_this select 0, "black", []] call BIS_fnc_initVehicle;
		(_this select 0) setVariable ["REPAIR_ServiceLevel", 2, true];
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 5];

		(_this select 0) setVariable ["ASL_DONOTSLING", true, true];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 120] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;