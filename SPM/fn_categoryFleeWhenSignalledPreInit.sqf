/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

//TODO: Coalesce units into a group when they're trying to use the same vehicle.  Pack 'em in.

OO_TRACE_DECL(SPM_FleeWhenSignalled_IsUsableTransport) =
{
	params ["_vehicle", "_group"];

	if (not canMove _vehicle) exitWith { false };

	if (locked _vehicle == 2) exitWith { false };
	
	if (count crew _vehicle != 0) exitWith { false };

	if (count fullCrew [_vehicle, "", true] < count units _group) exitWith { false };
	
	private _group = _vehicle getVariable "SPM_FleeingGroup";

	if (isNil "_group") exitWith { true };

	if (isNull _group) exitWith { true };

	false
};

#define CAR_SEARCH_DISTANCE 100

OO_TRACE_DECL(SPM_FleeWhenSignalled_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	if (not OO_GET(_category,FleeWhenSignalledCategory,_Fleeing)) then
	{
		private _signalGarrison = OO_GET(_category,FleeWhenSignalledCategory,SignalGarrison);
		private _groupHasSignalled = OO_GET(_category,FleeWhenSignalledCategory,GroupHasSignalled);

		{
			private _unit = OO_GET(_x,ForceUnit,Vehicle);
			if (_unit == leader group _unit && { [_category, group _unit] call _groupHasSignalled }) exitWith { OO_SET(_category,FleeWhenSignalledCategory,_Fleeing,true) };
		} forEach OO_GET(_signalGarrison,ForceCategory,ForceUnits);

		if (OO_GET(_category,FleeWhenSignalledCategory,_Fleeing)) then
		{
			private _fleeGarrison = OO_GET(_category,FleeWhenSignalledCategory,FleeGarrison);
			private _getFleeDestination = OO_GET(_category,FleeWhenSignalledCategory,GetFleeDestination);
			{
				private _unit = OO_GET(_x,ForceUnit,Vehicle);
				if (_unit == leader group _unit && { not isNil { [_category, group _unit] call _getFleeDestination } }) then
				{
					[group _unit] call SPM_DeletePatrolWaypoints;
					[_fleeGarrison, units group _unit] call SPM_InfantryGarrison_LeaveBuilding;
					group _unit setBehaviour "aware";
					group _unit setSpeedMode "full";
				};
			} forEach OO_GET(_fleeGarrison,ForceCategory,ForceUnits);
		};
	};

	if (OO_GET(_category,FleeWhenSignalledCategory,_Fleeing)) then
	{
		private _mission = OO_GETREF(_category,Category,Strongpoint);
		private _missionPosition = OO_GET(_mission,Strongpoint,Position);
		private _missionRadius = OO_GET(_mission,Strongpoint,ActivityRadius);

		private _fleeGarrison = OO_GET(_category,FleeWhenSignalledCategory,FleeGarrison);
		private _getFleeDestination = OO_GET(_category,FleeWhenSignalledCategory,GetFleeDestination);

		private _sideWest = OO_GET(_fleeGarrison,ForceCategory,SideWest);

		{
			private _unit = OO_GET(_x,ForceUnit,Vehicle);
			private _group = group _unit;
			private _fleeDestination = [];
			if (_unit == leader _group && { _fleeDestination = [_category, _group] call _getFleeDestination; not isNil "_fleeDestination" }) then
			{
				private _waypointType = waypointType [_group, currentWaypoint _group];

				// If no waypoint, create an exit waypoint
				if (_waypointType == "") then
				{
					// Delete the group and its vehicle when they reach the exit point
					private _salvage =
					{
						params ["_leader", "_units"];

						private _group = group _leader;
						if (vehicle _leader != _leader) then { deleteVehicle vehicle _leader };
						{ deleteVehicle _x } forEach (_units select { alive _x });
						deleteGroup _group;
					};

					private _waypoint = [_group, _fleeDestination] call SPM_AddPatrolWaypoint;
					_waypoint setWaypointType "move";
					[_waypoint, _salvage] call SPM_AddPatrolWaypointStatements;

					// Make sure they hustle unless they're clearly engaged
					[_group, 10] call SPM_InfantryGarrison_GroupAdvance;
				};

				// If the group is on foot and it doesn't have a getin waypoint, see if there's a vehicle nearby that they can use
				if (vehicle _unit == _unit) then
				{
					if (_waypointType != "getin") then
					{
						// Find out the distance to the closest known living enemy
						private _targets = (_unit targets [true, 200]) select { alive _x } apply { _x distance _unit };
						_targets pushBack (CAR_SEARCH_DISTANCE * 2);
						_targets sort true;

						// Look for cars that are half the distance to the closest enemy
						private _cars = (_unit nearEntities ["Car", (_targets select 0) / 2]) select { [_x, _group] call SPM_FleeWhenSignalled_IsUsableTransport };

						if (count _cars > 0) then
						{
							private _factionCars = _cars select { faction _x == faction _unit };
							if (count _factionCars > 0) then { _cars = _factionCars };

							private _car = selectRandom _cars;

							_car setVariable ["SPM_FleeingGroup", _group];

							// Insert a waypoint that tells the group to get into the car
							private _waypoint = [_group, getPos _car, 0, currentWaypoint _group] call SPM_AddPatrolWaypoint;
							_waypoint setWaypointType "getin";
							_waypoint waypointAttachVehicle _car;
						};
					};
				};
			};
		} forEach OO_GET(_fleeGarrison,ForceCategory,ForceUnits);
	};
};

OO_TRACE_DECL(SPM_FleeWhenSignalled_Create) =
{
	params ["_category", "_signalGarrison", "_fleeGarrison"];

	OO_SET(_category,FleeWhenSignalledCategory,SignalGarrison,_signalGarrison);
	OO_SET(_category,FleeWhenSignalledCategory,FleeGarrison,_fleeGarrison);
};

OO_BEGIN_SUBCLASS(FleeWhenSignalledCategory,Category);
	OO_OVERRIDE_METHOD(FleeWhenSignalledCategory,Root,Create,SPM_FleeWhenSignalled_Create);
	OO_OVERRIDE_METHOD(FleeWhenSignalledCategory,Category,Update,SPM_FleeWhenSignalled_Update);
	OO_DEFINE_PROPERTY(FleeWhenSignalledCategory,SignalGarrison,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(FleeWhenSignalledCategory,FleeGarrison,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(FleeWhenSignalledCategory,GroupHasSignalled,"CODE",{true});
	OO_DEFINE_PROPERTY(FleeWhenSignalledCategory,GetFleeDestination,"CODE",{true});
	OO_DEFINE_PROPERTY(FleeWhenSignalledCategory,_Fleeing,"BOOL",false);
OO_END_SUBCLASS(FleeWhenSignalledCategory);