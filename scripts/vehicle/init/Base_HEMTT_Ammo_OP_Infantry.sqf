[
	_this select 0,
	{
		(_this select 0) setAmmoCargo 0;

		[_this select 0] call compile preprocessFile "scripts\vehicle\setUnitAsArsenal.sqf";

		[_this select 0, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;