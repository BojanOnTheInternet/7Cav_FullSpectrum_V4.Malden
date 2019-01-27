[_this select 0,
	{
		(_this select 0) setObjectTextureGlobal [0, "\a3\air_f\Heli_Light_01\Data\heli_light_01_ext_ion_co.paa"];
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 1];
		[_this select 0, "B_Parachute", 0] call JB_fnc_setBackpackCargoGlobal;
		[_this select 0, 1.0] call JB_fnc_internalStorageInitContainer;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;