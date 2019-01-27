/*

	vehicleCrewRestrictionInit - given a list of pairs of vehicle filters and restrictions,
	when a player occupies a seat of a vehicle matching a filter, apply the corresponding restriction.

	[restriction, vehicleFilter] call compile "vehicleCrewRestrictionInit.sqf";
	[restriction, vehicleFilter] execVM "vehicleCrewRestrictionInit.sqf";

*/

VCR_MovePlayer =
{
	private _vehicle = (_this select 0);
	private _keepPlayerInVehicle = (_this select 1);

	if (_keepPlayerInVehicle && { (_vehicle emptyPositions "cargo") > 0 }) then
	{
		moveOut player;
		player moveInCargo _vehicle;
	}
	else
	{
		player action ["getOut", _vehicle];
	};
};

VCR_CheckRestrictions =
{
	private _playerInVehicle = param [0, false, [false]];

	// Allow incapacitated soldiers to be loaded into any position of any vehicle
	if (lifeState player == "INCAPACITATED") exitWith {};

	private _vehicle = vehicle player;

	private _restrictions = player getVariable ["VCR_Restrictions", []];

	{
		if ([typeOf _vehicle, _x select 1] call JB_fnc_passesTypeFilter) then
		{
			[_vehicle, _playerInVehicle, _x select 2] call (_x select 0);
		};
	} forEach _restrictions;
};

Restriction_MayNotDriveVehicle =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	private _state = _vehicle getVariable ["Restriction_MayNotDriveVehicle", "active"];

	if (_state == "suspended") exitWith { };

	if (player == (driver _vehicle)) then
	{
		private _playerClassDisplayName = ([roleDescription player] call SPM_Util_CleanedRoleDescription);
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["In your role of %1, you may not drive this vehicle (%2)", _playerClassDisplayName, _vehicleClassDisplayName], "black in", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

Restriction_MayNotDriveOccupiedVehicle =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player == (driver _vehicle) && count crew _vehicle > 1) then
	{
		private _playerClassDisplayName = ([roleDescription player] call SPM_Util_CleanedRoleDescription);
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["In your role of %1, you may not drive this vehicle (%2) while it is occupied", _playerClassDisplayName, _vehicleClassDisplayName], "black in", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

Restriction_MayNotEnterLogisticsVehicle =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (not isNull driver _vehicle && { player != driver _vehicle } && { (driver _vehicle) getVariable ["JBA_LogisticsSpecialist", false] }) then
	{
		private _driverClassDisplayName = ([roleDescription driver _vehicle] call SPM_Util_CleanedRoleDescription);
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["You may not enter this vehicle (%2) while it it driven by a %1", _driverClassDisplayName, _vehicleClassDisplayName], "black in", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

Restriction_MayNotGunCommandVehicle =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player == (gunner _vehicle) || player == (commander _vehicle)) then
	{
		private _playerClassDisplayName = [roleDescription player] call SPM_Util_CleanedRoleDescription;
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		private _prohibitedRole = if (player == (gunner _vehicle)) then { "gunner" } else { "commander" };

		titleText [format ["In your role of %1, you may not act as %2 for this vehicle (%3)", _playerClassDisplayName, _prohibitedRole, _vehicleClassDisplayName], "black in", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

Restriction_MayNotCrewVehicle =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player == (driver _vehicle) || player == (gunner _vehicle) || player == (commander _vehicle)) then
	{
		private _playerClassDisplayName = [roleDescription player] call SPM_Util_CleanedRoleDescription;
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["In your role of %1, you may not crew this vehicle (%2)", _playerClassDisplayName, _vehicleClassDisplayName], "black in", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};
};

Restriction_MayNotPilotAircraft =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player in [driver _vehicle]) then
	{
		private _playerClassDisplayName = [roleDescription player] call SPM_Util_CleanedRoleDescription;
		private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

		titleText [format ["In your role of %1, you may not pilot this aircraft (%2)", _playerClassDisplayName, _vehicleClassDisplayName], "black in", 5];
		[_vehicle, _playerInVehicle] call VCR_MovePlayer;
	};

	if (player in [_vehicle turretUnit [0]]) then
	{
		[_vehicle, false] remoteExec ["enableCopilot", 2]; // If performed locally, the server setting will eventually propagate and reset the value
	};
};

// This is needed to counter the change of aircraft state in Restriction_MayNotPilotAircraft
Permission_MayCopilotAircraft =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player in [_vehicle turretUnit [0]]) then
	{
		_vehicle enableCopilot true;
	};
};

Restriction_MayNotOperateGunTurrets =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _playerInVehicle = param [1, false, [true]];

	if (player != driver _vehicle) then
	{
		private _role = assignedVehicleRole player;
		if (count _role > 0) then // BUG: ARMA sometimes fires the GetInMan event before assigning the vehicle role to the player
		{
			private _weapons = _vehicle weaponsTurret (_role select 1);
			private _offensiveWeapons = _weapons select { not (_x isKindOf ["CarHorn", configFile >> "CfgWeapons"]) && { not (_x isKindOf ["SmokeLauncher", configFile >> "CfgWeapons"]) }  && { not (_x isKindOf ["Laserdesignator_mounted", configFile >> "CfgWeapons"]) } };
			if (count _offensiveWeapons > 0) then
			{
				private _playerClassDisplayName = [roleDescription player] call SPM_Util_CleanedRoleDescription;
				private _vehicleClassDisplayName = [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName;

				titleText [format ["In your role of %1, you may not operate weapons on this vehicle (%2)", _playerClassDisplayName, _vehicleClassDisplayName], "black in", 5];
				[_vehicle, _playerInVehicle] call VCR_MovePlayer;
			};
		};
	};
};

private _restrictions = param [0, [], [[]]];

player setVariable ["VCR_Restrictions", _restrictions];

if (not (player getVariable ["VCR_RestrictionHandlersInstalled", false])) then
{
	player addEventHandler ["GetInMan", { [false] call VCR_CheckRestrictions }];
	player addEventHandler ["SeatSwitchedMan", { [true] call VCR_CheckRestrictions }];

	player setVariable ["VCR_RestrictionHandlersInstalled", true];
};