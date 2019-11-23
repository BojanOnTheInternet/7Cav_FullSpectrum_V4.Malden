/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_TransportRequestAir_WS_Salvage) =
{
	params ["_leader", "_units", "_request"];

	private _operation = OO_GETREF(_request,TransportRequest,Operation);
	private _category = OO_GETREF(_operation,TransportOperation,Category);

	[_request] call OO_GET(_request,TransportRequest,OnSalvage);
	[_category, group _leader] call SPM_Force_SalvageForceUnit;

	OO_SET(_request,TransportRequest,State,"complete");
};

OO_TRACE_DECL(SPM_TransportRequestAir_AddExitWaypoint) =
{
	params ["_request", "_transportGroup", "_exitDistance"];

	private _operation = OO_GETREF(_request,TransportRequest,Operation);
	private _spawnpoint = OO_GET(_operation,TransportOperation,Spawnpoint);

	private _area = OO_GET(_operation,TransportOperation,Area);

	private _toSpawnpoint = OO_GET(_area,StrongpointArea,Position) vectorFromTo (_spawnpoint select 0);
	private _exitPosition = (_spawnpoint select 0) vectorAdd (_toSpawnpoint vectorMultiply _exitDistance);

	private _waypoint = [_transportGroup, _exitPosition] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
	[_waypoint, SPM_TransportRequestAir_WS_Salvage, _request] call SPM_AddPatrolWaypointStatements;

	// Add another waypoint so they'll pass through the prior waypoint at speed
	private _waypoint = [_transportGroup, [0,0,0]] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
};

OO_TRACE_DECL(SPM_TransportRequestAir_WS_ParadropCargo) =
{
	params ["_leader", "_units", "_request"];

	[_request] call OO_GET(_request,TransportRequest,OnArrive);
};

OO_TRACE_DECL(SPM_TransportRequestAir_DropPosition) =
{
	params ["_areaCenter", "_areaRadius", "_dropRadius"];

	private _dropPositions = [_areaCenter, 0, _areaRadius, _areaRadius * 0.2] call SPM_Util_SampleAreaGrid;
	[_dropPositions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_dropPositions, _dropRadius, ["BUILDING", "HOUSE", "ROCK", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;

	if (count _dropPositions == 0) exitWith { _areaCenter };

	_dropPositions = _dropPositions apply { [_x distanceSqr _areaCenter, _x] };
	_dropPositions sort true;
	_dropPositions select 0 select 1
};


OO_TRACE_DECL(SPM_TransportRequestAir_AddParadropWaypoint) =
{
	params ["_request", "_transportGroup", "_transportVehicle", "_paratroopers", "_dropPosition"];

	private _direction = (getPos _transportVehicle) vectorFromTo _dropPosition;
	_direction set [2,0];
	_direction = vectorNormalized _direction;

	// Back up the start of the drop to anticipate the time it takes to drop the troops.  But don't back up right into deep water.
	private _scan = _dropPosition;
	private _i = 0;
	for "_i" from 1 to _paratroopers do
	{
		if (getTerrainHeightASL _scan < -1.0) exitWith {};
		_scan = _scan vectorAdd (_direction vectorMultiply -12); // Roughly 24m spacing on the drop at speed, back up half the distance of the 'stick'
	};
//	_scan = _scan vectorAdd (_direction vectorMultiply -100); // Back up farther for the delay in opening a parachute at speed
	_scan set [2,50]; // Set the drop altitude

	private _startDropWaypoint = [_transportGroup, _scan] call SPM_AddPatrolWaypoint;
	_startDropWaypoint setWaypointBehaviour "careless";
	_startDropWaypoint setWaypointType "move";
	_startDropWaypoint setWaypointSpeed "full";
	[_startDropWaypoint, SPM_TransportRequestAir_WS_ParadropCargo, _request] call SPM_AddPatrolWaypointStatements;

	private _distantPosition = _dropPosition vectorAdd (_direction vectorMultiply 600);
	_distantPosition set [2, 50];
	private _distantWaypoint = [_transportGroup, _distantPosition] call SPM_AddPatrolWaypoint;
	_distantWaypoint setWaypointType "move";
};

OO_TRACE_DECL(SPM_TransportRequestAir_DeployTransport) =
{
	params ["_category", "_operation", "_request", "_transportGroup", "_transportVehicle"];

	private _destination = OO_GET(_request,TransportRequest,Destination);
	private _paratroopers = OO_GET(_request,TransportRequest,Passengers);

	private _dropPosition = [_destination, 400, _paratroopers * 5] call SPM_TransportRequestAir_DropPosition;

	[_request, _transportGroup, _transportVehicle, _paratroopers, _dropPosition] call SPM_TransportRequestAir_AddParadropWaypoint;
	[_request, _transportGroup, 600] call SPM_TransportRequestAir_AddExitWaypoint;

	OO_SET(_request,TransportRequest,State,"to-destination");
};

OO_TRACE_DECL(SPM_TransportRequestAir_CreateUnit) =
{
	params ["_category", "_operation", "_request", "_position", "_direction"];

	private _transportCallup = OO_GET(_request,TransportRequest,VehicleCallup);
	if (count _transportCallup == 0) then
	{
		private _callups = OO_GET(_operation,TransportOperation,VehicleCallups);
		//TODO: Filter the transports based on the number of passengers specified in the request
		_transportCallup = selectRandom _callups;
	};

	private _transportVehicle = [_transportCallup select 0, _position, _direction, "fly"] call SPM_fnc_spawnVehicle;
	_transportVehicle setVehicleTIPars [1.0, 0.5, 0.0]; // Start vehicle hot so it shows on thermals
	[_transportVehicle] call (_transportCallup select 1 select 3);

	private _crew = [_transportVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewSide = _crew select 0;
	private _crewDescriptor = _crew select 1;

	private _transportGroup = [_crewSide, [[_transportVehicle]] + _crewDescriptor, [_transportVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;
	[_category, _transportGroup] call OO_GET(_category,Category,InitializeObject);
	[_category, _transportVehicle] call OO_GET(_category,Category,InitializeObject);

	private _forceUnit = [_transportVehicle, units _transportGroup] call OO_CREATE(ForceUnit);
	OO_SET(_request,TransportRequest,ForceUnit,_forceUnit);

	if (not ([_request] call OO_GET(_request,TransportRequest,OnLoad))) exitWith
	{
		[_forceUnit] call SPM_Force_DeleteForceUnit;
		[]
	};

	[_category, _operation, _request, _transportGroup, _transportVehicle] call SPM_TransportRequestAir_DeployTransport;

	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;
	private _force = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceRatings;

	if (count _force > 0) then
	{
		private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_force select 0,ForceRating,Rating);
		OO_SET(_category,ForceCategory,Reserves,_reserves);
	};

	_forceUnit
};

OO_TRACE_DECL(SPM_TransportRequestAir_CallUp) =
{
	params ["_position", "_direction", "_category", "_operation", "_request"];

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _forceUnit = [_category, _operation, _request, _position, _direction] call SPM_TransportRequestAir_CreateUnit;

	if (count _forceUnit == 0) exitWith
	{
		OO_SET(_request,TransportRequest,State,"complete");
	};

	[OO_GET(_forceUnit,ForceUnit,Vehicle), 20, 10, 20] call SPM_Util_WaitForVehicleToMove;

	if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle) || { _position distance OO_GET(_forceUnit,ForceUnit,Vehicle) < 10 }) then
	{
		[_request] call OO_GET(_request,TransportRequest,OnSalvage);
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
		OO_SET(_request,TransportRequest,State,"complete");
	}
	else
	{
		OO_SET(_request,TransportRequest,State,"to-destination");
	};
};

OO_TRACE_DECL(SPM_TransportRequestAir_Update) =
{
	params ["_request", "_category", "_operation"];

	switch (OO_GET(_request,TransportRequest,State)) do
	{
		case "create":
		{
			private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
			private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);
			private _spawnpoint = OO_GET(_operation,TransportOperation,Spawnpoint);
			[_spawnpoint select 0, _spawnpoint select 1, SPM_TransportRequestAir_CallUp, [_category, _operation, _request]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
			OO_SET(_request,TransportRequest,State,"pending");

			private _airDefense = OO_NULL;
			{
				if (OO_INSTANCE_ISOFCLASS(_x,AirDefenseCategory)) exitWith { _airDefense = _x };
			} forEach OO_GET(_strongpoint,Strongpoint,Categories);

			if (not OO_ISNULL(_airDefense)) then
			{
				[_spawnpoint select 0] call OO_METHOD(_airDefense,AirDefenseCategory,RequestSupport);
			};
		};

		case "pending": {};

		default
		{
			private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
			private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
			if (not alive _vehicle) then
			{
				[_request] call OO_GET(_request,TransportRequest,OnArrive);
			};
		};
	};
};

OO_BEGIN_SUBCLASS(TransportRequestAir,TransportRequest);
	OO_OVERRIDE_METHOD(TransportRequestAir,TransportRequest,Update,SPM_TransportRequestAir_Update);
OO_END_SUBCLASS(TransportRequestAir);