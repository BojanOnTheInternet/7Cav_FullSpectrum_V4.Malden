/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Chain_FixedPosition) =
{
	params ["_data", "_direction", "_position"];

	if (_direction == -1) exitWith { false };

	[_data, "position", _position] call SPM_Util_SetDataValue;

	true
};

OO_TRACE_DECL(SPM_Chain_RandomLandPosition) =
{
	params ["_data", "_direction"];

	private _position = [0,0,0];

	while { surfaceIsWater _position } do
	{
		_position = [random WorldSize, random WorldSize, 0];
	};

	[_data, "position", _position] call SPM_Util_SetDataValue;

	true
};

OO_TRACE_DECL(SPM_Chain_RandomLocation) =
{
	params ["_data", "_direction", "_locationTypes"];

	private _locations = [_data, "all-locations"] call SPM_Util_GetDataValue;

	if (isNil "_locations") then
	{
		_locations = nearestLocations [[WorldSize / 2, WorldSize / 2,0], _locationTypes, WorldSize / 2];
		[_data, "all-locations", _locations] call SPM_Util_SetDataValue;
	};

	if (count _locations == 0) exitWith { false };

	private _location = _locations deleteAt (floor random count _locations);
	private _position = getPos _location;
	_position set [2, 0];

	[_data, "location", _location] call SPM_Util_SetDataValue;
	[_data, "position", _position] call SPM_Util_SetDataValue;

	true
};

OO_TRACE_DECL(SPM_Chain_NearestLocation) =
{
	params ["_data", "_direction", "_position", "_distance", "_locationTypes"];

	private _locations = [_data, "near-locations"] call SPM_Util_GetDataValue;

	if (isNil "_locations") then
	{
		_locations = nearestLocations [_position, _locationTypes, _distance];
		[_data, "near-locations", _locations] call SPM_Util_SetDataValue;
	};

	if (count _locations == 0) exitWith { false };

	private _location = _locations deleteAt 0;
	private _position = getPos _location;
	_position set [2, 0];

	[_data, "location", _location] call SPM_Util_SetDataValue;
	[_data, "position", _position] call SPM_Util_SetDataValue;

	true
};

OO_TRACE_DECL(SPM_Chain_PositionToIsolatedPosition) =
{
	params ["_data", "_direction", "_blacklist"];

	if (_direction == -1) exitWith { false };

	private _position = [_data, "position"] call SPM_Util_GetDataValue;

	private _isIsolated = true;
	{
		if ([_position, _x] call SPM_Util_PositionInArea) exitWith { _isIsolated = false };
	} forEach _blacklist;

	_isIsolated
};

OO_TRACE_DECL(SPM_Chain_PositionToBuildings) =
{
	params ["_data", "_direction", "_innerRadius", "_outerRadius"];

	if (_direction == -1) exitWith { false };

	private _position = [_data, "position"] call SPM_Util_GetDataValue;

	_buildings = _position nearObjects ["Building", _outerRadius];
	if (_innerRadius > 0) then { _buildings = _buildings select { _x distance _position > _innerRadius } };

	[_data, "buildings", _buildings] call SPM_Util_SetDataValue;

	true;
};

OO_TRACE_DECL(SPM_Chain_BuildingsToEnterableBuildings) =
{
	params ["_data", "_direction"];

	if (_direction == -1) exitWith { false };

	_buildings = [_data, "buildings"] call SPM_Util_GetDataValue;

	_buildings = _buildings select { not ((_x buildingExit 0) isEqualTo [0,0,0]) && { count (_x buildingPos -1) > 0 } };
	_buildings = _buildings select { (typeOf _x) find "Bridge" == -1 };

	if (count _buildings == 0) exitWith { false };

	[_data, "enterable-buildings", _buildings] call SPM_Util_SetDataValue;

	true;
};

OO_TRACE_DECL(SPM_Chain_EnterableBuildingsToOccupancyBuildings) =
{
	params ["_data", "_direction", "_occupancyMinimum"];

	if (_direction == -1) exitWith { false };

	_buildings = [_data, "enterable-buildings"] call SPM_Util_GetDataValue;

	private _type = "";

	_buildings = _buildings select
		{
			// Skip buildings that aren't big enough or whose exits are off the ground (suggesting that they're not properly connected to the rest of the world)
			if (count (_x buildingPos -1) < _occupancyMinimum || { (_x buildingExit 0) select 2 > 4.0 }) then
			{
				false
			}
			else
			{
				_type = toLower typeOf _x;

				if (_type == "land_i_shed_ind_f") then
				{
					true
				}
				else
				{
					_type find "land_d_" == -1 &&
					{ _type find "land_u_" == -1 } &&
					{ _type find "_ruins_" == -1 } &&
					{ _type find "_unfinished_" == -1 } &&
					{ _type find "_shed_" == -1 } &&
					{ _type find "_slum_" == -1 } &&
					{ _type find "_dam_" == -1 } &&
					{ not (_x isKindOf "Piers_base_F") }
				};
			};
		};

	if (count _buildings == 0) exitWith { false };

	[_data, "occupancy-buildings", _buildings] call SPM_Util_SetDataValue;

	true
};

// A location that can house _garrisonComplement within _garrisonRadius
OO_TRACE_DECL(SPM_Chain_OccupancyBuildingsToGarrisonPosition) =
{
	params ["_data", "_direction", "_garrisonRadius", "_garrisonComplement", "_matchAny"];

	if (_direction == -1) exitWith { false };

	private _buildings = [_data, "occupancy-buildings"] call SPM_Util_GetDataValue;

	private _candidateCenterBuildings = +_buildings;

	private _garrisonCenterBuilding = objNull;
	private _garrisonBuildings = [];
	private _garrisonRadiusSqr = _garrisonRadius ^ 2;

	private _garrisonCapacity = -1;
	private _largestCapacity = -1;
	private _candidateCenterBuilding = objNull;

	while { count _candidateCenterBuildings > 0 } do
	{
		_candidateCenterBuilding = _candidateCenterBuildings deleteAt (floor random count _candidateCenterBuildings);
		_garrisonBuildings = _buildings select { _x distanceSqr _candidateCenterBuilding < _garrisonRadiusSqr };
		_garrisonCapacity = 0;
		{
			_garrisonCapacity = _garrisonCapacity + count (_x buildingPos -1);
		} forEach _garrisonBuildings;
		if (_garrisonCapacity > _largestCapacity) then { _largestCapacity = _garrisonCapacity; _garrisonCenterBuilding = _candidateCenterBuilding };
		if (_garrisonCapacity >= _garrisonComplement) exitWith { };
	};

	if (_largestCapacity < _garrisonComplement && not _matchAny) exitWith { false };

	[_data, "garrison-position", getPos _garrisonCenterBuilding] call SPM_Util_SetDataValue;
	[_data, "garrison-capacity", _largestCapacity] call SPM_Util_SetDataValue;

	true
};

OO_TRACE_DECL(SPM_Chain_Execute) =
{
	params ["_data", "_chain"];

	private _chainComplete = false;
	private _linkIndex = 0;
	private _direction = 1;

	while { true } do
	{
		private _link = _chain select _linkIndex;

		private _parameters = [_data, _direction] + (_link select 1);
		private _function = (_link select 0);
		private _success = (_parameters call _function);

		if (not _success && _linkIndex == 0) exitWith { _chainComplete = false };
		if (_success && _linkIndex == (count _chain - 1)) exitWith { _chainComplete = true };

		_direction = if (_success) then { 1 } else { -1 };
		_linkIndex = _linkIndex + _direction;
	};

	_chainComplete
};