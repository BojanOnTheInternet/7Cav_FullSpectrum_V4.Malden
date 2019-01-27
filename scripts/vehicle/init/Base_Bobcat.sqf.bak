BOBCAT_RestrictToGreenZone =
{
	params ["_bobcat"];

	while { alive _bobcat } do
	{
		if (not ([Headquarters, _bobcat] call BIS_fnc_inTrigger) && { not ([Carrier, _bobcat] call BIS_fnc_inTrigger) }) then
		{
			[_bobcat] call JB_fnc_respawnVehicleReturn;
		};

		{
			private _direction = _bobCat getRelDir _x;
			if (_direction < 30 || _direction > 330) then
			{
				[_x, (getPos _x) vectorAdd [0, 0, -0.333]] remoteExec ["setPos", _x];
			};

			if (((getPos _x) select 2) < -0.66) then
			{
				deleteVehicle _x;
			}
		} forEach nearestObjects [getPos _bobCat, ["CraterLong"], 9];

		sleep 2;
	};

	if (alive _bobcat) then
	{
		[_bobcat] spawn BOBCAT_RestrictToGreenZone;
	};
};

[_this select 0,
	{
		(_this select 0) allowDamage false;

		{ (_this select 0) removeWeapon _x } forEach weapons (_this select 0);
		(_this select 0) animate ["HideTurret", 1];

		(_this select 0) setRepairCargo 0;
		(_this select 0) setVariable ["REPAIR_ServiceLevel", 2, true];

		(_this select 0) setFuelCargo 0;
		[(_this select 0), [[-1.087,-4.847,-0.844]], 2000, 50] call JB_fnc_fuelInitSupply;

		(_this select 0) setAmmoCargo 0;
		[_this select 0, 800, [2, AmmoFilter_TransferToAny], []] call JB_fnc_ammoInit;

		[_this select 0, 4.0] call JB_fnc_internalStorageInitContainer;

		[_this select 0, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
		(_this select 0) addBackpackCargoGlobal ["B_AssaultPack_rgr_Repair", 3];

		[_this select 0] spawn BOBCAT_RestrictToGreenZone;

		_this remoteExec ["BobcatService_SetupClient", 0, true]; //JIP

		(_this select 0) addMPEventHandler ["MPKilled", { if (local (_this select 0)) then { [_this select 0, 0.8, 1.0] call SPM_RemoveRandomAmmunition } }];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 20] call JB_fnc_respawnVehicleWhenAbandoned;