#include "..\SPM\strongpoint.h"

OO_TRACE_DECL(HALO_AddParachute) =
{
	params ["_unit"];

	_unit setVariable ["HALO_Backpack", [backpack _unit, backpackItems _unit]];

	removeBackpack _unit;
	_unit addBackpack "B_Parachute";
};

OO_TRACE_DECL(HALO_RestoreBackpack) =
{
	params ["_unit"];

	private _backpack = _unit getVariable ["HALO_Backpack", []];
	_unit setVariable ["HALO_Backpack", nil];

	if (count _backpack > 0) then
	{
		removeBackpack _unit;
		if (_backpack select 0 != "") then
		{
			_unit addBackpack (_backpack select 0);
			clearAllItemsFromBackpack _unit;
			{
				_unit addItemToBackpack _x;
			} foreach (_backpack select 1);
		};
	};
};

OO_TRACE_DECL(HALO_ShowStatusMessage) =
{
	params ["_remainingDelay", "_target"];

	titleText [format ["HALO jump over %1 in %2...", _target, [_remainingDelay, "MM:SS"] call BIS_fnc_secondsToString], "plain down", 0.3];
};

OO_TRACE_DECL(HALO_CurrentTime) =
{
	daytime * 3600; // 24 hour clock will produce problems when spanning midnight
};

OO_TRACE_DECL(HALO_ReadyForJump) =
{
	params ["_player", "_vehicle"];

	if (_player getVariable ["HALO_Cancel", false]) exitWith { false };
	if (not (lifeState _player in ["HEALTHY", "INJURED"])) exitWith { false };
	if (not (alive _vehicle)) exitWith { false };

	true
};

OO_TRACE_DECL(HALO_GroupStartName) =
{
	"HALO_Group " + str (group player);
};

OO_TRACE_DECL(HALO_GetOutHandler) =
{
	params ["_unit", "_position", "_vehicle", "_turret"];

	[_vehicle] call HALO_Stop;
};

OO_TRACE_DECL(HALO_Stop) =
{
	params ["_vehicle"];

	player setVariable ["HALO_Cancel", true];

	if (({ group _x == group player } count crew _vehicle) == 0) then
	{
		_vehicle setVariable [[] call HALO_GroupStartName, nil, true]; // public
	};
};

OO_TRACE_DECL(HALO_Start) =
{
	params ["_vehicle"];

	private _haloVehicles = player getVariable ["HALO_Vehicles", []];

	// Delete any entries based on non-existent vehicles
	for "_i" from count _haloVehicles - 1 to 0 step -1 do
	{
		private _vehicles = _haloVehicles select _i select 0;
		for "_j" from count _vehicles - 1 to 0 step -1 do
		{
			if (not alive (_vehicles select _j)) then { _vehicles deleteAt _j };
		};
		if (count _vehicles == 0) then { _haloVehicles deleteAt _i };
	};

	private _match = [];
	{
		if (_vehicle in (_x select 0)) exitWith { _match = _x };
	} forEach _haloVehicles;

	if (count _match == 0) exitWith {};

	[_vehicle, _match select 1] spawn
	{
		params ["_vehicle", "_jumpCode"];

		scriptName "spawnHALO_Start";

		player setVariable ["HALO_Cancel", nil];

		// The time that the player started waiting is either his own time of getting into the HALO vehicle
		// or the time of the earliest squad member who got in.  This allows groups to jump together.

		private _groupStartName = [] call HALO_GroupStartName;
		private _groupStart = _vehicle getVariable [_groupStartName, -1];
		private _waitStart = [] call HALO_CurrentTime;

		if (_groupStart == -1) then
		{
			_vehicle setVariable [_groupStartName, _waitStart, true]; // public
		}
		else
		{
			_waitStart = _groupStart;
		};

		private _targetData = [_vehicle] call _jumpCode;
		private _targetDrop = _targetData select 0;
		private _targetPosition = _targetData select 1;
		private _targetDelay = _targetData select 2;

		private _jumpTime = _waitStart + round _targetDelay;
		private _remainingDelay = _jumpTime - ([] call HALO_CurrentTime);
		_remainingDelay = _remainingDelay max 7; // Ensure that we at least get the countdown

		if (_targetDrop != "" && _remainingDelay < 10) then
		{
			[_remainingDelay, _targetDrop] call HALO_ShowStatusMessage;
		};

		private _nextMessageDelay = _remainingDelay;

		// If the player gets out of the vehicle and he's the last member of his group to get out, clear the group
		// start time variable.
		private _getOutHandler = player addEventHandler ["GetOutMan", HALO_GetOutHandler];

		// So long as the player is alive and in an intact HALO vehicle, keep the process going
		while { ([player, _vehicle] call HALO_ReadyForJump) } do
		{
			_targetData = [_vehicle] call _jumpCode;
			_targetDrop = _targetData select 0;
			private _currentDrop = _targetData select 0;

			while { ([player, _vehicle] call HALO_ReadyForJump) && _remainingDelay > 0 && { _targetDrop == _currentDrop } && { _targetDrop != "" } } do
			{
				if (_remainingDelay < 6) then
				{
					[format ["<t align='center' size='2'>%1</t>", round _remainingDelay], -1, -1, 0.2, 0.2] call BIS_fnc_dynamicText;
				}
				else
				{
					if (_remainingDelay < _nextMessageDelay) then
					{
						[_remainingDelay, _targetDrop] call HALO_ShowStatusMessage;

						_nextMessageDelay = if (_remainingDelay > 30) then { _remainingDelay - 10 } else { _remainingDelay - 5 };
					};

					sleep 1;
				};

				_remainingDelay = _remainingDelay - 1;

				_targetData = [_vehicle] call _jumpCode;
				_currentDrop = _targetData select 0;
			};

			if (not ([player, _vehicle] call HALO_ReadyForJump)) exitWith { };

			if (_targetDrop != "" && _targetDrop == _currentDrop) exitWith // Timer expired and player should make HALO jump
			{
				// Clear the group wait start time so that anyone who gets into the HALO vehicle after
				// the current jump has to wait the full delay.
				_vehicle setVariable [_groupStartName, nil, true]; // public

				["<t align='center' size='2'>GREEN LIGHT</t>", -1, -1, 0.2, 0.2] call BIS_fnc_dynamicText;

				if (vehicle player == player) then
				{
					player setVelocity [0, 0, 40];
					sleep 1;
					player setVelocity [0, 0, 0];
				};

				// Position is horizontally randomized +/- 5 meters
				private _dropPosition = (_targetData select 1) vectorAdd [-5 + random 10, -5 + random 10, 0];
				private _dropDirection = (getPos _vehicle) getDir (_targetData select 1);

				[player, false, _dropPosition, _dropDirection] call JB_fnc_halo;
				waitUntil { vehicle player == player };
			};

			if (_currentDrop == "") then
			{
				["Waiting for new operation", 2] call JB_fnc_showBlackScreenMessage;

				while { ([player, _vehicle] call HALO_ReadyForJump) && _currentDrop == "" } do
				{
					sleep 5;

					_targetData = [_vehicle] call _jumpCode;
					_currentDrop = _targetData select 0;
				};
			};

			if ([player, _vehicle] call HALO_ReadyForJump) then
			{
				[format ["Combat operations have moved to %1.", _currentDrop], 2] call JB_fnc_showBlackScreenMessage;
				sleep 5;

				_targetDrop = _currentDrop;

				_remainingDelay = (_targetData select 2) - (([] call HALO_CurrentTime) - _waitStart);
				_remainingDelay = round(_remainingDelay) max 7; // Give him time to get out if he doesn't want new drop target
			};
		};

		player removeEventHandler ["GetOutMan", _getOutHandler];

		// When the player exits the vehicle, don't leave a message sitting on the screen
		titleText ["", "plain down", 0.1];
	};
};

OO_TRACE_DECL(HALO_SetupClient) =
{
	private _vehicles = param [0, [], [[]]];
	private _jumpCode = param [1, {}, [{}]];

	if (count _vehicles == 0) exitWith {};

	private _haloVehicles = player getVariable ["HALO_Vehicles", []];

	if (count _haloVehicles == 0) then
	{
		player addEventHandler ["GetInMan", { if ((_this select 1) == "cargo") then { [_this select 2] call HALO_Start } }];
	};

	_haloVehicles pushback [_vehicles, _jumpCode];
	player setVariable ["HALO_Vehicles", _haloVehicles];
};

OO_TRACE_DECL(HALO_InstallPlayerReserveParachute) =
{
	player setVariable ["JB_HALO_Reserve", true];
	_handler = (findDisplay 46) displayAddEventHandler ["KeyDown",
		{
			params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

			private _override = false;

			if (_key in actionKeys "GetOver") then
			{
				private _animationState = animationState player;
				if (animationState player == "para_pilot") then
				{
					private _parachute = vehicle player;
					moveOut player;
					[_parachute] spawn
					{
						sleep 3;
						deleteVehicle (_this select 0);
					};

					if (player getVariable["JB_HALO_Reserve", false]) then
					{
						player addBackpack "B_Parachute";
						player setVariable ["JB_HALO_Reserve", nil];
					}
					else
					{
						[player] call HALO_RestoreBackpack;
					};
					_override = true;
				};
			};

			_override;
		}];
	player setVariable ["JB_HALO_ReserveHandler", _handler];
};

OO_TRACE_DECL(HALO_UninstallPlayerReserveParachute) =
{
	(findDisplay 46) displayRemoveEventHandler ["KeyDown", player getVariable "JB_HALO_ReserveHandler"];
	player setVariable ["JB_HALO_ReserveHandler", nil];
};