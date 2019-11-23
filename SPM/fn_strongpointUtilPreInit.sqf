/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Util_GetOwnerPlayer) =
{
	params ["_owner"];

	private _player = objNull; // Server (_owner == 2) returns objNull
	{
		if ((_x getVariable ["CLIENT_Owner", objNull]) == _owner) exitWith { _player = _x };
	} forEach allPlayers;

	_player
};

#define OO_TRACE_DECL(name) name

SPM_Util_MessageReceivers = [{ systemchat (_this select 0) }];

OO_TRACE_DECL(SPM_Util_PushMessageReceiver) =
{
	params ["_receiver"];

	SPM_Util_MessageReceivers pushBack _receiver;
};

OO_TRACE_DECL(SPM_Util_PopMessageReceiver) =
{
	params ["_receiver"];

	SPM_Util_MessageReceivers deleteAt (count SPM_Util_MessageReceivers - 1);
};

OO_TRACE_DECL(SPM_C_Util_MessageCaller) =
{
	params ["_message"];

	[_message] call (SPM_Util_MessageReceivers select (count SPM_Util_MessageReceivers - 1));
};

OO_TRACE_DECL(SPM_Util_MessageCaller) =
{
	params ["_message"];

	[_message] remoteExec ["SPM_C_Util_MessageCaller", remoteExecutedOwner];
};

OO_TRACE_DECL(SPM_Util_SurrenderVehicle) =
{
	params ["_vehicle"];

	if (not alive _vehicle) exitWith {};

	if ({ alive _x } count crew _vehicle == 0) exitWith {};

	if (_vehicle isKindOf "Tank" || _vehicle isKindOf "Car") then
	{
		_vehicle forceFlagTexture "\A3\Data_F\Flags\Flag_white_CO.paa";
	};
/*
	{
		_vehicle removeMagazineTurret [_x select 0, _x select 1];
	} forEach magazinesAllTurrets _vehicle;

	if (not (_vehicle isKindOf "Air")) then
	{
		_vehicle setFuel 0.0;
	};
*/
	{
		[_x] call SPM_Util_SurrenderMan;
	} forEach crew _vehicle;
};

OO_TRACE_DECL(SPM_Util_IsCowering) =
{
	params ["_unit"];

	animationState _unit select [0, 4] == "apan"
};

OO_TRACE_DECL(SPM_Util_StartCowering) =
{
	params ["_unit"];

	_unit playMove "ApanPknlMstpSnonWnonDnon_G01";
};

OO_TRACE_DECL(SPM_Util_StopCowering) =
{
	params ["_unit"];

	_unit switchMove "aidlpknlmstpsnonwnondnon_ai";
};

OO_TRACE_DECL(SPM_C_Util_SurrenderMan_Surrender) =
{
	params ["_man"];

	if ([_man] call SPM_Util_IsCowering) then { [_man] call SPM_Util_StopCowering };

	_man addAction ["Secure prisoner", { deleteVehicle (_this select 0) }, nil, 10, true, true, "", "vehicle _this == _this && alive _target", 2];
};

SPM_C_Util_SurrenderMan_DestroyPlayerLoadedMagazines =
{
	params ["_personalWeapon"];

	if (_personalWeapon) then
	{
		switch (currentWeapon player) do
		{
			case primaryWeapon player: { player setAmmo [primaryWeapon player, 0] };
			case handgunWeapon player: { player setAmmo [handgunWeapon player, 0] };
		};
	}
	else
	{
		private _turret = ((assignedVehicleRole player) select 1);
		private _magazineType = vehicle player currentMagazineturret _turret;
		private _roundsPerMagazine = [_magazineType] call JBA_RoundsPerMagazine;
		[vehicle player, _turret, _magazineType, _roundsPerMagazine - 1] call JBA_AdjustTurretAmmo;
	};
};

// AI should not spawn visible within this distance of a player
#define SPAWN_EXCLUSION_PROXIMITY 200.0

SPM_Util_Ranks = ["PRIVATE", "CORPORAL", "SERGEANT", "LIEUTENANT", "CAPTAIN", "MAJOR", "COLONEL"];

OO_TRACE_DECL(SPM_Util_InValueRange) =
{
	params ["_value", "_min", "_max"];

	_value >= _min && _value <= _max
};

OO_TRACE_DECL(SPM_Util_MapValueRange) =
{
	params ["_value", "_map"];

	if (_value < _map select 0 select 0) exitWith {};

	for "_i" from 1 to (count _map - 1) do
	{
		if (_map select _i select 0 >= _value) exitWith
		{
			private _pointMin = _map select (_i-1);
			private _pointMax = _map select _i;
			linearConversion [_pointMin select 0, _pointMax select 0, _value, _pointMin select 1, _pointMax select 1];
		};
	};
};

// Set a position above whatever surface is present, sea or ground

OO_TRACE_DECL(SPM_Util_SetPosition) =
{
	params ["_unit", "_position"];

	if (surfaceIsWater _position) then
	{
		_unit setPosASL _position
	}
	else
	{
		_unit setVectorUp (surfaceNormal _position);
		_unit setPosATL _position
	};
};

OO_TRACE_DECL(SPM_Util_RandomSpawnPosition) =
{
	[-10000 - random 10000, -10000 - random 10000, 1000 + random 1000]
};

OO_TRACE_DECL(SPM_Util_RandomPosition) =
{
	params ["_center", "_radius"];

	private _position = _center vectorAdd [_radius * 2, 0, 0];

	while { _center distance2D _position > _radius } do
	{
		_position = [(_center select 0) - _radius + random (_radius * 2), (_center select 1) - _radius + random (_radius * 2), 0];
	};

	_position;
};

OO_TRACE_DECL(SPM_Util_RotatePosition2D) =
{
	params ["_position", "_angle"];

	private _x = _position select 0;
	private _y = _position select 1;

	private _cos = cos -_angle;
	private _sin = sin -_angle;

	[_x * _cos - _y * _sin, _y * _cos + _x * _sin, _position select 2]
};

OO_TRACE_DECL(SPM_Util_AngleBetweenDirections) =
{
	params ["_direction1", "_direction2"];

	private _minimumAngle = (_direction1 max _direction2) - (_direction1 min _direction2);
	if (_minimumAngle > 180) then { _minimumAngle = 360 - _minimumAngle };
	_minimumAngle
};

OO_TRACE_DECL(SPM_Util_Find) =
{
	params ["_array", "_code", "_passthrough"];

	if (isNil "_passthrough") then
	{
		_passthrough = 0;
	};

	_index = -1;
	{
		if ([_x, _passthrough] call _code) exitWith
		{
			_index = _forEachIndex;
		};
	} forEach _array;

	_index
};

OO_TRACE_DECL(SPM_Util_DeleteArrayElements) =
{
	private _array = _this select 0;
	private _condition = _this select 1;
	private _count = param [2, -1, [0]];

	private _deletedElements = [];

	for "_i" from (count _array - 1) to 0 step -1 do
	{
		if ([_array, _i, _array select _i] call _condition) then
		{
			_deletedElements pushBack (_array deleteAt _i);
		};
		if (count _deletedElements == _count) exitWith {};
	};

	_deletedElements;
};

OO_TRACE_DECL(SPM_Util_GetUnits) =
{
	params ["_center", "_innerRadius", "_outerRadius", "_candidates"];

	private _innerRadiusSqr = _innerRadius ^ 2;
	private _outerRadiusSqr = _outerRadius ^ 2;
	private _distanceSqr = 0;

	_candidates select { _distanceSqr = _center distanceSqr getPos _x; _distanceSqr >= _innerRadiusSqr && _distanceSqr <= _outerRadiusSqr };
};

SPM_Util_DirectionNames = ["north", "northeast", "northeast", "east", "east", "southeast", "southeast", "south", "south", "southwest", "southwest", "west", "west", "northwest", "northwest", "north"];

OO_TRACE_DECL(SPM_Util_DirectionDescription) =
{
	params ["_direction"];

	SPM_Util_DirectionNames select floor (_direction / 22.5)
};

OO_TRACE_DECL(SPM_Util_PositionDescription) =
{
	params ["_position"];
	
	if ([_position, [0, getPos Headquarters] + triggerArea Headquarters] call SPM_Util_PositionInArea) exitWith { "base" };

	private _description = "";

	private _locations = [];

	_locations pushBack [nearestLocation [_position, "NameVillage"], 100];
	_locations pushBack [nearestLocation [_position, "NameCity"], 120];
	_locations pushBack [nearestLocation [_position, "NameCityCapital"], 140];

	{
		private _distance = (_x select 0) distance _position;
		_x pushBack _distance;
		_x pushBack (_distance / (_x select 1));
	} forEach _locations;

	private _bestLocation = locationNull;
	private _bestProximity = 1e30;
	private _bestDistance = 1e30;

	{
		if (_x select 3 < 3.0) exitWith
		{
			_bestLocation = _x select 0;
			_bestDistance = _x select 2;
			_bestProximity = _x select 3;
			_description = (if (_x select 3 < 2.0) then { "" } else { "near "}) + text (_x select 0);
		};
	} forEach _locations;

	if (_description == "") then
	{
		{
			if ((_x select 3) < _bestProximity) then
			{
				_bestLocation = _x select 0;
				_bestDistance = _x select 2;
				_bestProximity = _x select 3;
			};
		} forEach _locations;

		private _direction = (getPos _bestLocation) getDir _position;

		_description = ([_direction] call SPM_Util_DirectionDescription) + " of " + text _bestLocation;
	};

	private _nearestLocations = nearestLocations [_position, ["NameLocal", "NameMarine", "NameVillage", "NameCity", "NameCityCapital"], 1000];

	if (count _nearestLocations > 0 && type (_nearestLocations select 0) in ["NameLocal", "NameMarine"]) then
	{
		private _nearestLocation = _nearestLocations select 0;
		if (_nearestLocation distance _position < (_bestDistance * 0.6)) then
		{
			private _text = text _nearestLocation;
			if (_text == "military") then { _text = "military compound" };
			_description = text (_nearestLocations select 0) + " " + _description;
		};
	};

	_description;
};

OO_TRACE_DECL(SPM_Util_KeepOutOfWater) =
{
	params ["_position", "_center", "_distanceFromWater"];

	if (not surfaceIsWater _position) exitWith { _position };

	private _shiftDistance = 10;

	private _shift = (_center vectorDiff _position);
	_shift = (vectorNormalized _shift) vectorMultiply _shiftDistance;
	private _steps = floor ((_position distance _center) / _shiftDistance);

	for "_i" from 1 to _steps - 1 do
	{
		_position = _position vectorAdd _shift;
		if (not surfaceIsWater _position) exitWith { _position = _position vectorAdd (_shift vectorMultiply (_distanceFromWater / _shiftDistance)) };
	};

	_position
};

SPM_Util_AIAllEnabled = ["target", "autotarget", "move", "anim", "teamswitch", "fsm", "aimingerror", "suppression", "checkvisible", "autocombat", "path"];

OO_TRACE_DECL(SPM_Util_AISet) =
{
	params ["_unit", "_name", "_settings"];

	private _allEnabled = false;
	if (_settings == "all") then
	{
		_settings = SPM_Util_AIAllEnabled;
		_allEnabled = true;
	}
	else
	{
		_allEnabled = (count (SPM_Util_AIAllEnabled - _settings) == 0);
	};

	private _ai = _unit getVariable "SPM_AI";
	if (isNil "_ai") exitWith
	{
		if (not _allEnabled) then
		{
			_ai = [[_name, _settings]];
			_unit setVariable ["SPM_AI", _ai];
		};
	};


	private _index = [_ai, _name] call BIS_fnc_findInPairs;
	if (_index == -1) exitWith
	{
		if (not _allEnabled) then
		{
			_ai pushBack [_name, _settings];
		};
	};

	if (_allEnabled) exitWith
	{
		_ai deleteAt _index;
		if (count _ai == 0) then
		{
			_unit setVariable ["SPM_AI", nil];
		};
	};

	_ai select _index set [1, _settings];
};

OO_TRACE_DECL(SPM_Util_AIGet) =
{
	params ["_unit", "_name"];

	private _ai = _unit getVariable "SPM_AI";
	if (isNil "_ai") exitWith { +SPM_Util_AIAllEnabled };

	private _index = [_ai, _name] call BIS_fnc_findInPairs;
	if (_index == -1) exitWith { +SPM_Util_AIAllEnabled };

	_ai select _index select 1
};

OO_TRACE_DECL(SPM_Util_AIApply) =
{
	params ["_unit", "_settings"];

	_unit disableAI "all";
	{
		_unit enableAI _x;
	} forEach _settings;
};

OO_TRACE_DECL(SPM_Util_AIOnlyMove) =
{
	params ["_units"];

	{
		private _unit = _x;
		if (not isNull _unit) then
		{
			_unit disableAI "all";
			_unit enableAI "move";
			_unit enableAI "path";
			_unit enableAI "anim";
			_unit enableAI "teamswitch";
			{
				_unit forgetTarget _x;
			} forEach (_unit targets [true]);
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Util_AIRevokeMove) =
{
	params ["_units"];

	{
		private _unit = _x;
		if (not isNull _unit) then
		{
			_unit disableAI "move";
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Util_AIGrantMove) =
{
	params ["_units"];

	{
		private _unit = _x;
		if (not isNull _unit) then
		{
			_unit enableAI "move";
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Util_AIFullCapability) =
{
	params ["_units"];

	{
		private _unit = _x;
		if (not isNull _unit) then
		{
			_unit enableAI "all";
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Util_WaitForVehicleToMove) =
{
	params ["_vehicle", "_distance", "_movementTime", "_distanceTime"];

	private _origin = getPos _vehicle;

	[{ not alive _vehicle || { speed _vehicle > 1 } }, _movementTime, 0.1] call JB_fnc_timeoutWaitUntil;

	if (speed _vehicle > 1) then
	{
		[{ not alive _vehicle || { _origin distance _vehicle > _distance } }, _distanceTime, 0.1] call JB_fnc_timeoutWaitUntil;
	};
};

OO_TRACE_DECL(SPM_Util_HasLoadedWeapons) =
{
	params ["_vehicle"];

	if (_vehicle isKindOf "Man") exitWith { primaryWeapon _vehicle != "" || secondaryWeapon _vehicle != "" || handgunWeapon _vehicle != "" };

	private _hasLoadedWeapons = false;
	{
		private _type = _x select 0;
		if (not (getText (configFile >> "CfgMagazines" >> _type >> "ammo") in ["CMflare_Chaff_Ammo", "Laserbeam"])) exitWith
		{
			_hasLoadedWeapons = true;
		};
	} forEach (magazinesAllTurrets _vehicle);

	_hasLoadedWeapons;
};

// Return instances at least _minDistance from any member of the specified side, but don't check farther than _maxDistance.  instances
// are returned sorted from farthest to closest to a member of the specified side.
OO_TRACE_DECL(SPM_Util_PositionsFarthestFromSide) =
{
	params ["_instances", "_positionIndex", "_side", "_minDistance", "_maxDistance"];

	private _position = [];
	private _sideDistances = [];

	// Find out the distance from each position to its nearest entity of the specified side
	_instances = _instances apply
	{
		_position = if (_positionIndex == -1) then { _x } else { _x select _positionIndex };
		_sideDistances = (_position nearEntities _maxDistance) select { side _x == _side };
		_sideDistances = _sideDistances apply { _position distance _x };
		if (count _sideDistances == 0) then { _sideDistances = [_maxDistance] } else { _sideDistances sort true };
		[_sideDistances select 0, _x]
	};

	_instances sort false;

	for "_i" from count _instances - 1 to 0 step -1 do
	{
		if (_instances select _i select 0 > _minDistance) exitWith {};
		_instances deleteAt _i;
	};

	// Revert to the original _instances array format
	_instances apply { _x select 1 }
};

OO_TRACE_DECL(SPM_Util_PositionsInArc) =
{
	params ["_instances", "_positionIndex", "_center", "_direction", "_sweep"];

	if (_sweep == 360) exitWith { _instances };

	_instances select { [_center getDir (if (_positionIndex == -1) then { _x } else { _x select _positionIndex}), _direction] call SPM_Util_AngleBetweenDirections < _sweep / 2 }
};

OO_TRACE_DECL(SPM_Util_GetInteriorSpawnPositions) =
{
	params ["_center", "_innerRadius", "_outerRadius", "_enemySide"];

	private _innerArea = pi * _innerRadius^2;
	private _outerArea = pi * _outerRadius^2;
	private _area = _outerArea - _innerArea;

	private _positions = [_center, _innerRadius, _outerRadius, (sqrt _area) / 20] call SPM_Util_SampleAreaGrid; // 400 samples

#ifdef EXCLUDE_TOWARDS_BASE
	private _centerToHeadquarters = _center getDir (getPos Headquarters);
	_positions = _positions select { [_center getDir _x, _centerToHeadquarters] call SPM_Util_AngleBetweenDirections > 30 }
#endif

	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 20, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
//	[_positions, SPAWN_EXCLUSION_PROXIMITY, allPlayers apply { (getPosATL _x) vectorAdd [0,0,2] }] call SPM_Util_ExcludeSamplesVisibleToViewers;
	[_positions, 6.0, ["FENCE", "WALL", "BUILDING", "HOUSE", "ROCK", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;

	[_positions, -1, _enemySide, 100, 1000] call SPM_Util_PositionsFarthestFromSide
};

OO_TRACE_DECL(SPM_Util_ExitRoads) =
{
	params ["_originRoad", "_center", "_radius"];

	private _intersections = [];
	private _ends = [];
	private _exits = [];

	{
		_ends pushBack [_originRoad, _x];
	} forEach roadsConnectedTo _originRoad;

	{
		private _run = [_x select 0, _x select 1, _center, _radius] call SPM_Nav_RoadRun;
		private _end = _run select (count _run - 1);

		switch (count roadsConnectedTo _end) do
		{
			case 1: {};

			case 2: { _exits pushBack [_run select (count _run - 2), _end] };

			default
			{
				if (not (_end in _intersections)) then
				{
					_intersections pushBack _end;

					private _endNeighbor = _run select (count _run - 2);
					{
						if (_x != _endNeighbor) then
						{
							_ends pushBack [_end, _x];
						};
					} forEach roadsConnectedTo _end;
				};
			}
		};
	} forEach _ends;

	_exits
};

// Find a road that starts in the specified area and leaves the strongpoint
OO_TRACE_DECL(SPM_Util_GetRoadSpawnpoint) =
{
	params ["_areaPosition", "_areaRadius", "_destinationPosition", "_destinationRadius", "_enemySide", "_direction", "_sweep"];

	private _spawnpoint = [[],0];

	if (_sweep == 0) exitWith { _spawnpoint };

	private _originRoad = [_destinationPosition, _destinationRadius min 200] call BIS_fnc_nearestRoad;

	if (not isNull _originRoad) then
	{
		private _exits = [_originRoad, _areaPosition, _areaRadius] call SPM_Util_ExitRoads;

		if (count _exits > 0) then
		{
			_exits = _exits apply { [getPosATL (_x select 1), _x] };

			_exits = [_exits, 0, _destinationPosition, _direction, _sweep] call SPM_Util_PositionsInArc;

			_exits = [_exits, 0, _enemySide, 100, 1000] call SPM_Util_PositionsFarthestFromSide;

			if (count _exits > 0) then
			{
				private _exit = _exits select 0 select 1;
				private _exitPosition = getPos (_exit select 1) vectorAdd [-0.25 + random 0.5, -0.25 + random 0.5, 0];

				_spawnpoint = [_exitPosition, _exitPosition getDir (_exit select 0)];
			};
		};
	};

	_spawnpoint
};

OO_TRACE_DECL(SPM_Util_GetGroundSpawnpoint) =
{
	params ["_areaPosition", "_areaRadius", "_enemySide", "_direction", "_sweep"];

	if (_sweep == 0) exitWith { [[],0] };

	private _positions = [_areaPosition, _areaRadius, 10, "meters", _direction - _sweep / 2, _sweep] call SPM_Util_SampleAreaPerimeter;

	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 20, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
	[_positions, 6.0, ["FENCE", "WALL", "BUILDING", "HOUSE", "ROCK", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;

	_positions = [_positions, -1, _enemySide, 100, 1000] call SPM_Util_PositionsFarthestFromSide;

	if (count _positions == 0) exitWith { [[],0] };

	//private _position = _positions select 0; Bojan \/
	private _position = _positions select (random (count _positions));

	[_position, _position getDir _areaPosition]
};

OO_TRACE_DECL(SPM_Util_GetAirSpawnpoint) =
{
	params ["_center", "_radius", "_distance", "_altitude", "_direction", "_sweep"];

	if (_sweep == 0) exitWith { [[],0] };

	private _spawnDirection = _direction - (_sweep / 2) + random _sweep;
	_position = _center vectorAdd ([(_radius + _distance) * sin _spawnDirection, (_radius + _distance) * cos _spawnDirection, _altitude]);

	[_position, _position getDir _center]
};

OO_TRACE_DECL(SPM_Util_GetSeaSpawnpoint) =
{
	params ["_center", "_spawnRadius", "_enemySide", "_direction", "_sweep"];

	if (_sweep == 0) exitWith { [[],0] };

	private _positions = [_center, _spawnRadius, 10.0, "meters", _direction - _sweep / 2, _sweep] call SPM_Util_SampleAreaPerimeter;
	private _waterPositions = [];
	[_positions, ["#GdtWater"], _waterPositions] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_waterPositions, -20, 0] call SPM_Util_ExcludeSamplesByHeightASL;

	_waterPositions = [_waterPositions, -1, _enemySide, 100, 1000] call SPM_Util_PositionsFarthestFromSide;

	if (count _waterPositions == 0) exitWith { [[],0] };

	private _spawnPosition = selectRandom _waterPositions;

	[_spawnPosition, _spawnPosition getDir _center]
};

OO_TRACE_DECL(SPM_Util_GroupMembersAreDead) =
{
	params ["_groups"];

	if (_groups isEqualType grpNull) exitWith
	{
		{ alive _x } count units _groups == 0
	};

	private _livingMembers = 0;
	{
		_livingMembers = { alive _x } count units _x;
		if (_livingMembers > 0) exitWith {};
	} forEach _groups;

	_livingMembers == 0
};

OO_TRACE_DECL(SPM_Util_PositionIsInsideObject) =
{
	params ["_position", "_object"];

	_position = _object worldToModel _position;

	private _boundingBox = boundingBoxReal _object;

	private _negative = _boundingBox select 0;
	private _positive = _boundingBox select 1;

	if (_position select 0 < _negative select 0 || _position select 0 > _positive select 0) exitWith { false };
	if (_position select 1 < _negative select 1 || _position select 1 > _positive select 1) exitWith { false };
	if (_position select 2 < _negative select 2 || _position select 2 > _positive select 2) exitWith { false };

	true
};

OO_TRACE_DECL(SPM_Util_MarkPositions) =
{
	params ["_positions", "_prefix", "_color"];

	private _markerName = "";

	private _markerIndex = 0;
	while { true } do
	{
		_markerName = format ["%1-%2", _prefix, _markerIndex];
		if ((getMarkerPos _markerName) select 0 == 0) exitWith {};
		deleteMarker _markerName;
		_markerIndex = _markerIndex + 1;
	};

	{
		_markerName = format ["%1-%2", _prefix, _forEachIndex];
		private _marker = createMarker [_markerName, _x];
		if (_color find "Color" == 0) then
		{
			_marker setMarkerType "mil_dot";
			_marker setMarkerColor _color;
		}
		else
		{
			_marker setMarkerType _color;
		};
	} forEach _positions;
};

OO_TRACE_DECL(SPM_Util_MarkPositionsLocal) =
{
	params ["_positions", "_prefix", "_color"];

	private _markerName = "";

	private _markerIndex = 0;
	while { true } do
	{
		_markerName = format ["%1-%2", _prefix, _markerIndex];
		if ((getMarkerPos _markerName) select 0 == 0) exitWith {};
		deleteMarkerLocal _markerName;
		_markerIndex = _markerIndex + 1;
	};

	{
		_markerName = format ["%1-%2", _prefix, _forEachIndex];
		private _marker = createMarkerLocal [_markerName, _x];
		if (_color find "Color" == 0) then
		{
			_marker setMarkerTypeLocal "mil_dot";
			_marker setMarkerColorLocal _color;
		}
		else
		{
			_marker setMarkerTypeLocal _color;
		};
	} forEach _positions;
};

OO_TRACE_DECL(SPM_Util_SampleAreaGrid) =
{
	params ["_center", "_innerRadius", "_outerRadius", "_stepSize"];

	private _steps = floor (_outerRadius / _stepSize);
	private _position = [0, 0, 0];
	private _outerRadiusSqr = _outerRadius ^ 2;
	private _innerRadiusSqr = _innerRadius ^ 2;
	private _distanceSqr = 0;

	private _positions = [];

	for "_x" from -_steps to _steps do
	{
		_position set [0, (_center select 0) - (_x * _stepSize)];
		for "_y" from -_steps to _steps do
		{
			_position set [1, (_center select 1) - (_y * _stepSize)];
		
			_distanceSqr = _center distanceSqr _position;

			if (_distanceSqr < _innerRadiusSqr) then
			{
				_y = abs _y; // We found a point inside, so skip to the mirrored point inside
			}
			else
			{
				if (_distanceSqr <= _outerRadiusSqr) then
				{
					_positions pushBack +_position;
				};
			};
		};
	};

	_positions
};

OO_TRACE_DECL(SPM_Util_SampleAreaRandom) =
{
	params ["_center", "_innerRadius", "_outerRadius", "_samples"];

	private _positions = [];

	if (_innerRadius >= _outerRadius) exitWith { _positions };

	private _position = [0,0,0];

	private _outerRadiusSquared = _outerRadius * _outerRadius;
	private _r = 0;
	private _a = 0;
	private _getPosition =
	{
		_r = sqrt (random _outerRadiusSquared);
		_a = random 360;
		[_r * cos _a, _r * sin _a, 0]
	};

	for "_i" from 1 to _samples do
	{
		_position = call _getPosition;
		if (_innerRadius > 0) then
		{
			while { vectorMagnitude _position < _innerRadius } do
			{
				_position = call _getPosition;
			};
		};

		_positions pushBack (_center vectorAdd _position);
	};

	_positions
};

OO_TRACE_DECL(SPM_Util_SampleAreaPerimeter) =
{
	params ["_center", "_radius", "_stepSize", ["_stepSizeUnits", "meters", [""]], ["_startAngle", random 360, [0]], ["_sweepAngle", 360, [0]]];

	private _angleIncrement = 0;
	switch (_stepSizeUnits) do
	{
		case "meters":
		{
			private _circumference = 2 * pi * _radius;
			private _sweepDistance = _circumference * (_sweepAngle / 360);
			_angleIncrement = _sweepAngle / (_sweepDistance / _stepSize);
		};
		case "degrees":
		{
			_angleIncrement = _stepSize;
		};
		case "samples":
		{
			_angleIncrement = _sweepAngle / _stepSize;
		};
	};

	if (_angleIncrement == 0) exitWith { [] };

	private _positions = [];
	private _angle = _startAngle;
	while { _angle <= _startAngle + _sweepAngle } do
	{
		_positions pushBack (_center vectorAdd [_radius * sin _angle, _radius * cos _angle, 0]);
		_angle = _angle + _angleIncrement;
	};

	_positions
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesBySurfaceType) =
{
	params ["_positions", "_surfaceTypes", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _excludeRoadSurfaces = "#GdtRoad" in _surfaceTypes;
	private _excludeWaterSurfaces = "#GdtWater" in _surfaceTypes;

	private _position = [];

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;

		if (_excludeRoadSurfaces && { isOnRoad _position } || { (_excludeWaterSurfaces && { surfaceIsWater _position }) } || { surfaceType _position in _surfaceTypes }) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesBySurfaceIncline) =
{
	params ["_positions", "_minAngle", "_maxAngle", "_excludedPositions"];

	private _minAngleCos = cos _minAngle;
	private _maxAngleCos = cos _maxAngle;

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _position = [];
	private _slopeCos = 0;

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;

		_slopeCos = (surfaceNormal _position) select 2;
		if (_slopeCos >= _maxAngleCos && _slopeCos <= _minAngleCos) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesByHeightASL) =
{
	params ["_positions", "_minHeight", "_maxHeight", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _position = [];

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;

		if (getTerrainHeightASL _position >= _minHeight && { getTerrainHeightASL _position <= _maxHeight }) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesVisibleToViewers) =
{
	params ["_positions", "_radius", "_viewers", "_excludedPositions"];

	if (count _viewers == 0) exitWith {};

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _position = [];
	private _raisedPosition = [];

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;
		_raisedPosition = _position vectorAdd [0,0,2];

		{
			if (_position distance _x <= _radius && { not terrainIntersect [_raisedPosition, _x] }) exitWith
			{
				_positions deleteAt _i;
				if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
			}
		} forEach _viewers;
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesByDirection) =
{
	params ["_positions", "_origin", "_direction", "_sweepAngle", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _position = [];
	private _halfSweep = _sweepAngle / 2.0;

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;

		if (([_origin getDir _position, _direction] call SPM_Util_AngleBetweenDirections) < _halfSweep) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesByProximity) =
{
	params ["_positions", "_proximity", "_proximateTypes", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _excludeBuildings = "BUILDING" in _proximateTypes;
	private _excludeRoads = "ROAD" in _proximateTypes;
	private _excludeWest = "WEST" in _proximateTypes;
	private _excludeEast = "EAST" in _proximateTypes;
	private _excludeIndependent = "INDEPENDENT" in _proximateTypes;
	private _excludeCivilian = "CIVILIAN" in _proximateTypes;
	private _excludeRocks = "ROCK" in _proximateTypes;
	private _excludeEntities = "ENTITY" in _proximateTypes;

	private _excludeFaction = _excludeWest || _excludeEast || _excludeIndependent || _excludeCivilian;

	private _position = [];
	private _entities = [];
	private _shiftedPosition = [];
	private _towardsObject = [];
	private _boundingBox = [];
	private _deleted = false;

	for "_i" from (count _positions - 1) to 0 step -1 do
	{
		_position = _positions select _i;
		_deleted = false;

		_entities = if (_excludeFaction || _excludeEntities) then { _position nearEntities _proximity } else { [] };

		switch (true) do
		{
			case (_excludeEntities && { count _entities > 0 }): { _deleted = true };
			case (_excludeWest && { not isNil { { if (side _x == west) exitWith { true } } forEach _entities } }): { _deleted = true };
			case (_excludeEast && { not isNil { { if (side _x == east) exitWith { true } } forEach _entities } }): { _deleted = true };
			case (_excludeIndependent && { not isNil { { if (side _x == independent) exitWith { true } } forEach _entities } }): { _deleted = true };
			case (_excludeCivilian && { not isNil { { if (side _x == civilian) exitWith { true } } forEach _entities } }): { _deleted = true };
			default
			{
				private _terrainObjects = nearestTerrainObjects [_position, _proximateTypes, _proximity + 40, false, true];

				{
					if (_x distance2D _position < _proximity) exitWith { _deleted = true };

					_boundingBox = boundingBoxReal _x;
					if ([_position, [_proximity, getPosATL _x, _boundingBox select 1 select 0, _boundingBox select 1 select 1, getDir _x]] call SPM_Util_PositionInArea) exitWith { _deleted = true };
				} forEach _terrainObjects;

				if (not _deleted && _excludeBuildings) then
				{
					private _buildings = nearestObjects [_position, ["Building"], _proximity + 50, false];

					{
						if (_x distance2D _position < _proximity) exitWith { _deleted = true };

						_boundingBox = boundingBoxReal _x;
						if ([_position, [_proximity, getPosATL _x, _boundingBox select 1 select 0, _boundingBox select 1 select 1, getDir _x]] call SPM_Util_PositionInArea) exitWith { _deleted = true };
					} forEach _buildings;
				};

				if (not _deleted && _excludeRoads) then
				{
					if (isOnRoad _position) exitWith { _deleted = true };

					private _roads = _position nearRoads (_proximity + 50);

					{
						_shiftedPosition = +_position;
						_shiftedPosition set [2, getPosATL _x select 2];
						_towardsObject = _shiftedPosition vectorFromTo getPosATL _x;  //TODO: Use perpendicular to road's direction
						if (isOnRoad (_shiftedPosition vectorAdd (_towardsObject vectorMultiply _proximity))) exitWith { _deleted = true };
					} forEach _roads;
				};

				if (not _deleted && _excludeRocks) then
				{
					private _objects = nearestTerrainObjects [_position, ["ROCK", "HIDE"], _proximity + 40, false, true]; // Largest rock object to date has a radius of over 35 meters

					{
						if (str _x find "stone_" != -1 || str _x find "rock_" != -1) then // sharp & blunt
						{
							if (_x distance2D _position < _proximity) exitWith { _deleted = true };

							_boundingBox = boundingBoxReal _x;
							if ([_position, [_proximity, getPosATL _x, _boundingBox select 1 select 0, _boundingBox select 1 select 1, getDir _x]] call SPM_Util_PositionInArea) exitWith { _deleted = true };
						};

						if (_deleted) exitWith {};
					} forEach _objects;
				};
			};
		};

		if (_deleted) then
		{
			_positions deleteAt _i;
			if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
		};
	};
};

OO_TRACE_DECL(SPM_Util_ExcludeSamplesByAreas) =
{
	params ["_positions", "_areas", "_excludedPositions"];

	private _saveFilteredPositions = not isNil "_excludedPositions";

	private _position = [];
	private _center = [];
	private _innerRadiusSqr = 0;
	private _outerRadiusSqr = 0;
	private _distanceSqr = 0;

	{
		_center = _x select 0;
		_innerRadiusSqr = (_x select 1) ^ 2;
		_outerRadiusSqr = (_x select 2) ^ 2;

		for "_i" from (count _positions - 1) to 0 step -1 do
		{
			_position = _positions select _i;

			_distanceSqr = _position distanceSqr _center;

			if (_distanceSqr >= _innerRadiusSqr && _distanceSqr <= _outerRadiusSqr) then
			{
				_positions deleteAt _i;
				if (_saveFilteredPositions) then { _excludedPositions pushBack _position };
			};
		};
	} forEach _areas;
};

OO_TRACE_DECL(SPM_Util_ClosestPosition) =
{
	params ["_positions", "_key"];

	private _distances = _positions apply { [_x distance _key, _x] };
	_distances sort true;

	_distances select 0 select 1
};

OO_TRACE_DECL(SPM_Util_OpenPositionForVehicle) =
{
	params ["_center", "_radius"];

	private _positions = [_center, 0, _radius, 10] call SPM_Util_SampleAreaGrid;
	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 10.0, ["WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

	if (count _positions == 0) exitWith { _center };

	selectRandom _positions
};

OO_TRACE_DECL(SPM_Util_VehicleMobilityDamage) =
{
	params ["_vehicle"];

	private _hitPointsDamage = getAllHitPointsDamage _vehicle;
	private _names = _hitPointsDamage select 1;
	private _values = _hitPointsDamage select 2;

	private _numberSystems = 0;
	private _totalDamage = 0;
	{ if (_x find "wheel" >= 0 || { _x find "track" >= 0 }) then { _numberSystems = _numberSystems + 1; _totalDamage = _totalDamage + (_values select _forEachIndex) } } forEach _names;

	if (_numberSystems == 0) exitWith { 0.0 };

	_totalDamage / _numberSystems
};

OO_TRACE_DECL(SPM_Util_PositionInArea) =
{
	params ["_position", "_area"];

	if (count _area == 0) exitWith { false };

	private _distance = 0;
	
	if (count _area == 2) then
	{
		// Radius [_distance, _position]
		_distance = (_area select 1) distance _position;
	}
	else
	{
		// Area [_distance, _position, _width, _height, _angle]
		_distance = [_position, _area select 1, _area select 2, _area select 3, _area select 4] call JB_fnc_distanceToArea;
	};

	if (_distance > (_area select 0)) exitWith { false };

	true
};

OO_TRACE_DECL(SPM_Util_CurrentWeapon) =
{
	params ["_unit"];

	if (vehicle _unit == _unit || { [_unit] call SPM_Util_UnitIsInPersonTurret }) exitWith { currentWeapon _unit };

	private _turret = if (driver vehicle _unit == _unit) then { [-1] } else { (assignedVehicleRole _unit) select 1 };

	vehicle _unit currentWeaponTurret _turret
};

OO_TRACE_DECL(SPM_Util_HasOffensiveWeapons) =
{
	params ["_vehicle"];

	(weapons _vehicle) findIf { [_x] call JB_fnc_isOffensiveWeapon } >= 0
};

OO_TRACE_DECL(SPM_Util_UnitIsInPersonTurret) =
{
	params ["_unit"];

	(fullCrew (vehicle _unit)) select { _x select 0 == _unit } select 0 select 4
};

OO_TRACE_DECL(SPM_Util_RoadDirection) =
{
	params ["_road"];

	private _adjacent = roadsConnectedTo _road;

	if (count _adjacent == 2) exitWith
	{
		private _v0 = getPos _road vectorFromTo getPos (_adjacent select 0);
		private _v1 = getPos _road vectorFromTo getPos (_adjacent select 1);

		private _vAverage = (_v0 vectorAdd _v1) vectorMultiply 0.5;

		private _direction = (-(_vAverage select 1)) atan2 (_vAverage select 0);

		(_direction + 360) mod 360
	};

	if (count _adjacent == 1) exitWith { _road getDir (_adjacent select 0) };

	_road getDir ([_road] call SPM_Nav_GetIntersectionPosition)
};

OO_TRACE_DECL(SPM_Util_PlaceVehicleOnSurface) =
{
	params ["_vehicle", "_position"];

	_vehicle setPosASL [_position select 0, _position select 1, 10000];
	_vehicle setPosASL [_position select 0, _position select 1, 10000 - ((getPosVisual _vehicle) select 2)];
};

OO_TRACE_DECL(SPM_Util_NumberPlayers) =
{
	private _parameterValue = ["NumberPlayers"] call JB_MP_GetParamValue;

	if (_parameterValue == -1) exitWith { { not (_x isKindOf "HeadlessClient_F") } count allPlayers };

	_parameterValue
};

OO_TRACE_DECL(SPM_Util_NumberServiceMembers) =
{
	params ["_branchesOfService"];

	{ (_x getVariable ["SPM_BranchOfService", ""]) in _branchesOfService } count allPlayers
};

OO_TRACE_DECL(SPM_Util_HabitableBuildings) =
{
	params ["_center", "_innerRadius", "_outerRadius", "_numberInhabitants"];

	private _data = [];
	private _chain =
	[
		[SPM_Chain_FixedPosition, [_center]],
		[SPM_Chain_PositionToBuildings, [_innerRadius, _outerRadius]],
		[SPM_Chain_BuildingsToEnterableBuildings, []],
		[SPM_Chain_EnterableBuildingsToOccupancyBuildings, [_numberInhabitants]]
	];

	if (not ([_data, _chain] call SPM_Chain_Execute)) exitWith { [] };

	[_data, "occupancy-buildings"] call SPM_Util_GetDataValue;
};

OO_TRACE_DECL(SPM_Util_CreateFlagpole) =
{
	params ["_center", "_radius", "_flag"];

	private _innerRadius = 0.0;
	private _positions = [];
	while { true } do
	{
		_positions = [_center, _innerRadius, _innerRadius + 20, 4.0] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 30, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, 4.0, ["FENCE", "WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

		if (count _positions > 0) exitWith {};

		if (_innerRadius == _radius) exitWith {};
		_innerRadius = (_innerRadius + 20) min _radius;
	};

	if (count _positions == 0) exitWith { objNull };

	private _flagpolePosition = [_positions, _center] call SPM_Util_ClosestPosition;
	private _flagpoleDirection = [_flagpolePosition, 0] call SPM_Util_EnvironmentAlignedDirection;

	private _flagpole = [_flag, _flagpolePosition, _flagpoleDirection] call SPM_fnc_spawnVehicle;
	_flagpole setVectorUp [0,0,1];  // Will rotate around the origin of the object, which is usually in its middle
	_flagpole allowDamage false;

	_flagpole
};

OO_TRACE_DECL(SPM_Util_PromoteMemberToOfficer) =
{
	params ["_garrison", ["_member", objNull, [objNull]]];

	private _forceUnit = [];

	private _forceUnits = OO_GET(_garrison,ForceCategory,ForceUnits);
	if (count _forceUnits == 0) exitWith { false };

	if (isNull _member) then
	{
		_forceUnit = selectRandom _forceUnits;
	}
	else
	{
		private _index = _forceUnits findIf { OO_GET(_x,ForceUnit,Vehicle) == _member };
		if (_index != -1) then { _forceUnit = _forceUnits select _index };
	};

	if (count _forceUnit == 0) exitWith { false };

	private _member = OO_GET(_forceUnit,ForceUnit,Vehicle);
	private _group = group _member;

	private _appearanceType = "";
	switch (OO_GET(_garrison,ForceCategory,SideEast)) do
	{
		case east: { _appearanceType = "O_officer_F" };
		case west: { _appearanceType = "B_officer_F" };
		case independent: { _appearanceType = "I_officer_F" };
	};

	if (_appearanceType == "") exitWith { false };

	private _descriptor = [[_appearanceType]] call SPM_fnc_groupFromClasses;
	private _replacementGroup = [_descriptor select 0, _descriptor select 1, getPosATL _member, getDir _member, false] call SPM_fnc_spawnGroup;
	[_garrison, _replacementGroup] call OO_GET(_category,Category,InitializeObject);

	private _replacementMember = leader _replacementGroup;
	private _replacementForceUnit = [_replacementMember, [_replacementMember]] call OO_CREATE(ForceUnit);

	[_forceUnit, _replacementForceUnit] call OO_METHOD(_garrison,ForceCategory,ReplaceUnit);

	[_replacementMember] join _group;
	deleteGroup _replacementGroup;
	deleteVehicle _member;

	true
};

OO_TRACE_DECL(SPM_Util_SetDataValue) =
{
	params ["_data", "_name", "_value"];

	private _index = _data findIf { _x select 0 == _name };
	if (_index >= 0) then
	{
		if (not isNil "_value") then
		{
			(_data select _index) set [1, _value];
		}
		else
		{
			_data deleteAt _index;
		};
	}
	else
	{
		if (not isNil "_value") then
		{
			_data pushBack [_name, _value];
		};
	};
};

OO_TRACE_DECL(SPM_Util_GetDataValue) =
{
	params ["_data", "_name"];

	private _index = _data findIf { _x select 0 == _name };

	if (_index == -1) exitWith {};

	_data select _index select 1
};

OO_TRACE_DECL(SPM_Util_CleanedRoleDescription) = 
{
	params ["_description"];

	private _paren = _description find "(";
	if (_paren >= 0) then
	{
		_description = _description select [0, _paren];
		_description = [_description, "end"] call JB_fnc_trimWhitespace;
	};

	_description;
};

OO_TRACE_DECL(SPM_Util_IsUrbanEnvironment) =
{
	params ["_buildings", "_area"];

	count _buildings > _area * 0.0005
};

// Figure out the direction of the closest house.  If nothing, then the closest fence or wall.  Returns _default if no context for direction,
OO_TRACE_DECL(SPM_Util_EnvironmentAlignedDirection) =
{
    params ["_position", "_default", ["_radius", 20, [0]]];

    private _objects = (_position nearObjects ["NonStrategic", _radius]) apply { [_position distance _x, getDir _x] };

    private _roads = _position nearRoads _radius;

    _objects append (_roads select { getDir _x != 0 } apply { [_position distance _x, getDir _x ] }); // Roads with inherent directions (includes runways)
    _objects append (_roads select { count roadsConnectedTo _x > 0 } apply { [_position distance _x, _x getDir ((roadsConnectedTo _x) select 0)] }); // Roads connected to other roads

    if (count _objects > 0) exitWith
    {
        _objects sort true;
        _objects select 0 select 1;
    };

    private _objects = ((nearestTerrainObjects [_position, ["wall"], _radius]) apply { [_position distance _x, getDir _x] });

    if (count _objects > 0) exitWith
    {
        _objects sort true;
        _objects select 0 select 1;
    };

    if (isNil "_default") exitWith { nil };
   
    _default
};

OO_TRACE_DECL(SPM_Util_FireTurretWeapon) =
{
	params ["_vehicle", "_turret", "_weapon"];

	private _crew = _vehicle turretUnit _turret;
	if (not isNull _crew) then
	{
		private _magazine = (weaponState [_vehicle, _turret, _weapon]) select 3;
		if (_magazine != "") then
		{
			private _details = magazinesAllTurrets _vehicle select { (_x select 0) == _magazine && { (_x select 1) isEqualTo _turret } };
			if (count _details > 0) then
			{
				_details = _details select 0;
				_vehicle action ["UseMagazine", _vehicle, _crew, _details select 4, _details select 3];
			};
		};
	};
};

if (not isServer && hasInterface) exitWith {};

SPM_Util_SurrenderMan_CS = call JB_fnc_criticalSectionCreate;
SPM_Util_SurrenderMan_Pending = [];

OO_TRACE_DECL(SPM_Util_SurrenderMan_Monitor) =
{
	scriptName "SPM_Util_SurrenderMan_Monitor";

	while { true } do
	{
		SPM_Util_SurrenderMan_CS call JB_fnc_criticalSectionEnter;

		if (count SPM_Util_SurrenderMan_Pending == 0) exitWith { SPM_Util_SurrenderMan_CS call JB_fnc_criticalSectionLeave };

		for "_i" from count SPM_Util_SurrenderMan_Pending - 1 to 0 step -1 do
		{
			_man = SPM_Util_SurrenderMan_Pending select _i;

			if (not alive _man) then
			{
				SPM_Util_SurrenderMan_Pending deleteAt _i;
			}
			else
			{
				// If in a state where he can get into the surrender pose
				//TODO: More cases.  Only the ones we run into are handled here.  There's also free fall and probably others.
				if (vehicle _man == _man && { not (((animationState _man) select [0, 4]) in ["aswm", "assw"]) }) then
				{
					SPM_Util_SurrenderMan_Pending deleteAt _i;

					[[_man], SPM_C_Util_SurrenderMan_Surrender] remoteExec ["call", 0];
					_man action ["surrender"];
				};
			};
		};

		SPM_Util_SurrenderMan_CS call JB_fnc_criticalSectionLeave;

		sleep 0.5;
	};
};

SPM_Util_SurrenderMan_Killed =
{
	params ["_unit", "_killer", "_instigator"];

	if (not isPlayer _instigator) exitWith {};

	if (_instigator == _unit) exitWith {};

	[_instigator == _killer] remoteExec ["SPM_C_Util_SurrenderMan_DestroyPlayerLoadedMagazines", _instigator];
};

SPM_Util_SurrenderMan_Functions = ["target", "autotarget", "autocombat", "cover"];

OO_TRACE_DECL(SPM_Util_SurrenderMan) =
{
	params ["_man"];

	if (captive _man || isPlayer _man) exitWith {};

	_man setCaptive true;
	{ _man disableAI _x } forEach SPM_Util_SurrenderMan_Functions;

	if ((vehicle _man) isKindOf "StaticWeapon") then
	{
		[_man] orderGetIn false;
		[_man] allowGetIn false;
	};

	_man addEventHandler ["Killed", SPM_Util_SurrenderMan_Killed];

	SPM_Util_SurrenderMan_CS call JB_fnc_criticalSectionEnter;

		SPM_Util_SurrenderMan_Pending pushBackUnique _man;
		if (count SPM_Util_SurrenderMan_Pending == 1) then
		{
			[] spawn SPM_Util_SurrenderMan_Monitor;
		};

	SPM_Util_SurrenderMan_CS call JB_fnc_criticalSectionLeave;
};

// Surrender the specified men and vehicles.  A wave of surrender propagates outwards from the center to a
// the specified radius in the specified elapsed time.  Any units outside of the radius are then instantly surrendered.
OO_TRACE_DECL(SPM_Util_Surrender) =
{
	params ["_men", "_vehicles", "_center", "_radius", "_elapsedTime"];

	if (_elapsedTime == 0 || _radius == 0) exitWith
	{
		{ [_x] call SPM_Util_SurrenderVehicle } forEach _vehicles;
		{ [_x] call SPM_Util_SurrenderMan } forEach _men;
	};

	_this spawn
	{
		params ["_men", "_vehicles", "_center", "_radius", "_elapsedTime"];

		_men = _men apply { [(_center distance _x) - 10 + random 20, _x] };
		_men sort true;

		_vehicles = _vehicles apply { [(_center distance _x) - 10 + random 20, _x] };
		_vehicles sort true;

		private _timeInterval = 0.5;
		private _intervals = _elapsedTime / _timeInterval;
		private _distanceInterval = _radius / _intervals;

		private _crew = objNull;

		private _distance = 0;
		while { count _vehicles > 0 || count _men > 0 } do
		{
			_distance = _distance + _distanceInterval;
			if (_distance < _radius) then
			{
				sleep _timeInterval;
			}
			else
			{
				_distance = 1e10;
			};

			while { count _vehicles > 0 && { (_vehicles select 0 select 0) < _distance } } do
			{
				[(_vehicles deleteAt 0) select 1] call SPM_Util_SurrenderVehicle;
			};

			while { count _men > 0 && { (_men select 0 select 0) < _distance } } do
			{
				[(_men deleteAt 0) select 1] call SPM_Util_SurrenderMan;
			};
		};
	};
};
