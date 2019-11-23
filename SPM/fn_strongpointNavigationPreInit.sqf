/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Nav_DeleteConnection) =
{
	params ["_intersections", "_fromIndex", "_toIndex"];

	private _connectionsFrom = (_intersections select _fromIndex) select 1;
	_connectionsFrom deleteAt (_connectionsFrom find _toIndex);

	private _connectionsTo = (_intersections select _toIndex) select 1;
	_connectionsTo deleteAt (_connectionsTo find _fromIndex);

	if (count _connectionsFrom == 1) then
	{
		[_intersections, _fromIndex, _connectionsFrom select 0] call SPM_Nav_DeleteConnection;
	};

	if (count _connectionsTo == 1) then
	{
		[_intersections, _toIndex, _connectionsTo select 0] call SPM_Nav_DeleteConnection;
	};
};

OO_TRACE_DECL(SPM_Nav_GetIntersectionPosition) =
{
	params ["_road"];

	private _roadPosition = getPos _road;

	private _connections = roadsConnectedTo _road;
	private _connectionsData = _connections apply { [_roadPosition distanceSqr getPos _x, _x] };
	_connectionsData sort false;

	scopeName "function";
	private _intersectionPosition = [];
	{
		private _connection = _x select 1;
		private _connectionPosition = getPos _connection;
		private _toConnection = _connectionPosition vectorDiff _roadPosition;
		private _toConnectionDistance = vectorMagnitude _toConnection;
		private _toConnectionNormal = _toConnection vectorMultiply (1 / _toConnectionDistance);
		{
			if (_x != _connection) then
			{
				private _toNeighbor = (getPos _x) vectorDiff _roadPosition;
				private _toNeighborDot = _toConnectionNormal vectorDotProduct _toNeighbor;
				if (_toNeighborDot > 0 && _toNeighborDot < _toConnectionDistance) then
				{
					_intersectionPosition = _roadPosition vectorAdd (_toConnectionNormal vectorMultiply _toNeighborDot);
					breakTo "function";
				};
			};
		} forEach _connections;
	} forEach _connectionsData;

	if (count _intersectionPosition == 0) exitWith { _roadPosition };

	_intersectionPosition
};

OO_TRACE_DECL(SPM_Nav_EndOfRun) =
{
	params ["_prev", "_next", "_position", "_radius"];

	private _run = [_prev, _next, _position, _radius] call SPM_Nav_RoadRun;

	[_run select (count _run - 2), _run select (count _run - 1)]
};

OO_TRACE_DECL(SPM_Nav_GetConnectedIntersections) =
{
	params ["_road", "_position", "_radius"];

	private _connections = [];

	{
		private _end = [_road, _x, _position, _radius] call SPM_Nav_EndOfRun;

		if (count roadsConnectedTo (_end select 1) > 2 && { not ((_end select 1) in _connections) }) then
		{
			_connections pushBack (_end select 1);
		};
	} forEach roadsConnectedTo _road;

	_connections
};

OO_TRACE_DECL(SPM_Nav_GetIntersections) =
{
	params ["_position", "_radius"];

	private _roads = _position nearRoads _radius;
	_roads = _roads select { count roadsConnectedTo _x > 2 };

	private _intersections = _roads apply { [_x, [_x, _position, _radius] call SPM_Nav_GetConnectedIntersections] };

	// Translate connected roads to connected road indexes
	{
		_connections = _x select 1;
		{
			_connections set [_forEachIndex, _roads find _x];
		} forEach _connections;
	} forEach _intersections;

	// Remove -1 index values
	{
		_x set [1, (_x select 1) select { _x != -1 }];
	} forEach _intersections;

	// Cascade removal of intersections with only 1 connection
	{
		_connections = _x select 1;
		if (count _connections == 1) then
		{
			[_intersections, _forEachIndex, _connections select 0] call SPM_Nav_DeleteConnection;
		};
	} forEach _intersections;

	private _index = -1;
	private _renumbering = _intersections apply { if (count (_x select 1) == 0) then { -1 } else { _index = _index + 1; _index } };

	{
		_connections = _x select 1;
		{
			_connections set [_forEachIndex, _renumbering select _x];
		} forEach _connections;
	} forEach _intersections;

	for "_i" from count _intersections - 1 to 0 step -1 do
	{
		private _x = _intersections select _i;
		if (_renumbering select _i == -1) then { _intersections deleteAt _i };
	};

	{
		private _position = [_x select 0] call SPM_Nav_GetIntersectionPosition;
		_x set [0, _position];
	} forEach _intersections;

	_intersections
};

OO_TRACE_DECL(SPM_Nav_GetIntersectionInFront) =
{
	params ["_intersections", "_position", "_direction"];

	private _maxDot = -1;
	private _maxDotIndex = -1;
	{
		if (_position distanceSqr (_x select 0) > 1) then
		{
			private _toIntersection = _position vectorFromTo (_x select 0);

			private _dot = _direction vectorDotProduct _toIntersection;
			if (_dot > _maxDot) then
			{
				_maxDot = _dot;
				_maxDotIndex = _forEachIndex;
			};
		};
	} forEach _intersections;

	_maxDotIndex;
};

OO_TRACE_DECL(SPM_Nav_RoadRun) =
{
	params ["_prev", "_next", "_position", "_distance"];

	private _checkDistance = not isNil "_distance";
	private _distanceSqr = (if (_checkDistance) then { _distance ^ 2 } else { 0 });

	private _run = [_prev];
	private _roads = [];
	private _save = 0;

	while { true } do
	{
		_run pushBack _next;

		if (_checkDistance && { _next distanceSqr _position > _distanceSqr }) exitWith { };

		_roads = roadsConnectedTo _next;

		if (count _roads != 2) exitWith { };

		_save = _next;
		_next = _roads select (if (_roads select 0 == _prev) then { 1 } else { 0 });
		_prev = _save;
	};

	_run
};

OO_TRACE_DECL(SPM_Nav_NeighborDirections) =
{
	params ["_road"];

	private _intersection = [_road] call SPM_Nav_GetIntersectionPosition;

	private _neighbors = roadsConnectedTo _road;
	_neighbors = _neighbors apply { [_x, (roadsConnectedTo _x) select { _x != _road }] };
	_neighbors = _neighbors apply { [_x select 0, if (count (_x select 1) == 1) then { _intersection getDir (_x select 1 select 0) } else { _intersection getDir (_x select 0) }] };

	_neighbors
};

OO_TRACE_DECL(SPM_Nav_FollowRoute) =
{
	params ["_prev", "_next", "_direction", "_length", ["_blacklist", [], [[]]], ["_intersections", [], [[]]]];

	private _run = [_prev, _next] call SPM_Nav_RoadRun;
	private _beforeJunction = (_run select (count _run - 2));
	private _junction = (_run select (count _run - 1));

	private _violatedBlacklist = false;
	{
		if ([getPos _junction, _x] call SPM_Util_PositionInArea) exitWith { _violatedBlacklist = true };
	} forEach _blacklist;

	if (_violatedBlacklist) exitWith { [] };

	private _runLength = (_run select 0) distance _junction;

	if (_runLength > _length) exitWith { _run }; // Good route

	if (count roadsConnectedTo _junction < 3) exitWith { [] }; // Dead end

	if (_junction in _intersections) exitWith { [] }; // Looped

	private _intersectionPosition = [_junction] call SPM_Nav_GetIntersectionPosition;

	private _intersectionRoadNeighbors = (roadsConnectedTo _junction) - [_beforeJunction];
	_intersectionRoadNeighbors = _intersectionRoadNeighbors apply { [_x, [_junction, _x, _intersectionPosition, 30] call SPM_Nav_RoadRun] };
	_intersectionRoadNeighbors = _intersectionRoadNeighbors apply { [_x select 0, _x select 1 select (count (_x select 1) - 1)] };
	private _neighborDirections = _intersectionRoadNeighbors apply { [_x select 0, _intersectionPosition getDir (_x select 1)] };
	_neighborDirections = _neighborDirections apply { [floor ([_direction, _x select 1] call SPM_Util_AngleBetweenDirections), _x select 0] };
	_neighborDirections = _neighborDirections select { _x select 0 < 90 };
	_neighborDirections sort true;

	_intersections pushBack _junction;

	private _continuation = [];
	{
		_continuation = [_junction, _x select 1, _direction, _length - _runLength, _blacklist, _intersections] call SPM_Nav_FollowRoute;
		if (count _continuation > 0) exitWith {};
		_continuation = [];
	} forEach _neighborDirections;

	_intersections deleteAt (count _intersections - 1);

	if (count _continuation == 0) exitWith { [] };

	_run append _continuation;

	_run
};