/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

//#define ENABLEATTACK true

#define STOPPED_DESTINATION [-1]

// The speed below which a transport should not fire, and only move
#define VEHICLE_MOVING_SPEED 10

#define GROUND_TRANSPORT_SPEED 40
// The hypothetical speed that the transport must maintain if it is going to avoid being shooed along by the monitor (m/s)
#define GROUND_TRANSPORT_CLOSING_SPEED (20 * 1000 / 3600)

SPM_TransportRequestGround_MonitoredVehicles = []; // [vehicle,destination,time,state]
SPM_TransportRequestGround_Monitor = scriptNull;

OO_TRACE_DECL(SPM_GroundTransportMonitor_Create) =
{
	params ["_monitor", "_vehicle", "_destination"];

	OO_SET(_monitor,GroundTransportMonitor,Vehicle,_vehicle);
	OO_SET(_monitor,GroundTransportMonitor,Destination,_destination);

	private _arrivalTime = diag_tickTime + (_vehicle distance _destination) / GROUND_TRANSPORT_CLOSING_SPEED;
	OO_SET(_monitor,GroundTransportMonitor,ArrivalTime,_arrivalTime);
};

OO_TRACE_DECL(SPM_GroundTransportMonitor_ForceMoving) =
{
	params ["_monitor"];

	OO_SET(_monitor,GroundTransportMonitor,State,"force-moving");
	private _vehicle = OO_GET(_monitor,GroundTransportMonitor,Vehicle);
	[[commander _vehicle, gunner _vehicle, driver _vehicle]] call SPM_Util_AIOnlyMove;
	//BUG: Playing games to get vehicle to notice the doMove
	_vehicle doMove (getPos _vehicle vectorAdd [1,1,0]);
	_vehicle doMove (OO_GET(_monitor,GroundTransportMonitor,Destination) vectorAdd [random 10, random 10, 0]);
	[_vehicle, "GTM", "Force Moving"] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_GroundTransportMonitor_PermitFiring) =
{
	params ["_monitor"];

	OO_SET(_monitor,GroundTransportMonitor,State,"permit-firing");
	private _vehicle = OO_GET(_monitor,GroundTransportMonitor,Vehicle);
	[_vehicle] call SPM_TransportRequestGround_ConfigureCrewForDuty;
	//BUG: Playing games to get vehicle to notice the doMove
	_vehicle doMove (getPos _vehicle vectorAdd [1,1,0]);
	_vehicle doMove (OO_GET(_monitor,GroundTransportMonitor,Destination) vectorAdd [random 10, random 10, 0]);
	[_vehicle, "GTM", "Permit Firing"] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_GroundTransportMonitor_DetachVehicle) =
{
	params ["_monitor"];

	private _vehicle = OO_GET(_monitor,GroundTransportMonitor,Vehicle);
	OO_SET(_monitor,GroundTransportMonitor,Vehicle,objNull);
	[_vehicle] call SPM_TransportRequestGround_ConfigureCrewForDuty;
	[_vehicle, "GTM", nil] call TRACE_SetObjectString;
};

OO_BEGIN_STRUCT(GroundTransportMonitor);
	OO_OVERRIDE_METHOD(GroundTransportMonitor,RootStruct,Create,SPM_GroundTransportMonitor_Create);
	OO_DEFINE_METHOD(GroundTransportMonitor,ForceMoving,SPM_GroundTransportMonitor_ForceMoving);
	OO_DEFINE_METHOD(GroundTransportMonitor,PermitFiring,SPM_GroundTransportMonitor_PermitFiring);
	OO_DEFINE_METHOD(GroundTransportMonitor,DetachVehicle,SPM_GroundTransportMonitor_DetachVehicle);
	OO_DEFINE_PROPERTY(GroundTransportMonitor,Vehicle,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(GroundTransportMonitor,Destination,"ARRAY",[]);
	OO_DEFINE_PROPERTY(GroundTransportMonitor,ArrivalTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(GroundTransportMonitor,State,"STRING","permit-firing"); //  permit-firing, force-moving
OO_END_STRUCT(GroundTransportMonitor);

OO_TRACE_DECL(SPM_TransportRequestGround_MonitorVehicles) =
{
	private _vehicle = objNull;
	private _arrivalTime = 0;

	while { sleep 1; SPM_TransportRequestGround_MonitoredVehicles = SPM_TransportRequestGround_MonitoredVehicles select { alive OO_GET(_x,GroundTransportMonitor,Vehicle) }; count SPM_TransportRequestGround_MonitoredVehicles > 0 } do
	{
		{
			_vehicle = OO_GET(_x,GroundTransportMonitor,Vehicle);

			// The vehicle must beat a pessimistic, predicted arrival time or be forced to move
			_arrivalTime = diag_tickTime + (_vehicle distance OO_GET(_x,GroundTransportMonitor,Destination)) / GROUND_TRANSPORT_CLOSING_SPEED;

			if (_arrivalTime > OO_GET(_x,GroundTransportMonitor,ArrivalTime)) then
			{
				if (OO_GET(_x,GroundTransportMonitor,State) == "permit-firing" && { not unitReady _vehicle } && { canMove _vehicle }) then { [] call OO_METHOD(_x,GroundTransportMonitor,ForceMoving) };
			}
			else
			{
				if (OO_GET(_x,GroundTransportMonitor,State) == "force-moving" && { canFire _vehicle } && { [_vehicle] call SPM_Util_HasOffensiveWeapons }) then { [] call OO_METHOD(_x,GroundTransportMonitor,PermitFiring) };
			};
		} forEach SPM_TransportRequestGround_MonitoredVehicles;
	};
};

OO_TRACE_DECL(SPM_TransportRequestGround_StartMonitoringVehicle) =
{
	params ["_vehicle", "_destination"];

	if (isNull _vehicle) exitWith { diag_log format ["SPM_TransportRequestGround_StartMonitoringVehicle: null vehicle ignored"] };

	private _monitor = [];
	{
		if (OO_GET(_x,GroundTransportMonitor,Vehicle) == _vehicle) exitWith { _monitor = _x; OO_SET(_x,GroundTransportMonitor,Destination,_destination) };
	} forEach SPM_TransportRequestGround_MonitoredVehicles;

	if (count _monitor == 0) then
	{
		_monitor = [_vehicle, _destination] call OO_CREATE(GroundTransportMonitor);
		SPM_TransportRequestGround_MonitoredVehicles pushBack _monitor;

		if (canFire _vehicle && { [_vehicle] call SPM_Util_HasOffensiveWeapons }) then
		{
			[] call OO_METHOD(_monitor,GroundTransportMonitor,PermitFiring);
		}
		else
		{
			[] call OO_METHOD(_monitor,GroundTransportMonitor,ForceMoving);
		};
	};

	if (isNull SPM_TransportRequestGround_Monitor) then
	{
		SPM_TransportRequestGround_Monitor = [] spawn SPM_TransportRequestGround_MonitorVehicles;
	};

	0 // If no value is returned here, the OO_TRACE_DECL stuff causes problems
};

OO_TRACE_DECL(SPM_TransportRequestGround_StopMonitoringVehicle) =
{
	params ["_vehicle"];

	if (isNull _vehicle) exitWith { diag_log format ["SPM_TransportRequestGround_StopMonitoringVehicle: null vehicle ignored"] };

	private _matchedVehicle = false;
	{
		if (OO_GET(_x,GroundTransportMonitor,Vehicle) == _vehicle) exitWith
		{
			_matchedVehicle = true;
			[] call OO_METHOD(_x,GroundTransportMonitor,DetachVehicle);
		};
	} forEach SPM_TransportRequestGround_MonitoredVehicles;
};

OO_TRACE_DECL(SPM_TransportRequestGround_CommandMoveToCover) =
{
	params ["_request", "_radius", "_samples"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	if (not canMove _transportVehicle) exitWith { false };

	private _center = (getPos _transportVehicle) vectorAdd ((vectorDir _transportVehicle) vectorMultiply _radius);

	private _samplingInterval = (_radius * 2) / round sqrt _samples;

	private _filteredPositions = [];
	private _positions = [_center, 0, _radius, _samplingInterval] call SPM_Util_SampleAreaGrid;
	[_positions, ["#GdtWater", "#GdtRoad"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 2.0, ["BUILDING", "HOUSE", "ROCK", "WALL"]] call SPM_Util_ExcludeSamplesByProximity;
	[_positions, 10.0, ["BUILDING", "HOUSE", "ROCK"], _filteredPositions] call SPM_Util_ExcludeSamplesByProximity;

	_positions = _filteredPositions; // _filteredPositions contains positions between 2m and 10m from cover objects

	if (count _positions == 0) exitWith { false };

	_positions = _positions apply { [_transportVehicle distance _x, _x] };
	_positions sort true;

	private _destination = _positions select 0 select 1;

#ifdef ENABLEATTACK
	(group driver _transportVehicle) enableAttack false;
	_transportVehicle doMove _destination;
#else
	[_transportVehicle] call SPM_TransportRequestGround_ConfigureCrewForDuty;
	_transportVehicle doMove _destination;
	[_transportVehicle, _destination] call SPM_TransportRequestGround_StartMonitoringVehicle;
#endif

	OO_SET(_request,TransportRequestGround,CurrentDestination,_destination);
	OO_SET(_request,TransportRequestGround,ArrivedCurrentDestination,false);
	OO_SET(_request,TransportRequest,State,"to-cover");

	[_transportVehicle, "TRG", "MoveToCover"] call TRACE_SetObjectString;
	[_transportVehicle, "TRG", _destination] call TRACE_SetObjectPosition;

	true
};

OO_TRACE_DECL(SPM_TransportRequestGround_CommandMoveToClearing) =
{
	params ["_request", "_radius", "_samples"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	if (not canMove _transportVehicle) exitWith { false };

	private _center = (getPos _transportVehicle) vectorAdd ((vectorDir _transportVehicle) vectorMultiply _radius);

	private _samplingInterval = (_radius * 2) / round sqrt _samples;

	private _filteredPositions = [];
	private _positions = [_center, 0, _radius, _samplingInterval] call SPM_Util_SampleAreaGrid;
	[_positions, ["#GdtWater", "#GdtRoad"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 5.0, ["BUILDING", "HOUSE", "ROCK", "WALL"]] call SPM_Util_ExcludeSamplesByProximity;

	if (count _positions == 0) exitWith { false };

	private _destination = selectRandom _positions;

#ifdef ENABLEATTACK
	(group driver _transportVehicle) enableAttack false;
	_transportVehicle doMove _destination;
#else
	[_transportVehicle] call SPM_TransportRequestGround_ConfigureCrewForDuty;
	_transportVehicle doMove _destination;
	[_transportVehicle, _destination] call SPM_TransportRequestGround_StartMonitoringVehicle;
#endif
	OO_SET(_request,TransportRequestGround,CurrentDestination,_destination);
	OO_SET(_request,TransportRequestGround,ArrivedCurrentDestination,false);
	OO_SET(_request,TransportRequest,State,"to-clearing");

	[_transportVehicle, "TRG", "MoveToClearing"] call TRACE_SetObjectString;
	[_transportVehicle, "TRG", _destination] call TRACE_SetObjectPosition;

	true
};

OO_TRACE_DECL(SPM_TransportRequestGround_CommandMove) =
{
	params ["_request", "_destination"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	if (not canMove _transportVehicle) exitWith { false };

#ifdef ENABLEATTACK
	(group driver _transportVehicle) enableAttack false;
	_transportVehicle doMove _destination;
#else
	[_transportVehicle] call SPM_TransportRequestGround_ConfigureCrewForDuty;
	_transportVehicle doMove _destination;
	[_transportVehicle, _destination] call SPM_TransportRequestGround_StartMonitoringVehicle;
#endif

	OO_SET(_request,TransportRequestGround,CurrentDestination,_destination);
	OO_SET(_request,TransportRequestGround,ArrivedCurrentDestination,false);
	OO_SET(_request,TransportRequest,State,"move");

	[_transportVehicle, "TRG", "Move"] call TRACE_SetObjectString;
	[_transportVehicle, "TRG", _destination] call TRACE_SetObjectPosition;

	true
};

OO_TRACE_DECL(SPM_TransportRequestGround_SalvageOnArrive) =
{
	params ["_request"];

	[_request] call OO_GET(_request,TransportRequest,OnSalvage);

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);

	private _group = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroup);
	[_category, _group] call SPM_Force_SalvageForceUnit;

	OO_SET(_request,TransportRequest,State,"complete");

	private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
	[_transportVehicle, "TRG", "Salvage"] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_TransportRequestGround_CommandRetire) =
{
	params ["_request"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	if (canMove _transportVehicle) then
	{
		private _destination = [_request, 50] call SPM_TransportRequestGround_GetExitPosition;
		OO_SET(_request,TransportRequest,Destination,_destination);
		[] call OO_METHOD(_request,TransportRequestGround,CommandResume);
		OO_SET(_request,TransportRequest,OnArrive,SPM_TransportRequestGround_SalvageOnArrive);
	};
};

OO_TRACE_DECL(SPM_TransportRequestGround_CommandResume) =
{
	params ["_request"];

	private _destination = OO_GET(_request,TransportRequest,Destination);

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	[_transportVehicle] call SPM_TransportRequestGround_ConfigureCrewForDuty;
	_transportVehicle doMove _destination;
	[_transportVehicle, _destination] call SPM_TransportRequestGround_StartMonitoringVehicle;

	OO_SET(_request,TransportRequestGround,CurrentDestination,_destination);
	OO_SET(_request,TransportRequestGround,ArrivedCurrentDestination,false);
	OO_SET(_request,TransportRequest,State,"to-destination");

	[_transportVehicle, "TRG", "Resume"] call TRACE_SetObjectString;
	[_transportVehicle, "TRG", _destination] call TRACE_SetObjectPosition;
};

OO_TRACE_DECL(SPM_TransportRequestGround_CommandStop) =
{
	params ["_request"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	doStop _transportVehicle;
	[_transportVehicle] call SPM_TransportRequestGround_StopMonitoringVehicle;

	OO_SET(_request,TransportRequestGround,CurrentDestination,STOPPED_DESTINATION);
	OO_SET(_request,TransportRequestGround,ArrivedCurrentDestination,false);
	OO_SET(_request,TransportRequest,State,"stopped");

	[_transportVehicle, "TRG", "Stop"] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_TransportRequestGround_VehicleAdjacentPosition) =
{
	params ["_vehicle", "_position", "_distance"];

//	[_vehicle, "TRG4", format ["(%1/%2)", ((sizeOf typeOf _vehicle) / 2) + _distance, _vehicle distance _position]] call TRACE_SetObjectString;

	((sizeOf typeOf _vehicle) / 2) + _distance > _vehicle distance _position
};

OO_TRACE_DECL(SPM_TransportRequestGround_UpdateGround) =
{
	params ["_request", "_category", "_operation"];

	[_request] call OO_GET(_request,TransportRequest,OnUpdate);

	if (not OO_GET(_request,TransportRequestGround,ArrivedCurrentDestination)) then
	{
		private _currentDestination = OO_GET(_request,TransportRequestGround,CurrentDestination);

		private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
		private _transportVehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

		private _arrived = false;
		if (alive effectiveCommander _transportVehicle && unitReady effectiveCommander _transportVehicle) then { _arrived = true; [_transportVehicle, "TRG", "Arrived-Ready"] call TRACE_SetObjectString };
		if (not canMove _transportVehicle) then { _arrived = true; [_transportVehicle, "TRG", "Arrived-Immobile"] call TRACE_SetObjectString };
		if ({ vehicle _x == _x && alive _x } count OO_GET(_forceUnit,ForceUnit,Units) > 0) then { _arrived = true; [_transportVehicle, "TRG", "Arrived-Dismounted"] call TRACE_SetObjectString };

		if (_currentDestination isEqualTo STOPPED_DESTINATION) then
		{
			_arrived = true; [_transportVehicle, "TRG", "Arrived-Stopped"] call TRACE_SetObjectString
		}
		else
		{
			private _distance = _transportVehicle distance _currentDestination;

			if (_distance < 100 && { _transportVehicle isKindOf "Ship" } && { getTerrainHeightASL (getPos _transportVehicle) > -2 }) then { _arrived = true; [_transportVehicle, "TRG", "Arrived-Shallow"] call TRACE_SetObjectString };
			if (_distance < 20) then { _arrived = true; [_transportVehicle, "TRG", "Arrived-Distance"] call TRACE_SetObjectString };
		};

		if (_arrived) then
		{
			OO_SET(_request,TransportRequestGround,ArrivedCurrentDestination,true);
			[_request] call OO_GET(_request,TransportRequest,OnArrive);
		};
	};
};

OO_TRACE_DECL(SPM_TransportRequestGround_GetExitPosition) =
{
	params ["_request", "_exitDistance"];

	private _operation = OO_GETREF(_request,TransportRequest,Operation);
	private _spawnpoint = OO_GET(_operation,TransportOperation,Spawnpoint);
	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	private _area = OO_GET(_operation,TransportOperation,Area);

	private _toSpawnpoint = OO_GET(_area,StrongpointArea,Position) vectorFromTo (_spawnpoint select 0);
	private _exitPosition = (_spawnpoint select 0) vectorAdd (_toSpawnpoint vectorMultiply _exitDistance);

	private _excludedPositions = [];
	private _positions = [];
	private _innerRadius = 0;
	private _outerRadius = _exitDistance min 50;
	while { count _positions == 0 } do
	{
		_positions = [_exitPosition, _innerRadius, _outerRadius, 10] call SPM_Util_SampleAreaGrid;
		_excludedPositions = [];
		[_positions, ["#GdtWater"], _excludedPositions] call SPM_Util_ExcludeSamplesBySurfaceType;
		if (_vehicle isKindOf "Ship") then { _positions = _excludedPositions };
		[_positions, 5.0, ["WALL", "BUILDING", "HOUSE", "ROCK"]] call SPM_Util_ExcludeSamplesByProximity;

		_innerRadius = _outerRadius;
		_outerRadius = _outerRadius + 50;
	};

	if (count _positions == 0) exitWith { _spawnpoint select 0 }; //TODO: Need a better backup than this

	selectRandom _positions;
};

OO_TRACE_DECL(SPM_TransportRequestGround_ConfigureCrewForDuty) =
{	
	params ["_transportVehicle"];

	if (not ([_transportVehicle] call SPM_Util_HasOffensiveWeapons)) exitWith
	{
		[[driver _transportVehicle, gunner _transportVehicle, commander _transportVehicle]] call SPM_Util_AIOnlyMove;
	};

	if (not isNull commander _transportVehicle) then
	{
		commander _transportVehicle disableAI "all";
		commander _transportVehicle enableAI "teamswitch";
		commander _transportVehicle enableAI "target";
		commander _transportVehicle enableAI "autotarget";
		commander _transportVehicle enableAI "autocombat";
		commander _transportVehicle enableAI "checkvisible";
	};

	if (not isNull gunner _transportVehicle) then
	{
		gunner _transportVehicle enableAI "all";
		gunner _transportVehicle disableAI "cover";
		gunner _transportVehicle disableAI "suppression";
	};

	if (not isNull driver _transportVehicle) then
	{
		driver _transportVehicle enableAI "all";
		driver _transportVehicle disableAI "cover";
		driver _transportVehicle disableAI "suppression";
	};
};

OO_TRACE_DECL(SPM_TransportRequestGround_DeployTransport) =
{
	params ["_category", "_operation", "_request", "_transportVehicle"];

	[] call OO_METHOD(_request,TransportRequestGround,CommandResume);
};

OO_TRACE_DECL(SPM_TransportRequestGround_CreateUnit) =
{
	params ["_category", "_operation", "_request", "_position", "_direction"];

	private _transportCallup = OO_GET(_request,TransportRequest,VehicleCallup);
	if (count _transportCallup == 0) then
	{
		private _callups = OO_GET(_operation,TransportOperation,VehicleCallups);
		//TODO: Filter the transports based on the number of passengers specified in the request
		_transportCallup = selectRandom _callups;
	};

	private _transportVehicle = [_transportCallup select 0, _position, _direction, ""] call SPM_fnc_spawnVehicle;
	_transportVehicle setVehicleTIPars [1.0, 0.5, 0.0]; // Start vehicle hot so it shows on thermals
	[_transportVehicle] call (_transportCallup select 1 select 3);

	private _crew = [_transportVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewSide = OO_GET(_category,TransportCategory,SideEast);
	private _crewDescriptor = _crew select 1;

	private _transportGroup = [_crewSide, [[_transportVehicle]] + _crewDescriptor, [_transportVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;
	(driver _transportVehicle) setUnitTrait ["engineer", true];
	(driver _transportVehicle) addBackpack "B_LegStrapBag_black_repair_F";

	[_category, _transportGroup] call OO_GET(_category,Category,InitializeObject);
	[_category, _transportVehicle] call OO_GET(_category,Category,InitializeObject);

	_transportGroup setSpeedMode "full"; // "limited" on tracked vehicles is around 30km/h
	[_transportVehicle, GROUND_TRANSPORT_SPEED] call JB_fnc_limitSpeed;

	private _forceUnit = [_transportVehicle, units _transportGroup] call OO_CREATE(ForceUnit);
	OO_SET(_request,TransportRequest,ForceUnit,_forceUnit);

	if (not ([_request] call OO_GET(_request,TransportRequest,OnLoad))) exitWith
	{
		[_forceUnit] call SPM_Force_DeleteForceUnit;
		[]
	};

	[_category, _operation, _request, _transportVehicle] call SPM_TransportRequestGround_DeployTransport;

	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;
	private _force = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceRatings;

	if (count _force > 0) then
	{
		private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_force select 0,ForceRating,Rating);
		OO_SET(_category,ForceCategory,Reserves,_reserves);
	};

	_forceUnit
};

OO_TRACE_DECL(SPM_TransportRequestGround_CallUp) =
{
	params ["_position", "_direction", "_category", "_operation", "_request"];

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _forceUnit = [_category, _operation, _request, _position, _direction] call SPM_TransportRequestGround_CreateUnit;

	if (count _forceUnit == 0) exitWith
	{
		OO_SET(_request,TransportRequest,State,"complete");
	};

	[OO_GET(_forceUnit,ForceUnit,Vehicle), 20, 10, 20] call SPM_Util_WaitForVehicleToMove;

	if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle) || { _position distance2D OO_GET(_forceUnit,ForceUnit,Vehicle) < 10 }) then
	{
		[_request] call OO_GET(_request,TransportRequest,OnSalvage);
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
		OO_SET(_request,TransportRequest,State,"complete");
	};
};

OO_TRACE_DECL(SPM_TransportRequestGround_Update) =
{
	params ["_request", "_category", "_operation"];

	switch (OO_GET(_request,TransportRequest,State)) do
	{
		case "create":
		{
			private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
			private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);
			private _spawnpoint = OO_GET(_operation,TransportOperation,Spawnpoint);
			[_spawnpoint select 0, _spawnpoint select 1, SPM_TransportRequestGround_CallUp, [_category, _operation, _request]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
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
			}
			else
			{
				[_request, _category, _operation] call SPM_TransportRequestGround_UpdateGround;
			};
		};
	};
};

OO_BEGIN_SUBCLASS(TransportRequestGround,TransportRequest);
	OO_OVERRIDE_METHOD(TransportRequestGround,TransportRequest,Update,SPM_TransportRequestGround_Update);
	OO_DEFINE_METHOD(TransportRequestGround,CommandMoveToClearing,SPM_TransportRequestGround_CommandMoveToClearing);
	OO_DEFINE_METHOD(TransportRequestGround,CommandMoveToCover,SPM_TransportRequestGround_CommandMoveToCover);
	OO_DEFINE_METHOD(TransportRequestGround,CommandMove,SPM_TransportRequestGround_CommandMove);
	OO_DEFINE_METHOD(TransportRequestGround,CommandResume,SPM_TransportRequestGround_CommandResume);
	OO_DEFINE_METHOD(TransportRequestGround,CommandRetire,SPM_TransportRequestGround_CommandRetire);
	OO_DEFINE_METHOD(TransportRequestGround,CommandStop,SPM_TransportRequestGround_CommandStop);
	OO_DEFINE_PROPERTY(TransportRequestGround,Controls,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequestGround,CurrentDestination,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequestGround,ArrivedCurrentDestination,"BOOL",false);
OO_END_SUBCLASS(TransportRequestGround);
