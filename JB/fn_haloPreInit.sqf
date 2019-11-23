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

	if (vehicle _player != _vehicle) exitWith { false };

	if (not (lifeState _player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (not (alive _vehicle)) exitWith { false };

	true
};

OO_TRACE_DECL(HALO_GroupName) =
{
	"HALO_Group " + str (group player);
};

OO_TRACE_DECL(HALO_Start) =
{
	params ["_vehicle"];

	private _haloVehicles = player getVariable ["HALO_Vehicles", []];

	// Delete any entries based on non-existent vehicles
	for "_i" from count _haloVehicles - 1 to 0 step -1 do
	{
		private _vehicles = _haloVehicles select _i select 0;
		_vehicles = _vehicles select { alive _x };
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

		scriptName "HALO_Start";

		private _groupName = "";
		private _newGroupName = "";
		private _waitStart = -1;
		private _currentDrop = "";
		private _jumpTime = 1e30;
		private _remainingDelay = 1e30;
		private _nextMessageDelay = -1;

		while { ([player, _vehicle] call HALO_ReadyForJump) && _remainingDelay >= 0 } do
		{
			_newGroupName = call HALO_GroupName;
			if (_newGroupName != _groupName) then
			{
				_groupName = _newGroupName;

				// If this is the first member of the group in the vehicle, set the group's global HALO start time on the vehicle
				if ({ group _x == group player } count crew _vehicle == 1) then
				{
					_vehicle setVariable [_groupName, call HALO_CurrentTime, true]; // public
				};
				_waitStart = _vehicle getVariable [_groupName, call HALO_CurrentTime];
			};

			private _jumpParameters = [_vehicle] call _jumpCode;
			if (count _jumpParameters == 0) then
			{
				if (not isNil "_currentDrop") then
				{
					["HALO from this vehicle is currently disabled", 5] call JB_fnc_showBlackScreenMessage;

					_jumpTime = 1e30;
					_currentDrop = nil;
					_nextMessageDelay = 1e30;
				};
			}
			else
			{
				_jumpParameters params ["_targetDrop", "_targetPosition", "_targetDelay"];
				if (isNil "_currentDrop" || { _targetDrop != _currentDrop }) then
				{
					if (_targetDrop == "") then
					{
						["Waiting for new operation", 2] call JB_fnc_showBlackScreenMessage;
						_jumpTime = 1e30;
					}
					else
					{
						_jumpTime = (_waitStart + round _targetDelay) max ((call HALO_CurrentTime) + 7);
						[format ["HALO jump over %1", _targetDrop], 2] call JB_fnc_showBlackScreenMessage;
					};

					_currentDrop = _targetDrop;
					_nextMessageDelay = 1e30;
				};
			};

			if (not isNil "_currentDrop" && { _currentDrop != "" }) then
			{
				_remainingDelay = floor (_jumpTime - (call HALO_CurrentTime));

				switch (true) do
				{
					case (_remainingDelay <= 0):
					{
						sleep 0.5; // Anticipation
						["<t align='center' size='2'>GREEN LIGHT</t>", -1, -1, 1.0, 0.2] call BIS_fnc_dynamicText;

						if (vehicle player == player) then
						{
							player setVelocity [0, 0, 40];
							sleep 1;
							player setVelocity [0, 0, 0];
						};

						_jumpParameters params ["_targetDrop", "_targetPosition", "_targetDelay"];

						// Position is horizontally randomized +/- 5 meters
						private _dropPosition = _targetPosition vectorAdd [-5 + random 10, -5 + random 10, 0];
						private _dropDirection = (getPos _vehicle) getDir _targetPosition;

						[player, false, _dropPosition, _dropDirection] call JB_fnc_halo;
						waitUntil { vehicle player == player };
					};

					case (_remainingDelay < 6):
					{
						[_remainingDelay] spawn { [format ["<t align='center' size='2'>%1</t>", _this select 0], -1, -1, 1.0, 0.2] call BIS_fnc_dynamicText };
					};

					case (_remainingDelay < _nextMessageDelay):
					{
						[_remainingDelay, _currentDrop] call HALO_ShowStatusMessage;

						_nextMessageDelay = if (_remainingDelay > 30) then { _remainingDelay - 10 } else { _remainingDelay - 5 };
					};
				};
			};

			sleep 1;
		};
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

OO_TRACE_DECL(HALO_EjectFromParachute) =
{
	params ["_display", "_actionName", "_actionKey", "_change", "_passthrough"];

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
	};

	true
};

OO_TRACE_DECL(HALO_InstallPlayerReserveParachute) =
{
	player setVariable ["JB_HALO_Reserve", true];
	private _handler = [46, "Eject", HALO_EjectFromParachute] call JB_fnc_actionHandlerAdd;
	player setVariable ["JB_HALO_ReserveHandler", _handler];
};

OO_TRACE_DECL(HALO_UninstallPlayerReserveParachute) =
{
	[46, player getVariable "JB_HALO_ReserveHandler"] call JB_fnc_actionHandlerRemove;
	player setVariable ["JB_HALO_ReserveHandler", nil];
};