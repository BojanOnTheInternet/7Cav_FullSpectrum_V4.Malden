/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_BEGIN_STRUCT(ConvoyData);
	OO_DEFINE_PROPERTY(ConvoyData,Alive,"BOOL",true);
	OO_DEFINE_PROPERTY(ConvoyData,Mobile,"BOOL",true);
	OO_DEFINE_PROPERTY(ConvoyData,LoadState,"STRING","loaded");
	OO_DEFINE_PROPERTY(ConvoyData,UnloadPosition,"ARRAY",[]);
OO_END_STRUCT(ConvoyData);

OO_TRACE_DECL(SPM_ConvoySpacing_Create) =
{
	params ["_convoySpacing", "_tightStopSqr", "_tightSlowSqr", "_normalSqr", "_looseSlowSqr", "_looseStopSqr"];

	if (not isNil "_tightStopSqr") then { OO_SET(_convoySpacing,ConvoySpacing,TightStopSqr,_tightStopSqr) };
	if (not isNil "_tightSlowSqr") then { OO_SET(_convoySpacing,ConvoySpacing,TightSlowSqr,_tightSlowSqr) };
	if (not isNil "_normalSqr") then { OO_SET(_convoySpacing,ConvoySpacing,NormalSqr,_normalSqr) };
	if (not isNil "_looseStopSqr") then { OO_SET(_convoySpacing,ConvoySpacing,LooseStopSqr,_looseStopSqr) };
	if (not isNil "_looseSlowSqr") then { OO_SET(_convoySpacing,ConvoySpacing,LooseSlowSqr,_looseSlowSqr) };
};

OO_BEGIN_STRUCT(ConvoySpacing);
	OO_OVERRIDE_METHOD(ConvoySpacing,RootStruct,Create,SPM_ConvoySpacing_Create);
	OO_DEFINE_PROPERTY(ConvoySpacing,TightStopSqr,"SCALAR",30^2);
	OO_DEFINE_PROPERTY(ConvoySpacing,TightSlowSqr,"SCALAR",40^2);
	OO_DEFINE_PROPERTY(ConvoySpacing,NormalSqr,"SCALAR",50^2);
	OO_DEFINE_PROPERTY(ConvoySpacing,LooseSlowSqr,"SCALAR",70^2);
	OO_DEFINE_PROPERTY(ConvoySpacing,LooseStopSqr,"SCALAR",100^2);
OO_END_STRUCT(ConvoySpacing);

OO_TRACE_DECL(SPM_ConvoyVehicle_Create) =
{
	params ["_convoyVehicle", "_vehicleType", "_vehicleInitializer", "_groupDescriptors", "_convoySpacing"];

	OO_SET(_convoyVehicle,ConvoyVehicle,VehicleType,_vehicleType);
	OO_SET(_convoyVehicle,ConvoyVehicle,VehicleInitializer,_vehicleInitializer);
	OO_SET(_convoyVehicle,ConvoyVehicle,GroupDescriptors,_groupDescriptors);
	OO_SET(_convoyVehicle,ConvoyVehicle,ConvoySpacing,_convoySpacing);
};

OO_BEGIN_STRUCT(ConvoyVehicle);
	OO_OVERRIDE_METHOD(ConvoyVehicle,RootStruct,Create,SPM_ConvoyVehicle_Create);
	OO_DEFINE_PROPERTY(ConvoyVehicle,VehicleType,"STRING","");
	OO_DEFINE_PROPERTY(ConvoyVehicle,VehicleInitializer,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ConvoyVehicle,ConvoySpacing,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ConvoyVehicle,GroupDescriptors,"ARRAY",[]);
OO_END_STRUCT(ConvoyVehicle);

//TODO: This is really a RestructureConvoy routine that needs to detach disabled vehicles, fill empty crew positions and mount up everyone possible
OO_TRACE_DECL(SPM_MissionInterceptConvoy_ReplaceMissingCrewmen) =
{
	params ["_vehicles", "_transportCrewmen", "_passengers"];

	private _assignedPassengers = [];
	private _orphanedPassengers = [];
	{
		(if (alive assignedVehicle _x) then { _assignedPassengers } else { _orphanedPassengers }) pushBack [0, _x];
	} forEach _passengers;

	private _assignedCrewmen = [];
	private _orphanedCrewmen = [];
	{
		(if (alive assignedVehicle _x) then { _assignedCrewmen } else { _orphanedCrewmen }) pushBack [0, _x];
	} forEach _transportCrewmen;

	private _crewGroups = _vehicles apply { private _group = grpNull; { if (not isNull group _x) exitWith { _group = group _x } } forEach [driver _x, gunner _x, commander _x]; _group };

	private _getVehicleSeats =
	{
		params ["_seatName", "_vehicles", "_assignedCrewmen"];

		private _vehicleSeats = _vehicles apply { fullCrew [_x, _seatName, true] };

		private _vehicleSeat = [];
		private _assignedRole = [];
		{
			if (count _x > 0) then
			{
				_vehicle = _vehicles select _forEachIndex;
				_vehicleSeat = _x select 0;

				if (count _vehicleSeat > 0 && { isNull (_vehicleSeat select 0) }) then
				{
					{
						private _assignedCrewman = _x select 1;
						if (assignedVehicle _assignedCrewman == _vehicle) then
						{
							_assignedRole = assignedVehicleRole _assignedCrewman;
							switch (_seatName) do
							{
								case "driver":
								{
									if ((_assignedRole select 0) == "driver" && (_vehicleSeat select 1) == "driver") then { _vehicleSeat set [0, _assignedCrewman] };
								};
								case "gunner":
								{
									if ((_assignedRole select 0) == "Turret" && (_assignedRole select 1) isEqualTo (_vehicleSeat select 3)) then { _vehicleSeat set [0, _assignedCrewman] };
								};
								case "commander":
								{
									if ((_assignedRole select 0) == "Turret" && (_assignedRole select 1) isEqualTo (_vehicleSeat select 3)) then { _vehicleSeat set [0, _assignedCrewman] };
								};
							};
						};
					} forEach _assignedCrewmen;
				};
			};
		} forEach _vehicleSeats;

		_vehicleSeats;
	};

	private _replaceCrewmen =
	{
		params ["_seatName", "_vehicles", "_crewGroups", "_assignedCrewmen", "_orphanedCrewmen", "_assignedPassengers", "_orphanedPassengers"];

		{
			private _vehicleSeat = _x;

			if (count _vehicleSeat > 0) then
			{
				private _crewman = _vehicleSeat select 0 select 0;

				if (not alive _crewman) then
				{
					private _candidates = if (count _orphanedCrewmen > 0) then { _orphanedCrewmen } else { if (count _orphanedPassengers > 0) then { _orphanedPassengers} else { _assignedPassengers } };

					if (count _candidates == 0) exitWith { diag_log format ["SPM_MissionInterceptConvoy_ReplaceMissingCrewmen: insufficient replacements to fill all empty vehicle crew positions"] };

					private _vehicle = _vehicles select _forEachIndex;
#ifdef OO_TRACE
					diag_log format ["SPM_MissionInterceptConvoy_ReplaceMissingCrewmen: replacing %1 on %2", _vehicleSeat select 1, _vehicle];
#endif
					{
						_x set [0, _vehicle distance (_x select 1)];
					} forEach _candidates;
					_candidates sort true;

					_crewman = (_candidates deleteAt 0) select 1;

					_vehicleSeat select 0 set [0, _crewman];

					if (assignedVehicle _crewman == _vehicle) then { [_crewman] orderGetIn false };
					switch (_seatName) do
					{
						case "driver": { _crewman assignAsDriver _vehicle };
						case "gunner": { _crewman assignAsGunner _vehicle };
						case "commander": { _crewman assignAsCommander _vehicle };
					};

					_assignedCrewmen pushBack [0, _crewman];
				};

				if (not isNull _crewman) then
				{
					private _crewGroup = _crewGroups select _forEachIndex;
					if (isNull _crewGroup) then { _crewGroup = createGroup side _crewman; _crewGroups set [_forEachIndex, _crewGroup] };
					[_crewman] join _crewGroup;
				};
			};
		} forEach ([_seatName, _vehicles, _assignedCrewmen] call _getVehicleSeats);
	};

	["driver", _vehicles, _crewGroups, _assignedCrewmen, _orphanedCrewmen, _assignedPassengers, _orphanedPassengers] call _replaceCrewmen;
	["gunner", _vehicles, _crewGroups, _assignedCrewmen, _orphanedCrewmen, _assignedPassengers, _orphanedPassengers] call _replaceCrewmen;
	["commander", _vehicles, _crewGroups, _assignedCrewmen, _orphanedCrewmen, _assignedPassengers, _orphanedPassengers] call _replaceCrewmen;

	[_assignedCrewmen apply { _x select 1 }, _orphanedCrewmen apply { _x select 1 }, _assignedPassengers apply { _x select 1 }, _orphanedPassengers apply { _x select 1 }]
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_UpdateConvoy) =
{
	params ["_mission"];

	private _operation = OO_GET(_mission,MissionInterceptConvoy,ConvoyOperation);
	private _requests = OO_GET(_operation,TransportOperation,Requests);

	private _transport = OO_GETREF(_operation,TransportOperation,Category);
	private _sideWest = OO_GET(_transport,TransportCategory,SideWest);

	// Each vehicle occupies one slot in the convoy
	private _allSlots = _requests apply { private _forceUnit = OO_GET(_x,TransportRequest,ForceUnit); if (count _forceUnit == 0) then { [_x, objNull] } else { [_x, OO_GET(_forceUnit,ForceUnit,Vehicle)] } };
	{
		if (not isNull (_x select 1) && { isNil { (_x select 1) getVariable "SPM_MissionInterceptConvoy_Data" } }) then
		{
			(_x select 1) setVariable ["SPM_MissionInterceptConvoy_Data", [] call OO_CREATE(ConvoyData)];
		};
	} forEach _allSlots;

	_activeSlots = _allSlots select { alive (_x select 1) && side (_x select 1) != _sideWest };

	if (count _activeSlots == 0) exitWith {};

	// If close to end, stop babysitting and direct vehicles to individual destinations
	if (OO_GET(_mission,Strongpoint,Position) distance getPos (_activeSlots select 0 select 1) < 200) exitWith
	{
		if (not OO_GET(_mission,MissionInterceptConvoy,_Arriving)) then
		{
			OO_SET(_mission,MissionInterceptConvoy,_Arriving,true);
			{
				private _request = _x select 0;
				private _vehicle = _x select 1;
				[_vehicle, -1] call JB_fnc_limitSpeed;
				driver _vehicle setSpeedMode "limited";

				private _convoyDestination = OO_GET(_request,TransportRequest,Destination);
				private _vehicleDestination = [_convoyDestination, 100] call SPM_Util_OpenPositionForVehicle;
				OO_SET(_request,TransportRequest,Destination,_vehicleDestination);
				[] call OO_METHOD(_request,TransportRequestGround,CommandResume);
			} forEach _activeSlots;
		};
	};

	private _passengers = OO_GET(_mission,MissionInterceptConvoy,_Passengers);
	for "_i" from count _passengers - 1 to 0 step -1 do
	{
		if (not alive (_passengers select _i)) then { _passengers deleteAt _i };
	};

	private _transportCrewmen = OO_GET(_mission,MissionInterceptConvoy,_Crewmen);
	for "_i" from count _transportCrewmen - 1 to 0 step -1 do
	{
		if (not alive (_transportCrewmen select _i)) then { _transportCrewmen deleteAt _i };
	};

	private _dismounts = _passengers select { vehicle _x == _x };

	// If the infanty chose to dismount for any reason, then unload the convoy
	if (count _dismounts > 0) then
	{
		private _loadedVehicles = { private _data = (_x select 1) getVariable "SPM_MissionInterceptConvoy_Data"; OO_GET(_data,ConvoyData,LoadState) == "loaded" } count _activeSlots;
		if (_loadedVehicles > 0) then
		{
#ifdef OO_TRACE
			diag_log "SPM_MissionInterceptConvoy_UpdateConvoy: unloading because infantry spontaneously dismounted";
#endif
			{ private _data = (_x select 1) getVariable "SPM_MissionInterceptConvoy_Data"; OO_SET(_data,ConvoyData,LoadState,"unload-ordered") } forEach _activeSlots;
			OO_SET(_mission,MissionInterceptConvoy,_UnloadOrderTime,diag_tickTime);
		};
	};

	// Update the state of the vehicles, triggering convoy unloads as appropriate
	{
		private _vehicle = _x select 1;
		private _convoyData = _vehicle getVariable "SPM_MissionInterceptConvoy_Data";
#ifdef OO_TRACE
		diag_log format ["SPM_MissionInterceptConvoy_UpdateConvoy: convoyData: %1", _convoyData];
#endif
		if (not alive _vehicle) then
		{
			if (OO_GET(_convoyData,ConvoyData,Alive)) then // Vehicle was just destroyed
			{
#ifdef OO_TRACE
				diag_log "SPM_MissionInterceptConvoy_UpdateConvoy: unloading because a vehicle was destroyed";
#endif
				OO_SET(_convoyData,ConvoyData,Alive,false);
				OO_SET(_convoyData,ConvoyData,Mobile,false);

				{ private _data = (_x select 1) getVariable "SPM_MissionInterceptConvoy_Data"; OO_SET(_data,ConvoyData,LoadState,"unload-ordered") } forEach _activeSlots;
				OO_SET(_mission,MissionInterceptConvoy,_UnloadOrderTime,diag_tickTime);
			};
		}
		else
		{
			if (([_vehicle] call SPM_Util_VehicleMobilityDamage) >= 0.25 || (not alive driver _vehicle)) then
			{
				if (OO_GET(_convoyData,ConvoyData,Mobile)) then // Vehicle was just disabled
				{
#ifdef OO_TRACE
					diag_log "SPM_MissionInterceptConvoy_UpdateConvoy: unloading because a vehicle was disabled";
#endif

					OO_SET(_convoyData,ConvoyData,Mobile,false);

					{ private _data = (_x select 1) getVariable "SPM_MissionInterceptConvoy_Data"; OO_SET(_data,ConvoyData,LoadState,"unload-ordered") } forEach _activeSlots;
					OO_SET(_mission,MissionInterceptConvoy,_UnloadOrderTime,diag_tickTime);
				};
			}
			else
			{
				if (not OO_GET(_convoyData,ConvoyData,Mobile)) then // Vehicle was just repaired
				{
					OO_SET(_convoyData,ConvoyData,Mobile,true);
				};
			};
		};
	} forEach (_allSlots select { not isNull (_x select 1) });

	{
		private _request = _x select 0;
		private _vehicle = _x select 1;
		private _convoyData = _vehicle getVariable "SPM_MissionInterceptConvoy_Data";
		if (OO_GET(_convoyData,ConvoyData,LoadState) == "unload-ordered") then // Should unload
		{
			OO_SET(_convoyData,ConvoyData,LoadState,"unloading");
			[] call OO_METHOD(_request,TransportRequestGround,CommandStop);
		};
//		[_vehicle, "MIC2", nil] call TRACE_SetObjectString;
	} forEach _activeSlots;

	// Any given unload will last at least 60 seconds
	if (diag_tickTime > OO_GET(_mission,MissionInterceptConvoy,_UnloadOrderTime) + 60) then
	{
		// If no dismounts, then mark all vehicles as loaded
		if (count _dismounts == 0) then
		{
			OO_SET(_mission,MissionInterceptConvoy,_UnloadOrderTime,1e30);
			{
				private _vehicle = (_x select 0);
				private _convoyData = (_x select 1) getVariable "SPM_MissionInterceptConvoy_Data";
				OO_SET(_convoyData,ConvoyData,LoadState,"loaded");
			} forEach _activeSlots;
		}
		else
		{
			// If all dismounts are out of combat, order a load if it hasn't been done already.  We want to get the convoy on the move.
			if ({ behaviour _x in ["COMBAT", "STEALTH"] } count _dismounts == 0) then
			{
				private _vehiclesInOrder = true;
				{
					private _request = _x select 0;
					private _vehicle = _x select 1;
//					[_vehicle, "MIC2", "out-of-combat"] call TRACE_SetObjectString;
					private _convoyData = _vehicle getVariable "SPM_MissionInterceptConvoy_Data";
					private _convoyPosition = OO_GET(_convoyData,ConvoyData,UnloadPosition);
					if (_vehicle distance _convoyPosition > 15) then
					{
						[_convoyPosition] call OO_METHOD(_request,TransportRequestGround,CommandMove);
						_vehiclesInOrder = false;
					};
				} forEach _activeSlots;
				
				if (_vehiclesInOrder) then
				{
					private _orderConvoyLoad = false;
					{
						private _vehicle = _x select 1;
						private _convoyData = _vehicle getVariable "SPM_MissionInterceptConvoy_Data";
						if (OO_GET(_convoyData,ConvoyData,LoadState) == "unloaded") then
						{
							OO_SET(_convoyData,ConvoyData,LoadState,"loading");
							_orderConvoyLoad = true;
						};
//						[_vehicle, "MIC2", "in-convoy-order"] call TRACE_SetObjectString;
					} forEach _activeSlots;

					if (_orderConvoyLoad) then
					{
						private _results = [_activeSlots apply { _x select 1 }, _transportCrewmen, _dismounts] call SPM_MissionInterceptConvoy_ReplaceMissingCrewmen;

						_transportCrewmen = _results select 0;
						OO_SET(_mission,MissionInterceptConvoy,_Crewmen,_transportCrewmen);

						private _orphanedCrewmen = (_results select 1) + OO_GET(_mission,MissionInterceptConvoy,_OrphanedCrewmen);
						OO_SET(_mission,MissionInterceptConvoy,_OrphanedCrewmen,_orphanedCrewmen);

						_passengers = _results select 2;
						OO_SET(_mission,MissionInterceptConvoy,_Passengers,_passengers);

						private _orphanedPassengers = (_results select 3) + OO_GET(_mission,MissionInterceptConvoy,_OrphanedPassengers);
						OO_SET(_mission,MissionInterceptConvoy,_OrphanedPassengers,_orphanedPassengers);

						//TODO: If there are orphaned convoy members, move them into empty cargo and passenger turret spots (and take them out of the orphan lists).  Any left over should be garrisoned in a nearby building.

						{
							[group _x] call SPM_DeletePatrolWaypoints;
						} forEach _dismounts;

						_dismounts allowGetIn true;
						_dismounts orderGetIn true;

						_transportCrewmen orderGetIn true;
					};
				};
			};
		};
	};

	{
		private _vehicle = _x select 1;
		private _convoyData = _vehicle getVariable "SPM_MissionInterceptConvoy_Data";
//		[_vehicle, "MIC", format ["%1", OO_GET(_convoyData,ConvoyData,LoadState)]] call TRACE_SetObjectString;
	} forEach _activeSlots;

	// If any vehicle is not in the "loaded" state, we're not moving
	if ({ private _convoyData = (_x select 1) getVariable "SPM_MissionInterceptConvoy_Data"; OO_GET(_convoyData,ConvoyData,LoadState) != "loaded" } forEach _activeSlots) exitWith {};

	// Get the spacing information for each vehicle in the convoy
	// Objective doesn't provide one.  Gotta build that routine that lets objectives put in a request
	private _convoySpacings = _activeSlots apply { private _request = _x select 0; private _convoyVehicle = OO_GET(_request,TransportRequest,ClientData) select 0 select 0; OO_GET(_convoyVehicle,ConvoyVehicle,ConvoySpacing) };
#ifdef OO_TRACE
	diag_log format ["SPM_MissionInterceptConvoy_UpdateConvoy: convoySpacings: %1", _convoySpacings];
#endif
	// Find out the room in front of each vehicle
	private _currentSpacings = [];
	{ _currentSpacings pushBack (if (_forEachIndex == 0) then { 0 } else { (_activeSlots select _forEachIndex select 1) distanceSqr (_activeSlots select (_forEachIndex - 1) select 1) }) } forEach _activeSlots;

	private _fullSpeed = OO_GET(_mission,MissionInterceptConvoy,ConvoySpeed);
	private _halfSpeed = _fullSpeed * 0.5;

	// Find out if any vehicles have fallen back, causing the lead vehicle to slow or stop
	private _leadVehicleSpeed = _fullSpeed;
	{
		if ((_currentSpacings select _forEachIndex) > OO_GET(_x,ConvoySpacing,LooseStopSqr)) exitWith
		{
			_leadVehicleSpeed = 0;
		};

		if ((_currentSpacings select _forEachIndex) > OO_GET(_x,ConvoySpacing,LooseSlowSqr)) then
		{
			_leadVehicleSpeed = _halfSpeed;
		};
	} forEach _convoySpacings;

	// Pick speeds for each vehicle based on how close it is to the vehicle in front of it
	private _speeds = [_leadVehicleSpeed];
	for "_i" from 1 to (count _convoySpacings - 1) do
	{
		private _convoySpacing = _convoySpacings select _i;
		private _currentSpacing = _currentSpacings select _i;

		if (_currentSpacing < OO_GET(_convoySpacing,ConvoySpacing,TightStopSqr)) then
		{
			_speeds pushBack 0;
		}
		else
		{
			if (_currentSpacing < OO_GET(_convoySpacing,ConvoySpacing,TightSlowSqr)) then
			{
				_speeds pushBack _halfSpeed;
			}
			else
			{
				if (_currentSpacing < OO_GET(_convoySpacing,ConvoySpacing,NormalSqr)) then
				{
					_speeds pushBack (_speeds select (_i - 1));
				}
				else
				{
					_speeds pushBack _fullSpeed;
				};
			};
		};
	};

#ifdef OO_TRACE
	diag_log format ["SPM_MissionInterceptConvoy_UpdateConvoy: speeds %1", _speeds];
	diag_log format ["SPM_MissionInterceptConvoy_UpdateConvoy: current spacings %1", _currentSpacings];
#endif
	for "_i" from 0 to (count _speeds - 1) do
	{
		private _speed = _speeds select _i;

		private _slot = _activeSlots select _i;
		private _request = _slot select 0;
		private _vehicle = _slot select 1;

		if (_speed == 0) then
		{
			if (speed _vehicle > 0) then
			{
				[] call OO_METHOD(_request,TransportRequestGround,CommandStop);
			};
		}
		else
		{
			if (speed _vehicle == 0) then
			{
				[] call OO_METHOD(_request,TransportRequestGround,CommandResume);
			};
		};

		// If the vehicles are to move at a specific speed, set a speed limit.  Otherwise, let them go (this impacts player capture scenarios)
		[_vehicle, if (_speed > 0) then { _speed } else { -1 }] call JB_fnc_limitSpeed;
	};
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_GetMissionDescription) =
{
	params ["_mission"];

	private _objectiveDescriptions = [];
	{
		_objectiveDescriptions pushBack (_x select 2 select 0);
	} forEach OO_GET(_mission,Mission,NotificationsAccumulator);

	private _convoyDirection = OO_GET(_mission,MissionInterceptConvoy,ConvoyDirection);
	private _directionDescription = [_convoyDirection] call SPM_Util_DirectionDescription;

	private _convoyRoute = OO_GET(_mission,MissionInterceptConvoy,ConvoyRoute);
	private _originDescription = [_convoyRoute select 0] call SPM_Util_PositionDescription;

	["Mission Orders", "Intercept convoy departing " + _originDescription, "heading " + _directionDescription] + _objectiveDescriptions
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_Update) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Strongpoint,Update,MissionSpecialOperations);

	// Announce on second update pass.  This is atypical because we're just having objectives go active before the vehicles in the convoy are created.  On the first update,
	// the objectives announce and we accumulate the announcements.  On the second update, we make the actual mission-level announcement.
	if (OO_GET(_mission,Mission,Announced) == "none" && OO_GET(_mission,Strongpoint,UpdateIndex) == 2) then
	{
		private _description = [] call OO_METHOD(_mission,MissionSpecialOperations,GetMissionDescription);

		OO_SET(_mission,Mission,Announced,"start-of-mission");
		[_mission, OO_NULL, _description, "mission-description"] call OO_GET(_mission,Strongpoint,SendNotification);
	};

	if (diag_tickTime > OO_GET(_mission,MissionInterceptConvoy,_StartOfMission)) then
	{
		private _transport = OO_GET(_mission,MissionInterceptConvoy,_Transport);
		if (count OO_GET(_transport,TransportCategory,Operations) == 0) then
		{
			private _convoyOperation = OO_GET(_mission,MissionInterceptConvoy,ConvoyOperation);
			[_convoyOperation] call OO_METHOD(_transport,TransportCategory,AddOperation);
		};

		[_mission] call SPM_MissionInterceptConvoy_UpdateConvoy;
	};
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_TransportOnLoad) =
{
	params ["_request"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	private _missionData = _clientData select 0;
	if (count _missionData > 0) then
	{
		private _convoyVehicle = _missionData select 0;
		private _mission = OO_INSTANCE(_missionData select 1);

		private _vehicleInitializer = OO_GET(_convoyVehicle,ConvoyVehicle,VehicleInitializer);
		private _groupDescriptors = OO_GET(_convoyVehicle,ConvoyVehicle,GroupDescriptors);

		([_vehicle] + (_vehicleInitializer select 1)) call (_vehicleInitializer select 0);

		OO_GET(_mission,MissionInterceptConvoy,_Crewmen) append crew _vehicle;

		private _category = OO_GET(_mission,Strongpoint,Categories) select 0; //TODO: Get these troops from a garrison that's part of the mission

		private _units = [];
		{
			private _side = _x select 0;
			private _descriptor = _x select 1;
			private _group = [_side, [[_vehicle]] + _descriptor, call SPM_Util_RandomSpawnPosition, 0, true, ["cargo", "turret"]] call SPM_fnc_spawnGroup;
			_units append units _group;
			[_category, _group] call OO_GET(_category,Category,InitializeObject);
		} forEach _groupDescriptors;

		// Delete any that didn't fit
		for "_i" from count _units - 1 to 0 step -1 do
		{
			if (vehicle (_units select _i) != _vehicle) then { deleteVehicle (_units deleteAt _i) }
		};

		OO_GET(_mission,MissionInterceptConvoy,_Passengers) append _units;
	};

	true
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_TransportOnUpdate) =
{
	params ["_request"];
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_TransportOnArrive) =
{
	params ["_request", "_state"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

#ifdef OO_TRACE
	diag_log format ["SPM_MissionInterceptConvoy_TransportOnArrive: vehicle: %1", _vehicle];
#endif

	if (not alive _vehicle) exitWith {};

	private _convoyData = _vehicle getVariable "SPM_MissionInterceptConvoy_Data";

#ifdef OO_TRACE
	diag_log format ["SPM_MissionInterceptConvoy_TransportOnArrive: state: %1", OO_GET(_request,TransportRequest,State)];
	diag_log format ["SPM_MissionInterceptConvoy_TransportOnArrive: convoyData: %1", _convoyData];
#endif
	if (OO_GET(_convoyData,ConvoyData,LoadState) == "unloading") then
	{
		private _vehiclePosition = getPos _vehicle;
		OO_SET(_convoyData,ConvoyData,UnloadPosition,_vehiclePosition);

		private _clientData = OO_GET(_request,TransportRequest,ClientData);
		private _missionData = _clientData select 0;
		if (count _missionData > 0) then
		{
			private _mission = OO_INSTANCE(_missionData select 1);
			private _passengers = OO_GET(_mission,MissionInterceptConvoy,_Passengers);

			_passengers = _passengers select { assignedVehicle _x == _vehicle };

			_passengers orderGetIn false;
			_passengers allowGetIn false;
		
			OO_SET(_convoyData,ConvoyData,LoadState,"unloaded");

			private _groups = [];
			{ _groups pushBackUnique group _x } forEach _passengers;

			{
				[_x, getPos _vehicle, 50, 100, random 1 < 0.5] call SPM_fnc_patrolPerimeter;
			} forEach _groups;
		};
	};
};

// Delete any troops that are still onboard the transport
OO_TRACE_DECL(SPM_MissionInterceptConvoy_TransportOnSalvage) =
{
	params ["_request"];

	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	private _missionData = _clientData select 0;
	if (count _missionData > 0) then
	{
		private _mission = OO_INSTANCE(_missionData select 1);
		private _passengers = OO_GET(_mission,MissionInterceptConvoy,_Passengers);

		private _transportForceUnit = OO_GET(_request,TransportRequest,ForceUnit);
		if (count _transportForceUnit > 0) then
		{
			private _transportVehicle = OO_GET(_transportForceUnit,ForceUnit,Vehicle);
			if (not isNil "_transportVehicle" && { not isNull _transportVehicle }) then
			{
				private _troops = (fullCrew [_transportVehicle, "turret"] + fullCrew [_transportVehicle, "cargo"]);
				_troops = _troops apply { _x select 0 };

				private _groups = [];
				{
					_groups pushBackUnique group _x;
				} forEach _troops;

				{
					{
						private _index = _passengers find _x;
						if (_index >= 0) then { deleteVehicle (_passengers deleteAt _index) };
					} forEach units _x;
					if (count units _x == 0) then { deleteGroup _x };
				} forEach _groups;
			};
		};
	};
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_AddObjective) =
{
	params ["_mission", "_objective"];

	[_objective] call OO_METHOD_PARENT(_mission,Mission,AddObjective,Mission);

	if (OO_INSTANCE_ISOFCLASS(_objective,ConvoyObjective)) then
	{
		private _convoyOperation = OO_GET(_mission,MissionInterceptConvoy,ConvoyOperation);
		[_convoyOperation] call OO_METHOD(_objective,ConvoyObjective,ModifyConvoyOperation);
	};
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_CreateRequest) =
{
	params ["_mission", "_convoyVehicle"];

	private _vehicleCallup = [OO_GET(_convoyVehicle,ConvoyVehicle,VehicleType), [0,0,{}]];
	private _clientData = [[_convoyVehicle, OO_REFERENCE(_mission)]]; // Mission controls first array element, objectives can tack on stuff after that.

	_request = [0, [0,0,0]] call OO_CREATE(TransportRequestGround);
	OO_SET(_request,TransportRequest,OnLoad,SPM_MissionInterceptConvoy_TransportOnLoad);
	OO_SET(_request,TransportRequest,OnUpdate,SPM_MissionInterceptConvoy_TransportOnUpdate);
	OO_SET(_request,TransportRequest,OnArrive,SPM_MissionInterceptConvoy_TransportOnArrive);
	OO_SET(_request,TransportRequest,OnSalvage,SPM_MissionInterceptConvoy_TransportOnSalvage);
	OO_SET(_request,TransportRequest,VehicleCallup,_vehicleCallup);
	OO_SET(_request,TransportRequest,ClientData,_clientData);

	_request
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_CreateConvoyOperation) =
{
	params ["_mission", "_spawnpoint", "_destination", "_convoyDescription"];

	private _area = [_destination, 0, 100] call OO_CREATE(StrongpointArea);
	private _operation = [_area, _spawnpoint] call OO_CREATE(TransportOperation);

	{
		private _request = [_x] call OO_METHOD(_mission,MissionInterceptConvoy,CreateRequest);
		OO_SET(_request,TransportRequest,Destination,_destination); // All must use exact same destination
		[_request] call OO_METHOD(_operation,TransportOperation,AddRequest);
	} forEach _convoyDescription;

	_operation
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_Create) =
{
	params ["_mission", "_convoyRoute", "_convoyDescription", "_convoyStartTime", "_convoySpeed"];

	private _startIndex = 0;
	private _endIndex = count _convoyRoute - 1;
	private _startDirection = (_convoyRoute select _startIndex) getDir (_convoyRoute select (_startIndex + 1));

	private _spawnpoint = [(_convoyRoute select _startIndex) vectorAdd [-1 + random 2.0, -1 + random 2.0, 0.25], _startDirection];
	private _destination = _convoyRoute select _endIndex;

	[_destination, 10, (_spawnpoint select 0) distance _destination, -1] call OO_METHOD_PARENT(_mission,Root,Create,Mission);

	OO_SET(_mission,Strongpoint,Name,"Special Operation");
	OO_SET(_mission,Strongpoint,InitializeObject,SERVER_InitializeCategoryObject);
	OO_SET(_mission,Strongpoint,GetUpdateInterval,{2});

	OO_SET(_mission,Mission,ParticipantFilter,BOTH_IsSpecOpsMember);

	OO_SET(_mission,MissionInterceptConvoy,_StartOfMission,_convoyStartTime);
	OO_SET(_mission,MissionInterceptConvoy,ConvoyRoute,_convoyRoute);

	private _convoyDirection = (_convoyRoute select _startIndex) getDir (_convoyRoute select _endIndex);
	OO_SET(_mission,MissionInterceptConvoy,ConvoyDirection,_convoyDirection);

	if (not isNil "_convoySpeed") then
	{
		OO_SET(_mission,MissionInterceptConvoy,ConvoySpeed,_convoySpeed);
	};

	private _area = OO_NULL;
	private _category = OO_NULL;
	private _categories = [];

	_category = [] call OO_CREATE(TransportCategory);
	OO_SET(_category,TransportCategory,GroundTransports,SPM_Transport_CallupsEastMarid);
	_categories pushBack _category;

	OO_SET(_mission,MissionInterceptConvoy,_Transport,_category);

	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _categories;

	private _convoyOperation = [_mission, _spawnpoint, _destination, _convoyDescription] call SPM_MissionInterceptConvoy_CreateConvoyOperation;
	OO_SET(_mission,MissionInterceptConvoy,ConvoyOperation,_convoyOperation);
};

OO_TRACE_DECL(SPM_MissionInterceptConvoy_Delete) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Strongpoint);

	private _groups = [];
	{
		_groups pushBackUnique group _x;
		deleteVehicle _x;
	} forEach OO_GET(_mission,MissionInterceptConvoy,_Passengers);

	{
		_groups pushBackUnique group _x;
		deleteVehicle _x;
	} forEach OO_GET(_mission,MissionInterceptConvoy,_OrphanedPassengers);

	{
		deleteGroup _x;
	} forEach _groups;
};

OO_BEGIN_SUBCLASS(ConvoyObjective,MissionObjective);
	OO_DEFINE_METHOD(ConvoyObjective,ModifyConvoyOperation,{});
OO_END_SUBCLASS(ConvoyObjective);

OO_BEGIN_SUBCLASS(MissionInterceptConvoy,MissionSpecialOperations);
	OO_OVERRIDE_METHOD(MissionInterceptConvoy,Root,Create,SPM_MissionInterceptConvoy_Create);
	OO_OVERRIDE_METHOD(MissionInterceptConvoy,Root,Delete,SPM_MissionInterceptConvoy_Delete);
	OO_OVERRIDE_METHOD(MissionInterceptConvoy,Strongpoint,Update,SPM_MissionInterceptConvoy_Update);
	OO_OVERRIDE_METHOD(MissionInterceptConvoy,Mission,AddObjective,SPM_MissionInterceptConvoy_AddObjective);
	OO_OVERRIDE_METHOD(MissionInterceptConvoy,MissionSpecialOperations,GetMissionDescription,SPM_MissionInterceptConvoy_GetMissionDescription);
	OO_DEFINE_METHOD(MissionInterceptConvoy,CreateRequest,SPM_MissionInterceptConvoy_CreateRequest);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,ConvoyOperation,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,ConvoyRoute,"ARRAY",[]);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,ConvoyDirection,"SCALAR",0);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,ConvoySpeed,"SCALAR",40);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,_StartOfMission,"SCALAR",1e30);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,_Transport,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,_Crewmen,"ARRAY",[]);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,_Passengers,"ARRAY",[]);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,_OrphanedCrewmen,"ARRAY",[]);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,_OrphanedPassengers,"ARRAY",[]);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,_UnloadOrderTime,"SCALAR",1e30);
	OO_DEFINE_PROPERTY(MissionInterceptConvoy,_Arriving,"BOOL",false);
OO_END_SUBCLASS(MissionInterceptConvoy);
