/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

SPM_Map_StatusGridCellContainsLand =
{
	params ["_cell"];

	private _centerX = (_cell select 0) * 100 + 50;
	private _centerY = (_cell select 1) * 100 + 50;

	if (not surfaceIsWater [_centerX - 50, _centerY - 50, 0]) exitWith { true };
	if (not surfaceIsWater [_centerX + 50, _centerY - 50, 0]) exitWith { true };
	if (not surfaceIsWater [_centerX + 50, _centerY + 50, 0]) exitWith { true };
	if (not surfaceIsWater [_centerX - 50, _centerY + 50, 0]) exitWith { true };

	false;
};

SPM_Map_CreateStatusGrid =
{
	params ["_center", "_size"];

	private _gridLowerLeft = [(_center select 0) - (_size select 0), (_center select 1) - (_size select 1)];
	_gridLowerLeft = _gridLowerLeft apply { floor (_x / 100) };

	private _gridUpperRight = [(_center select 0) + (_size select 0), (_center select 1) + (_size select 1)];
	_gridUpperRight = _gridUpperRight apply { floor (_x / 100) };

	private _gridSize = [(_gridUpperRight select 0) - (_gridLowerLeft select 0) + 1, (_gridUpperRight select 1) - (_gridLowerLeft select 1) + 1];

	private _gridValues = [];

	for "_x" from 0 to (_gridSize select 0) - 1 do
	{
		private _row = [];
		for "_y" from 0 to (_gridSize select 1) - 1 do
		{
			_row pushBack (if (not ([[(_gridLowerLeft select 0) + _x, (_gridLowerLeft select 1) + _y]] call SPM_Map_StatusGridCellContainsLand)) then { [] } else { [false, false, false] });
		};
		_gridValues pushBack _row;
	};

	SPM_StatusGrid = [_gridLowerLeft, _gridSize, _gridValues];
};

SPM_Map_GetStatusGridCell =
{
	params ["_position"];

	[floor ((_position select 0) / 100), floor ((_position select 1) / 100)];
};

SPM_Map_GetStatusGridCellValues =
{
	params ["_cell"];

	if (isNil "SPM_StatusGrid") exitWith { [] };

	SPM_StatusGrid params ["_gridLowerLeft", "_gridSize", "_gridValues"];

	private _cellValues = [];

	if ([_cell select 0, _gridLowerLeft select 0, (_gridLowerLeft select 0) + (_gridSize select 0) - 1] call SPM_Util_InValueRange) then
	{
		if ([_cell select 1, _gridLowerLeft select 1, (_gridLowerLeft select 1) + (_gridSize select 1) - 1] call SPM_Util_InValueRange) then
		{
			private _gridX = (_cell select 0) - (_gridLowerLeft select 0);
			private _gridY = (_cell select 1) - (_gridLowerLeft select 1);
			_cellValues = (_gridValues select _gridX) select _gridY;
		};
	};

	_cellValues
};

SPM_Map_UpdateStatusGrid =
{
	{
		if (lifeState _x in ["HEALTHY", "INJURED"]) then
		{
			private _gridCell = [getPos _x] call SPM_Map_GetStatusGridCell;
			private _gridCellValues = [_gridCell] call SPM_Map_GetStatusGridCellValues;
			if (count _gridCellValues > 0) then
			{
				_gridCellValues set [1, true];
				_gridCellValues set [2, true];
			};
		};
	} forEach (allPlayers select { not (_x isKindOf "HeadlessClient_F") });
};

SPM_Map_GetStatusGridMarker =
{
	params ["_x", "_y", ["_suffix", "", [""]], ["_create", true, [true]]];

	private _markerName = format ["SPM_StatusMarker%1%2-%3", _suffix, _x, _y];

	if (getMarkerColor _markerName == "") then
	{
		if (not _create) then
		{
			_markerName = "";
		}
		else
		{
			private _gridCellCenter = [_x * 100 + 50, _y * 100 + 50, 0];
			createMarker [_markerName, _gridCellCenter];
			_markerName setMarkerShape "rectangle";
			_markerName setMarkerSize [50, 50];
			_markerName setMarkerAlpha 0.5;
		};
	};

	_markerName
};

SPM_Map_UpdateStatusDisplay =
{
	SPM_StatusGrid params ["_gridLowerLeft", "_gridSize", "_gridValues"];

	[] call SPM_Map_UpdateStatusGrid;

	private _x = 0;
	private _y = 0;
	private _gridRow = [];
	private _gridCellCenter = [];

	for "_gx" from 0 to (_gridSize select 0) - 1 do
	{
		_x = (_gridLowerLeft select 0) + _gx;

		_gridRow = _gridValues select _gx;
		for "_gy" from 0 to (_gridSize select 1) - 1 do
		{
			_y = (_gridLowerLeft select 1) + _gy;

			private _gridCell = _gridRow select _gy;

			if (count _gridCell > 0) then
			{
				_gridCell params ["_enemyFired", "_playersPresent", "_playerControlled"];
				_gridCell set [0, false];
				_gridCell set [1, false];

				if (_enemyFired) then
				{
					private _marker = [_x, _y, "Fired"] call SPM_Map_GetStatusGridMarker;
					if (markerColor _marker != "coloreast") then
					{
						_marker setMarkerColor "coloreast";
					};
				}
				else
				{
					private _marker = [_x, _y, "Fired", false] call SPM_Map_GetStatusGridMarker;
					if (_marker != "") then
					{
						deleteMarker _marker;
					};
				};


				private _markerColor = if (_playersPresent || _playerControlled) then	{ "colorwest" } else { "coloreast" };

				private _marker = [_x, _y] call SPM_Map_GetStatusGridMarker;

				if (markerColor _marker != _markerColor) then
				{
					_marker setMarkerColor _markerColor;
				};
			};
		};
	};
};

SPM_Map_DisplayGrid =
{
	private _targetPosition = getMarkerPos "Mission-Advance";
	private _targetSize = getMarkerSize "Mission-Advance";

	[_targetPosition, _targetSize] call SPM_Map_CreateStatusGrid;

	SPM_ContinueMapUpdates = true;

	while { SPM_ContinueMapUpdates } do
	{
		[] call SPM_Map_UpdateStatusDisplay;
		sleep 10;
	};
};