[_this select 0,
	{
		createVehicleCrew (_this select 0);

		{
			private _member = _x;
			{ _member setSkill [_x, 1.0] } forEach ((configProperties [configFile >> "CfgAiSkill"]) apply { configName _x });
		} forEach crew (_this select 0);
		group driver (_this select 0) allowFleeing 0.0;

		(_this select 0) setAutonomous false;
		[_this select 0, [Headquarters, Carrier], []] execVM "scripts\greenZoneInit.sqf";

		(_this select 0) addMPEventHandler ["MPKilled", { if (local (_this select 0)) then { [_this select 0, 0.8, 1.0] call SPM_RemoveRandomAmmunition } }];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 900] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 300] call JB_fnc_respawnVehicleWhenAbandoned;