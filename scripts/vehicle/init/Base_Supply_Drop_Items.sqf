[_this select 0,
	{
		params ["_container"];

		[_container] call Base_Supply_Drop_Items_StockContainer;
		[_container] remoteExec ["Base_Supply_Drop_Items_C_SetupActions", 0, true]; //JIP
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1000] call JB_fnc_respawnVehicleWhenAbandoned;