private _state = param [0, "", [""]];

if (_state == "init") then
{
	Repair_EOD_GetRepairProfile =
	{
		params ["_engineer", "_vehicle", "_systemName"];

		if (not ([_engineer, _vehicle] call Repair_EOD_CanRepairVehicle)) exitWith { [false, ""] };

		// Don't allow repairs on anything but wheels on cars
		if ((toLower _systemName) find "wheel" == -1 && _vehicle isKindOf "Car") exitWith { [false, ""] };

		// Don't allow repairs on other systems without a toolkit
		if ((toLower _systemName) find "wheel" == -1 && { (not ("ToolKit" in (backpackItems player))) }) exitWith
		{
			[true, 0, 0, format ["%1 repairs require a Toolkit", _systemName], false];
		};

		private _repairPPS = 1.0;
		private _targetPC = 0.4;
		private _message = "";

		{
			switch (_x getVariable ["REPAIR_ServiceLevel", 0]) do
			{
				case 2:
				{
					if (_targetPC > 0.0) then
					{
						_targetPC = 0.0;
						_message = format ["Using repair facilities of %1", [typeOf _x, "CfgVehicles"] call JB_fnc_displayName];
					};
				};
			};
		} forEach (nearestObjects [_engineer, ["All"], 15]);

		[true, _repairPPS, _targetPC, _message, true]
	};

	Repair_EOD_CanRepairVehicle =
	{
		params ["_engineer", "_vehicle"];

		if (_vehicle isKindOf "Car") exitWith { true };

		if ([typeOf _vehicle, TypeFilter_EODVehicles] call JB_fnc_passesTypeFilter) exitWith { true };

		false
	};

	[player, [Repair_EOD_GetRepairProfile, Repair_EOD_CanRepairVehicle]] call JB_fnc_repairInit;

	[false] execVM "scripts\fatigueToggleInit.sqf";

	[] call MAP_InitializeGeneral;
	[] call HUD_Infantry_Initialize;

	player setVariable ["SPM_BranchOfService", "infantry"];

	[player] call CLIENT_SetEODVehiclePermissions;

	addMissionEventHandler ["EachFrame", CLIENT_EOD_RevealSpottedMine];

#define BRIEFING
#ifdef BRIEFING
	private _roleDescription =
"Be sure to read both the Advances and Special Operations sections of the Briefing to understand the parameters and strategies of each.<br/><br/>
You are an explosives specialist.  Your responsibility is to dispose of dangerous ordinance identified by friendly forces, place explosive devices
such as mines in order to aid those forces, and to engage enemy infantry as necessary.<br/>";

	private _roleRecord = player createDiaryRecord ["diary", ["Explosives specialist",
		_roleDescription + "<br/>" +
		DOC_InfantryTransportAir + "<br/>" +
		DOC_InfantryTransportHALO + "<br/>" +
		DOC_Paradrop + "<br/>" +
		DOC_InfantryTransportBoat
	]];

	CLIENT_RoleLink = createDiaryLink ["Diary", _roleRecord, ""];
#endif
};

if (_state == "respawn") then
{
	player setUnitRecoilCoefficient 0.7;
	[0.4] call JB_fnc_weaponSwayInit;

	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};