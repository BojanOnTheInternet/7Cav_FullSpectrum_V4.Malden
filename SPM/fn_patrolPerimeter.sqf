/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

SPM_PerimeterBuildingPatrolComplete =
{
	params ["_buildingTask", "_perimeterTask"];

	private _group = [_perimeterTask] call SPM_TaskGetObject;

	[leader _group, units _group, _perimeterTask] call SPM_GoToNextPerimeterPoint;
};

SPM_GoToNextPerimeterPoint =
{
	params ["_leader", "_units", "_task"];

	private _parameters = [_task, "Parameters", []] call SPM_TaskGetValue;
	private _group = _parameters select 0;
	private _center = _parameters select 1;
	private _minRadius = _parameters select 2;
	private _maxRadius = _parameters select 3;
	private _clockwise = _parameters select 4;
	private _minDistance = _parameters select 5;
	private _maxDistance = _parameters select 6;
	private _checkRadius = _parameters select 7;
	private _visit = _parameters select 8;
	private _enter = _parameters select 9;
	private _loiterChance = _parameters select 10;

	private _state = [_task, "State", []] call SPM_TaskGetValue;
	private _angleCovered = _state select 0;
	private _consideredBuildings = _state select 1;

	if (_angleCovered > 360 || { ([_task] call SPM_TaskGetState) == -1  }) exitWith
	{
		[_task] call SPM_TaskComplete;
	};

	private _position = getPos _leader;
	private _inVehicle = { vehicle _x != _x } count _units > 0;

	if (_consideredBuildings || _inVehicle) then
	{
		private _radius = _minRadius + random (_maxRadius - _minRadius);
		private _distance = _minDistance + random (_maxDistance - _minDistance);

		private _circumference = 6.283 * _radius;
		private _step = 360 * (_distance / _circumference);

		private _angle = _center getDir _position;
		_angle = if (_clockwise) then { _angle + _step } else { _angle - _step };

		private _waypointPosition = _center vectorAdd ([[0, _radius, 0], _angle] call SPM_Util_RotatePosition2D);
		private _loiter = false;

		if (_inVehicle) then
		{
			if (random 1 < _loiterChance) then
			{
				_loiter = true;
			};

			private _totalAngle = _step;
			while { true } do
			{
				private _houses = nearestObjects [_waypointPosition, ["HouseBase"], 20];
				if (count _houses == 0) exitWith {};

				_angle = if (_clockwise) then { _angle + _step } else { _angle - _step };
				_totalAngle = _totalAngle + _step;

				if (_totalAngle > 360) exitWith {};

				_waypointPosition = _center vectorAdd ([[0, _radius, 0], _angle] call SPM_Util_RotatePosition2D);
			};
		};

		_waypointPosition = [_waypointPosition, _center, _maxRadius * 0.2] call SPM_Util_KeepOutOfWater;

		_state set [0, _angleCovered + _step];
		_state set [1, false];

		private _waypoint = [_group, _waypointPosition] call SPM_AddPatrolWaypoint;
		_waypoint setWaypointType "move";
		_waypoint setWaypointCompletionRadius (sizeOf typeOf vehicle _leader);
		if (_loiter) then { _waypoint setWaypointTimeout [10, 20, 30] };
		[_waypoint, SPM_GoToNextPerimeterPoint, _task] call SPM_AddPatrolWaypointStatements;
	}
	else
	{
		_state set [1, true];

		private _buildings = nearestObjects [_position, ["HouseBase"], _checkRadius];
		_buildings = _buildings select { random 1 < _visit };
		_buildings = _buildings apply { [_x, random 1 < _enter] };

		private _buildingTask = [_group, _buildings] call SPM_fnc_patrolBuildings;
		if (([_buildingTask] call SPM_TaskGetState) == 0) then
		{
			[_buildingTask, SPM_PerimeterBuildingPatrolComplete, _task] call SPM_TaskOnComplete;
		}
		else
		{
			[leader _group, units _group, _task] call SPM_GoToNextPerimeterPoint;
		};
	};
};

private _group = _this select 0;
private _center = _this select 1;
private _minRadius = _this select 2;
private _maxRadius = _this select 3;
private _clockwise = param [4, true, [true]];
private _minStep = param [5, 30, [0]];
private _maxStep = param [6, 45, [0]];
private _checkRadius = param [7, _maxRadius / 10, [0]];
private _visit = param [8, 1, [0]];
private _enter = param [9, 1, [0]];
private _loiterChance = param [10, 0.3, [0]];

private _task = [_group] call SPM_TaskCreate;

[_task, "Parameters", [_group, _center, _minRadius, _maxRadius, _clockwise, _minStep, _maxStep, _checkRadius, _visit, _enter, _loiterChance]] call SPM_TaskSetValue;
[_task, "State", [0, true]] call SPM_TaskSetValue;

[leader _group, units _group, _task] call SPM_GoToNextPerimeterPoint;

_task
