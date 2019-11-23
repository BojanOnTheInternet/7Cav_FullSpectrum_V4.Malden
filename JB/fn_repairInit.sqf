#define IDC_OK 1
#define IDC_CANCEL 2

#define REPAIR_DISPLAY 2800
#define SYSTEMS_LIST 1200
#define FOOTER_BAND 1300

// Given a vehicle class and a system name, return a list of hitpoint indices and the number of points allocated to each
// The format of the return is [[index, [system-name, points]], [index, [system-name, points]], ...]
JBR_GetSystemDescriptor =
{
	params ["_vehicle", "_systemName"];

	private _descriptor = [];
	if (typeOf _vehicle != "" && _systemName != "") then
	{
		{
			if (_x select 0 == _systemName) then
			{
				_descriptor pushBack [_forEachIndex, _x];
			};
		} forEach ([_vehicle] call JBR_GetVehicleComponents);
	};

	_descriptor;
};

#define END_OF_SEQUENCE "AinvPknlMstpSnonWnonDnon_medicEnd"

JBR_RunAnimationSequence =
{
	private _animations =
	[
		"AinvPknlMstpSnonWnonDnon_medic_1",
		"AinvPknlMstpSnonWnonDnon_medicUp1",
		"AinvPknlMstpSnonWnonDnon_medicUp3",
		"AinvPknlMstpSnonWnonDnon_medicUp5",
		"AinvPknlMstpSnonWnonDr_medicUp1",
		"AinvPknlMstpSnonWnonDr_medicUp4",
		"Acts_carFixingWheel",
		"Acts_carFixingWheel"
	];

	if (random 1 < 0.1) then { _animations pushBack "InBaseMoves_repairVehicleKnl" };

	while { count _animations > 0 } do
	{
		player playMove (_animations deleteAt floor random count _animations);
	};
	player playMove END_OF_SEQUENCE;
};

JBR_GetSystemDamage =
{
	params ["_vehicle", "_descriptor"];

	{
		_x set [2, _vehicle getHitIndex (_x select 0)];
	} forEach _descriptor;
};

JBR_PointsSystemDamageToRepair =
{
	params ["_descriptor", "_targetDamagePC"];

	private _totalPoints = 0;
	{
		private _damagePC = (_x select 2) - _targetDamagePC;
		if (_damagePC > 0) then
		{
			_totalPoints = _totalPoints + _damagePC * ((_x select 1) select 1);
		};
	} forEach _descriptor;

	_totalPoints;
};

JBR_GetSystemRepairProfile =
{
	private _engineer = param [0, objNull, [objNull]];
	private _vehicle = param [1, objNull, [objNull]];
	private _systemName = param [2, "", [""]];

	if (_systemName == "") exitWith { [] };

	private _repairProfile = _engineer getVariable ["JBR_RepairProfile", []];
	if (count _repairProfile == 0) exitWith { [] };

	[_engineer, _vehicle, _systemName] call (_repairProfile select 0);
};

JBR_ContinueRepairs =
{
	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (player distance JBR_Vehicle > (sizeOf (typeOf JBR_Vehicle)) / 2) exitWith { false };

	if (not alive JBR_Vehicle) exitWith { false };

	true;
};

JBR_RepairSystemStop =
{
	JBR_InterruptRepair = true;
};

// How long one repair cycle lasts (seconds)
#define REPAIR_INTERVAL 2

JBR_RepairSystem =
{
	JBR_RepairsInProgress = true;

	_this spawn
	{
		params ["_systemIndex"];

		scriptName "JBR_RepairSystem";

		disableSerialization;

		private _display = findDisplay REPAIR_DISPLAY;
		private _systemsList = _display displayCtrl SYSTEMS_LIST;
		private _footerBand = _display displayCtrl FOOTER_BAND;

		private _systemName = (JBR_VehicleSystems select _systemIndex) select 0;

		// Get the vehicle system repair descriptor
		private _descriptor = [JBR_Vehicle, _systemName] call JBR_GetSystemDescriptor;

		// Find out how much damage is on each component
		[JBR_Vehicle, _descriptor] call JBR_GetSystemDamage;

		// Get the player's profile for repairing this vehicle's system
		private _repairProfile = [player, JBR_Vehicle, _systemName] call JBR_GetSystemRepairProfile;

		private _knowsSystem = _repairProfile select 0;
		private _systemRepairPPS = _repairProfile select 1;
		private _systemRepairTargetPC = (_repairProfile select 2) max 0;
		private _systemRepairMessage = _repairProfile select 3;
		private _canRepair = _repairProfile select 4;

		_footerBand ctrlSetText _systemRepairMessage;

		if (!_canRepair) exitWith
		{
			JBR_RepairsInProgress = nil;
		};

		player action ["SwitchWeapon", player, player, -1];
		[] call JBR_RunAnimationSequence;

		sleep 2; // Repair prep time

		private _componentIndex = 0;
		private _componentPoints = 0;
		private _componentDamage = 0;
		private _componentTargetDamage = 0;

		{
			if (not ([] call JBR_ContinueRepairs)) exitWith {};

			_componentIndex = _x select 0;
			_componentPoints = (_x select 1) select 1;
			_componentDamage = _componentPoints * (_x select 2);
			_componentTargetDamage = _componentPoints * _systemRepairTargetPC;

//			player sidechat format ["Repairing component %1", (_x select 1) select 0];

			_componentRepairTime = (_componentDamage - _componentTargetDamage) / _systemRepairPPS;
//			player sidechat format ["_componentRepairTime: %1", _componentRepairTime];
			while { _componentRepairTime > 0 && isNil "JBR_InterruptRepair" } do
			{
				if (not ([] call JBR_ContinueRepairs)) exitWith {};

				if (!isNil "_repairRestrictions" && { !([JBR_Vehicle, _systemName] call _repairRestrictions) }) exitWith {};

				if (animationState player == END_OF_SEQUENCE) then
				{
					[] call JBR_RunAnimationSequence;
				};

				_repairStep = _componentRepairTime min REPAIR_INTERVAL;
//				player sidechat format ["_repairStep: %1", _repairStep];

				[JBR_Vehicle, _descriptor] call JBR_GetSystemDamage;
				private _systemRepairTime = ([_descriptor, _systemRepairTargetPC] call JBR_PointsSystemDamageToRepair) / _systemRepairPPS;

				_systemsList lnbSetText [[_systemIndex, 2], [_systemRepairTime, "MM:SS"] call BIS_fnc_secondsToString];

				// Make repairs
				[JBR_Vehicle, _componentIndex, _repairStep / (_componentPoints / _systemRepairPPS), _systemRepairTargetPC] remoteExec ["JBR_R_RepairSystemDamage", JBR_Vehicle];

				sleep _repairStep;

				_componentRepairTime = _componentRepairTime - _repairStep;
				_systemRepairTime = _systemRepairTime - _repairStep;
			};

		} forEach _descriptor;

		_systemsList lnbSetText [[_systemIndex, 2], ""];
		_footerBand ctrlSetText "";

		// If we can't get into our final pose because a long animation is running, interrupt it with switchMove
		player playMoveNow "amovpknlmstpsnonwnondnon";
		[{ animationState player == "amovpknlmstpsnonwnondnon" }, 2.0] call JB_fnc_timeoutWaitUntil;
		if (animationState player != "amovpknlmstpsnonwnondnon") then { [player, "amovpknlmstpsnonwnondnon"] remoteExec ["switchMove", 0] };

		JBR_InterruptRepair = nil;
		JBR_RepairsInProgress = nil;
	};
};

JBR_InspectVehicleCondition =
{
	params ["_vehicle"];

	if (vehicle player != player) exitWith { false };

	if (not alive _vehicle) exitWith { false };

	if (locked _vehicle in [2, 3]) exitWith { false };

	if (side _vehicle getFriend side player < 0.6) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	private _repairProfile = player getVariable ["JBR_RepairProfile", []];

	if (count _repairProfile == 0) exitWith { false };

	[player, _vehicle] call (_repairProfile select 1);
};

JBR_InspectVehicle =
{
	JBR_Vehicle = param [0, objNull, [objNull]];

	(findDisplay 46) createDisplay "JBR_Repair";
	waitUntil { not isNull (findDisplay REPAIR_DISPLAY) };

	call CLIENT_DisableActionMenu;

	disableSerialization;
	private _display = findDisplay REPAIR_DISPLAY;
	private _systemsList = _display displayCtrl SYSTEMS_LIST;

	JBR_VehicleSystems = [typeOf JBR_Vehicle] call JBR_GetSystems;

	lbClear _systemsList;
	{
		_systemsList lnbAddRow [_x select 0];
		[_x, _forEachIndex] call JBR_UpdateSystemRow;
	} forEach JBR_VehicleSystems;

	[_display] spawn
	{
		params ["_display"];

		scriptName "JBR_InspectVehicle";

		disableSerialization;

		while { not isNull _display && lifeState player in ["HEALTHY", "INJURED"] } do
		{
			{
				[_x, _forEachIndex] call JBR_UpdateSystemRow;
			} forEach JBR_VehicleSystems;

			sleep 1;
		};

		if (not isNull _display) then { _display closeDisplay IDC_CANCEL };
	};
};

 // [[systemName, [component-index, component-index, ...]], [systemName, [component-index, component-index, ...]], ...]
JBR_GetSystems =
{
	private _systems = [];
	{
		_systemName = _x select 0;

		if (_systemName != "") then
		{
			private _profile = [player, JBR_Vehicle, _systemName] call JBR_GetSystemRepairProfile;
			if (_profile select 0) then
			{
				_systemIndex = [_systems, _systemName] call BIS_fnc_findInPairs;
				if (_systemIndex == -1) then
				{
					_systems pushBack [_systemName, [_forEachIndex]];
				}
				else
				{
					_system = _systems select _systemIndex;
					(_system select 1) pushBack _forEachIndex;
				};
			};
		};
	} forEach ([JBR_Vehicle] call JBR_GetVehicleComponents);

	_systems;
};

JBR_UpdateSystemRow =
{
	params ["_system", "_systemIndex"];

	private _systemDamage = 0;
	{
		_systemDamage = _systemDamage + (JBR_Vehicle getHitIndex _x);
	} forEach (_system select 1);
	_systemDamage = _systemDamage / (count (_system select 1));

	_description = "";
	if (_systemDamage > 0.01) then { _description = "bent" };
	if (_systemDamage > 0.33) then { _description = "damaged" };
	if (_systemDamage > 0.66) then { _description = "disabled" };
	if (_systemDamage > 0.99) then { _description = "destroyed" };

	((findDisplay REPAIR_DISPLAY) displayCtrl SYSTEMS_LIST) lnbSetText [[_systemIndex, 1], _description];
};

JBR_RepairSystemsKeyDown =
{
	params ["_control", "_keyCode", "_shiftKey", "_controlKey", "_altKey"];

	private _handled = false;

	switch (_keyCode) do
	{
		case 57: // space
		{
			if (not _shiftKey && not _controlKey && not _altKey) then
			{
				if (isNil "JBR_RepairsInProgress") then
				{
					private _systemIndex = lbCurSel _control;
					if (_systemIndex != -1) then
					{
						[_systemIndex] call JBR_RepairSystem;
					};
				}
				else
				{
					[] call JBR_RepairSystemStop;
				};
				_handled = true;
			};
		};

		default
		{
		};
	};

	_handled
};

JBR_RepairUnload =
{
	params ["_dialog", "_exitCode"];

	if (not isNil "JBR_RepairsInProgress") then
	{
		[] call JBR_RepairSystemStop;
	};

	call CLIENT_EnableActionMenu;
};

JBR_RepairDoneAction =
{
	params ["_display"];

	(findDisplay REPAIR_DISPLAY) closeDisplay IDC_OK;
};

JBR_SetupActions =
{
	player addAction ["<t color='#FFFF99'>Repair vehicle</t>", { [cursorObject] call JBR_InspectVehicle }, [], 0, false, true, "", "getCursorObjectParams select 2 <= 2 && { [cursorObject] call JBR_InspectVehicleCondition }"];
};

private _unit = param [0, objNull, [objNull]];
private _repairProfile = param [1, [], [[]]];

_unit setVariable ["JBR_RepairProfile", _repairProfile];

[] call JBR_SetupActions;
player addEventHandler ["Respawn", { [] call JBR_SetupActions }];