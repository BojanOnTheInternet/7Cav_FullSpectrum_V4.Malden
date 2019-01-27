#include "..\SPM\strongpoint.h"
#include "op.h"

if (isServer || not hasInterface) then
{
	OP_S_SelectMissionAtPosition =
	{
		params ["_position"];

		private _missions = [];

		private _parameters = [_position, _missions];
		private _code =
		{
			params ["_position", "_missions"];
			if ([_position, [OO_GET(_x,Strongpoint,ActivityRadius), OO_GET(_x,Strongpoint,Position)]] call SPM_Util_PositionInArea) then { _missions pushBack _x };
			false
		};
		OO_FOREACHINSTANCE(Mission,_parameters,_code);

		if (count _missions == 0) exitWith { [OP_SELECTION_NULL] remoteExec ["OP_C_SetSelection", remoteExecutedOwner] };

		// Find the strongpoint with the smallest radius
		_missions = _missions apply { [OO_GET(_x,Strongpoint,ActivityRadius), _x] };
		_missions sort true;

		private _operation = _missions select 0 select 1;
		private _selection = [OO_REFERENCE(_operation), OO_GET(_operation,Strongpoint,Position), OO_GET(_operation,Strongpoint,ActivityRadius), OO_GET(_operation,Strongpoint,Name), if (isServer) then { objNull } else { player }];
		[_selection] remoteExec ["OP_C_SetSelection", remoteExecutedOwner];
	};

	// When an mission is stopped, notify anyone that has it selected that the mission is gone
	OP_S_NotifyRemovedMission =
	{
		params ["_mission"];

		{
			private _selection = [_x] call OP_GetPlayerSelection;
			private _reference = _selection select 0;
			if (OO_ISEQUAL(_reference,_mission)) then
			{
				_selection set [0, OO_NULL];	// No mission reference
				_selection set [3, ""];			// No mission name
				[_selection] remoteExec ["OP_C_SetSelection", _x];
			};
		} forEach allPlayers;
	};
};

if (not hasInterface) exitWith {};

OO_TRACE_DECL(OP_C_SetSelection) =
{
	params ["_selection"];

	player setVariable ["OP_Selection", _selection, true];

	deleteMarkerLocal "OP_SelectionArea";
	deleteMarkerLocal "OP_SelectionName";

	_selection params ["_operation", "_position", "_radius", "_name", "_host"];

	if (_radius > 0) then
	{
		private _marker = createMarkerLocal ["OP_SelectionArea", _position];
		_marker setMarkerShapeLocal "ellipse";
		_marker setMarkerBrushLocal "fdiagonal";
		_marker setMarkerColorLocal ([_host] call OP_HostColor);
		_marker setMarkerSizeLocal [_radius, _radius];
		private _marker = createMarkerLocal ["OP_SelectionName", _position];
		_marker setMarkerTextLocal _name;
		_marker setMarkerColorLocal "colorblack";
	};
};

OO_TRACE_DECL(OP_GetKnownOperations) =
{
	params ["_host"];

	private _knownOperationsAllHosts = player getVariable "OP_KnownOperationsAllHosts";
	if (isNil "_knownOperationsAllHosts") then
	{
		_knownOperationsAllHosts = [];
		player setVariable ["OP_KnownOperationsAllHosts", _knownOperationsAllHosts];
	};

	private _knownOperations = _knownOperationsAllHosts select { (_x select 0) == _host };

	if (count _knownOperations == 1) exitWith { _knownOperations select 0 select 1 };

	private _operation = [_host, []];
	_knownOperationsAllHosts pushBack _operation;

	_operation select 1;
};

OO_TRACE_DECL(OP_HostColor) =
{
	params ["_host"];

	private _color = nil;
	if (_host isEqualType objNull && { not isNull _host }) then { _color = _host getVariable "OP_HostColor" };
	if (isNil "_color") then { _color = "colorgreen" };

	_color
};

OO_TRACE_DECL(OP_C_SetKnownOperations) =
{
	params ["_operations"]; // [[strongpoint-ref, position, radius, name], ...]

	private _host = [remoteExecutedOwner] call SPM_Util_GetOwnerPlayer;

	// Get the caller's operations
	private _knownOperations = [_host] call OP_GetKnownOperations;

	// Delete the markers for those operations
	while { count _knownOperations > 0 } do
	{
		private _operation = _knownOperations deleteAt 0;
		deleteMarkerLocal (_operation select 0);
		deleteMarkerLocal (_operation select 1);
	};

	// Figure out the color of the caller's operations.
	private _color = [_host] call OP_HostColor;

	// Create the markers for the caller's operations and put them in the array of known operations (which is specific to the caller)
	{
		_x params ["_operation", "_position", "_radius", "_name"];

		private _areaMarker = createMarkerLocal [format ["OP_KnownOperation_%1_%2_Area", owner _host, _forEachIndex], _position];
		_areaMarker setMarkerShapeLocal "ellipse";
		_areaMarker setMarkerColorLocal _color;
		_areaMarker setMarkerAlphaLocal 0.6;
		_areaMarker setMarkerBrushLocal "fdiagonal";
		_areaMarker setMarkerSizeLocal [_radius, _radius];
		private _nameMarker = createMarkerLocal [format ["OP_KnownOperation_%1_%2_Name", owner _host, _forEachIndex], _position];
		_nameMarker setMarkerTextLocal _name;
		_nameMarker setMarkerColorLocal "colorblack";
		_nameMarker setMarkerAlphaLocal 0.5;

		_knownOperations pushBack [_areaMarker, _nameMarker];
	} forEach _operations;
};

OP_SelectedHost = objNull;
OP_ControlShift = false;
OP_Dragging = false;

OP_MouseToWorld =
{
	params ["_position"];

	(((finddisplay 312) displayCtrl 50) ctrlMapScreenToWorld _position) + [0];
};

OP_SelectArea =
{
	private _center = [OP_MouseDownPosition] call OP_MouseToWorld;
	private _radius = 0;
	private _marker = "";
	private _frameNumber = 0;

	private _color = [OP_SelectedHost] call OP_HostColor;

	while { OP_Dragging && OP_ControlShift } do
	{
		if (diag_frameNo != _frameNumber) then
		{
			_frameNumber = diag_frameNo;

			if (getMousePosition distance OP_MouseDownPosition > 0.002) then { OP_MouseClick = false }; // A mouse click is a down/up without movement

			private _position = [getMousePosition] call OP_MouseToWorld;
			_radius = vectorMagnitude (_position vectorDiff _center);

			if (_radius > 10) then
			{
				if (_marker == "") then
				{
					_marker = createMarkerLocal ["OP_SelectionArea", _center];
					_marker setMarkerShapeLocal "ellipse";
					_marker setMarkerColorLocal _color;
				};
				_marker setMarkerSizeLocal [_radius, _radius];
			}
			else
			{
				if (_marker != "") then
				{
					deleteMarkerLocal _marker;
					_marker = "";
				};
			}
		};
	};

	if (not OP_ControlShift && _marker != "") then
	{
		deleteMarkerLocal _marker;
	}
	else
	{
		private _selectedOperation = [OP_SELECTION_NULL select 0, getMarkerPos "OP_SelectionArea", (getMarkerSize "OP_SelectionArea") select 0, markerText "OP_SelectionArea", OP_SelectedHost];
		player setVariable ["OP_Selection", _selectedOperation, true];
	};
};

OP_InstallHandlers =
{
	(findDisplay 312) displayAddEventHandler ["KeyDown",
		{
			params ["_control", "_key", "_isShift", "_isControl", "_isAlt"];

			private _override = false;

			switch (_key) do
			{
				case 0x1D; // LCTRL
				case 0x9D: // RCTRL
				{
					OP_ControlShift = _isShift;
				};

				case 0x2A; // RSHIFT
				case 0x36: // RSHIFT
				{
					OP_ControlShift = _isControl;
				};

				default { OP_ControlShift = false };
			};

			_override;
		}];

	(findDisplay 312) displayAddEventHandler ["KeyUp",
		{
			params ["_control", "_key", "_isShift", "_isControl", "_isAlt"];

			OP_ControlShift = _isShift && _isControl && not (_key in [0x1D, 0x9D, 0x2A, 0x36]);

			false;
		}];


	(finddisplay 312) displayAddEventHandler ["MouseButtonDown",
	{
		params ["_control", "_button", "_x", "_y", "_isShift", "_isControl", "_isAlt"];

		if (_button != 0) exitWith {}; // Left mouse button only

		if (not OP_ControlShift) exitWith {}; // We only care about mouse actions with CTRL+SHIFT active

		OP_MouseDownPosition = [_x, _y];
		OP_MouseClick = true;

		deleteMarkerLocal "OP_SelectionArea";
		deleteMarkerLocal "OP_SelectionName";
		player setVariable ["OP_Selection", OP_SELECTION_NULL, true];

		OP_Dragging = true;
		[] spawn OP_SelectArea;
	}];

	(finddisplay 312) displayAddEventHandler ["MouseButtonUp",
	{
		params ["_control", "_button", "_x", "_y", "_isShift", "_isControl", "_isAlt"];

		if (_button != 0) exitWith {}; // Left mouse button only

		OP_Dragging = false;

		if (OP_ControlShift && OP_MouseClick) then
		{
			[[OP_MouseDownPosition] call OP_MouseToWorld] remoteExec ["OP_S_SelectMissionAtPosition", if (isNull OP_SelectedHost) then { 2 } else { OP_SelectedHost }]; // Host will reply via remoteExec to OP_C_SetSelection
		};
	}];
};