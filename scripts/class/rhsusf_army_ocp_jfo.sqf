private _state = param [0, "", [""]];

if (_state == "init") then
{
	player removeWeapon (primaryWeapon player);

	B_Soldier_Repair_F_GetRepairProfile =
	{
		private _engineer = param [0, objNull, [objNull]];
		private _vehicle = param [1, objNull, [objNull]];
		private _systemName = param [2, "", [""]];

		if (not ((toLower _systemName) find "wheel" >= 0) && { (not ("ToolKit" in (backpackItems player))) }) exitWith
		{
			[true, 0, 0, format ["%1 repairs require a Toolkit", _systemName], false]
		};

		private _repairPPS = 1.0;
		private _targetPC = 0.4;
		private _message = "";

		if (_vehicle isKindOf "Air") then
		{
			_repairPPS = 0.7;
		}
		else
		{
			if (_vehicle isKindOf "Ship") then
			{
				_repairPPS = 0.4;
			};
		};

		{
			switch (_x getVariable ["REPAIR_ServiceLevel", 0]) do
			{
				case 1:
				{
					if (_targetPC > 0.2) then
					{
						_targetPC = 0.2;
						_message = format ["Using repair facilities of %1", [typeOf _x, "CfgVehicles"] call JB_fnc_displayName];
					};
				};
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

	B_Soldier_Repair_F_CanRepairVehicle =
	{
		private _engineer = param [0, objNull, [objNull]];
		private _vehicle = param [1, objNull, [objNull]];

		(_vehicle isKindOf "Car" || _vehicle isKindOf "Tank" || _vehicle isKindOf "Air" || _vehicle isKindOf "Ship")
	};

	[player, [B_Soldier_Repair_F_GetRepairProfile, B_Soldier_Repair_F_CanRepairVehicle]] call JB_fnc_repairInit;

	[] call MAP_InitializeGeneral;
	[] call HUD_Infantry_Initialize;
	[] call HUD_Repair_Initialize;

	player setVariable ["SPM_BranchOfService", "support"];
	player setVariable ["JBA_LogisticsSpecialist", true, true]; //JIP

	[player] call CLIENT_SetInfantryVehiclePermissions;
	{
		player setVariable [_x, [[TypeFilter_LogisticsVehicles, [], {}], [TypeFilter_All, [VPC_UnlessOccupied], {}]] + (player getVariable _x)];
		player setVariable [_x, [[TypeFilter_BaseServiceVehicles, [], {}]] + (player getVariable _x)];
	} forEach ["VP_Driver"];
};

if (_state == "respawn") then
{
	player setUnitRecoilCoefficient 1.0;
	[1.0] call JB_fnc_weaponSwayInit;
	player enableFatigue true;

	player setUnitTrait ["engineer", false];

	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};