Base_GhostHawk_Armed_WeaponControlCondition =
{
	params ["_player", "_vehicle"];

	if (not (_player in [driver _vehicle, _vehicle turretUnit [0]])) exitWith { false };

	private _results = ["VP_Pilot", _vehicle, _player] call VP_CheckPermissions;

	count (_results select 0) > 0 // Any permissions were granted
};

[_this select 0,
	{
		params ["_vehicle", "_oldVehicle"]; 

		_vehicle removeMagazines "2000Rnd_65x39_Belt_Tracer_Red";
		_vehicle removeWeaponTurret ["LMG_Minigun_Transport", [1]];
		_vehicle removeWeaponTurret ["LMG_Minigun_Transport2", [2]];

		_vehicle addMagazineTurret ["5000Rnd_762x51_Belt", [1]];
		_vehicle addWeaponTurret ["M134_Minigun", [1]];

		_vehicle addMagazineTurret ["5000Rnd_762x51_Belt", [2]];
		_vehicle addWeaponTurret ["M134_Minigun", [2]];
 
		[_vehicle, Base_GhostHawk_Armed_WeaponControlCondition] call JB_fnc_weaponControlInitializeVehicle; 
//		[_vehicle, [1], "M134_Minigun", false] call JB_fnc_weaponControlEnableWeapon; 
//		[_vehicle, [2], "M134_Minigun", false] call JB_fnc_weaponControlEnableWeapon; 

		[_vehicle, 4.0] call JB_fnc_internalStorageInitContainer; 
		[_vehicle, SERVER_LightParaDrop] call JB_fnc_paradropSlungCargo; 
		[_vehicle] remoteExec ["Parachute_SetupClient", 0, true]; //JIP 
		_vehicle addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 2]; 
		[_vehicle, "B_Parachute", 0] call JB_fnc_setBackpackCargoGlobal; 
		[_vehicle] call SERVER_Ghosthawk_DoorManager; 
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;