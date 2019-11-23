/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_HeadquartersReinforced_Create) =
{
	params ["_objective", "_communicationCenter"];

	OO_SETREF(_objective,HeadquartersReinforcedCategory,CommunicationCenter,_communicationCenter);
};

OO_TRACE_DECL(SPM_HeadquartersReinforced_Delete) =
{
	params ["_objective"];

	[_objective] call SPM_HeadquartersReinforced_DeleteTraceObject;
	[_objective] call SPM_HeadquartersReinforced_DeleteMarkers;
};

OO_TRACE_DECL(SPM_HeadquartersReinforced_Command) =
{
	params ["_objective", "_command", "_parameters"];

	switch (_command) do
	{
		case "minimize":
		{
			[_objective] call SPM_HeadquartersReinforced_DeleteTraceObject;
			[_objective] call SPM_HeadquartersReinforced_DeleteMarkers;
		};
	};
};

OO_TRACE_DECL(SPM_HeadquartersReinforced_UpdateReserves) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);

	// Add mobilized reinforcements to the garrison's reserves
	private _garrisonReserves = OO_GET(_garrison,ForceCategory,Reserves);
	private _reinforcements = OO_GET(_objective,HeadquartersReinforcedCategory,_MobilizedReinforcements);
	OO_SET(_objective,HeadquartersReinforcedCategory,_MobilizedReinforcements,0.0);
	_garrisonReserves = _garrisonReserves + _reinforcements;
	OO_SET(_garrison,ForceCategory,Reserves,_garrisonReserves);

	// If no more reserves will be made available and we cannot form a unit from the available reserve, set the reserves to zero
	if (_garrisonReserves > 1e-4) then
	{
		private _communicationCenter = OO_GETREF(_objective,HeadquartersReinforcedCategory,CommunicationCenter);

		if (not OO_GET(_communicationCenter,CommunicationCenterCategory,CommunicationsOnline) || OO_GET(_objective,HeadquartersReinforcedCategory,ReinforcementPool) < 1e-4) then
		{
			if (_garrisonReserves < selectMin (OO_GET(_garrison,ForceCategory,CallupsEast) apply { (_x select 1 select 0) * (_x select 1 select 1) })) then { OO_SET(_garrison,ForceCategory,Reserves,0.0) };
		};
	};
};

OO_TRACE_DECL(SPM_HeadquartersReinforced_CreateMarkers) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);

	// Place a marker indicating the area controlled by the garrison
	private _garrisonArea = OO_GET(_garrison,ForceCategory,Area);
	private _operationMarker = createMarker [format ["Headquarters-Reinforced%1", OO_REFERENCE(_objective)], OO_GET(_garrisonArea,StrongpointArea,Position)];
	_operationMarker setMarkerShape "ellipse";
	_operationMarker setMarkerColor "colorred";
	_operationMarker setMarkerBrush "border";
	_operationMarker setMarkerSize [OO_GET(_garrisonArea,StrongpointArea,OuterRadius), OO_GET(_garrisonArea,StrongpointArea,OuterRadius)];

	OO_SET(_objective,HeadquartersReinforcedCategory,_Markers,[_operationMarker]);
};

OO_TRACE_DECL(SPM_HeadquartersReinforced_DeleteMarkers) =
{
	params ["_objective"];

	// Delete the markers indicating the location of the headquarters area
	private _markers = OO_GET(_objective,HeadquartersReinforcedCategory,_Markers);
	while { count _markers > 0 } do
	{
		deleteMarker (_markers deleteAt 0);
	};
};

OO_TRACE_DECL(SPM_HeadquartersReinforced_CreateTraceObject) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);
	private _garrisonArea = OO_GET(_garrison,ForceCategory,Area);

	// Put down a trace object to show mission controllers useful information
	private _traceObject = "Land_FirePlace_F" createVehicle (OO_GET(_garrisonArea,StrongpointArea,Position) vectorAdd ([1,0,0] vectorMultiply OO_GET(_garrisonArea,StrongpointArea,OuterRadius)));
	_traceObject hideObjectGlobal true;
	OO_SET(_objective,HeadquartersReinforcedCategory,_TraceObject,_traceObject);

	[_traceObject, "C0", format [" %1 reinforced", OO_GET(_garrison,ForceCategory,SideEast)]] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_HeadquartersReinforced_DeleteTraceObject) =
{
	params ["_objective"];

	private _traceObject = OO_GET(_objective,HeadquartersReinforcedCategory,_TraceObject);
	if (not isNull _traceObject) then
	{
		deleteVehicle _traceObject;
		OO_SET(_objective,HeadquartersReinforcedCategory,_TraceObject,objNull);
	};
};

OO_TRACE_DECL(SPM_HeadquartersReinforced_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,HeadquartersCategory);

	private _mission = OO_GETREF(_objective,Category,Strongpoint);

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);
	private _garrisonArea = OO_GET(_garrison,ForceCategory,Area);
	private _garrisonPosition = OO_GET(_garrisonArea,StrongpointArea,Position);
	private _garrisonRadius = OO_GET(_garrisonArea,StrongpointArea,OuterRadius);

	if (OO_GET(_objective,MissionObjective,State) == "starting") then
	{
		[_objective] call SPM_HeadquartersReinforced_CreateTraceObject;

		// Request air defense if available
		{
			[_garrisonPosition] call OO_METHOD(_x,AirDefenseCategory,RequestSupport);
		} forEach (OO_GET(_mission,Strongpoint,Categories) select { OO_INSTANCE_ISOFCLASS(_x,AirDefenseCategory) });

		private _description = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
		[_objective, _description, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);

		OO_SET(_objective,MissionObjective,State,"active");
	};

	private _flagpole = OO_GET(_objective,HeadquartersCategory,Flagpole);
	if (isNull _flagpole) then
	{
		private _communicationCenter = OO_GETREF(_objective,HeadquartersReinforcedCategory,CommunicationCenter);
		private _communicationDevice = OO_GET(_communicationCenter,CommunicationCenterCategory,CommunicationDevice);
		if (not isNull _communicationDevice) then
		{
			_flagpole = [getPos _communicationDevice, 60, OO_GET(_objective,HeadquartersCategory,FlagpoleType)] call SPM_Util_CreateFlagpole;
			OO_SET(_objective,HeadquartersCategory,Flagpole,_flagpole);
		};
	};

	if (isNull _flagpole) exitWith {};
	if (not OO_GET(_garrison,InfantryGarrisonCategory,InitialForceCreated)) exitWith {};

	private _markers = OO_GET(_objective,HeadquartersReinforcedCategory,_Markers);
	if (count _markers == 0 && { OO_GET(_mission,Mission,Announced) == "start-of-mission" }) then { [_objective] call SPM_HeadquartersReinforced_CreateMarkers };

	private _activityBorder = OO_GET(_garrison,InfantryGarrisonCategory,ActivityBorder);

	private _eastForce = [-1] call OO_METHOD(_garrison,ForceCategory,GetForceLevelsEast); // East infantry anywhere in the operation
	private _eastRating = 0;
	{ _eastRating = _eastRating + ([_x, _garrisonPosition, _garrisonRadius, _activityBorder] call SPM_Headquarters_UnitRating) } forEach _eastForce;

	switch (OO_GET(_objective,HeadquartersReinforcedCategory,_OperationPhase)) do
	{
		case "defend":
		{
			private _traceObject = OO_GET(_objective,HeadquartersReinforcedCategory,_TraceObject);
			if (not isNull _traceObject) then
			{
				[_traceObject, "C1", format ["%1 (reinforce at %2)", floor _eastRating, OO_GET(_objective,HeadquartersReinforcedCategory,ReinforceRating)]] call TRACE_SetObjectString;
				[_traceObject, "C2", format ["available: %1, mobilized: %2", floor OO_GET(_objective,HeadquartersReinforcedCategory,ReinforcementPool), floor OO_GET(_objective,HeadquartersReinforcedCategory,_MobilizedReinforcements)]] call TRACE_SetObjectString;
			};

			// When the first garrison soldier is killed, headquarters begins requesting reinforcements
			private _initialInfantryCount = OO_GET(_objective,HeadquartersReinforcedCategory,_InitialInfantryCount);
			private _garrisonCount = count OO_GET(_garrison,ForceCategory,ForceUnits);
			if (_initialInfantryCount == -1) then { OO_SET(_objective,HeadquartersReinforcedCategory,_InitialInfantryCount,_garrisonCount) };
			if (_garrisonCount < _initialInfantryCount) then { OO_SET(_objective,HeadquartersReinforcedCategory,_MobilizeReinforcements,true) };

			// If enough garrison soldiers have been killed, switch to the reinforcement phase
			if (_eastRating <= OO_GET(_objective,HeadquartersReinforcedCategory,ReinforceRating)) then
			{
				if (OO_GET(_objective,MissionObjective,State) == "starting") then { OO_SET(_objective,MissionObjective,State,"active"); };

				OO_SET(_objective,HeadquartersReinforcedCategory,_OperationPhase,"reinforce");
				private _reinforceGraceTime = diag_tickTime + OO_GET(_objective,HeadquartersReinforcedCategory,ReinforceGraceDuration);
				OO_SET(_objective,HeadquartersReinforcedCategory,_ReinforceGraceTime,_reinforceGraceTime);

				[_objective] call SPM_Headquarters_RecallPatrols;

				// Immediately provide whatever reserves that are already available, and get the garrison to act on them as soon as possible
				[_objective] call SPM_HeadquartersReinforced_UpdateReserves;
				OO_SET(_garrison,InfantryGarrisonCategory,_BalanceTime,0);
			};
		};

		case "reinforce":
		{
			[_objective] call SPM_HeadquartersReinforced_UpdateReserves;

			private _westForce = [_activityBorder] call OO_METHOD(_garrison,ForceCategory,GetForceLevelsWest); // West infantry in infantry area plus the border
			private _westRating = 0;
			{ _westRating = _westRating + ([_x, _garrisonPosition, _garrisonRadius, _activityBorder] call SPM_Headquarters_UnitRating) } forEach _westForce;

			private _reserves = OO_GET(_garrison,ForceCategory,Reserves);

			private _traceObject = OO_GET(_objective,HeadquartersReinforcedCategory,_TraceObject);
			if (not isNull _traceObject) then
			{
				[_traceObject, "C1", format ["%1 vs %2", floor _westRating, floor (_eastRating + OO_GET(_garrison,ForceCategory,Reserves) + OO_GET(_objective,HeadquartersReinforcedCategory,_MobilizedReinforcements))]] call TRACE_SetObjectString;
				[_traceObject, "C2", format ["active: %1, reserve: %2", floor _eastRating, floor _reserves]] call TRACE_SetObjectString;
			};

			private _currentHighwater = _eastRating + OO_GET(_garrison,ForceCategory,Reserves) + OO_GET(_objective,HeadquartersReinforcedCategory,_MobilizedReinforcements);
			private _garrisonHighwater = OO_GET(_objective,HeadquartersReinforcedCategory,_GarrisonHighwater);
			if (_currentHighwater > _garrisonHighwater) then { _garrisonHighwater = _currentHighwater; OO_SET(_objective,HeadquartersReinforcedCategory,_GarrisonHighwater,_garrisonHighwater) };

			private _flagpole = OO_GET(_objective,HeadquartersCategory,Flagpole);
			private _flagPosition = if (_garrisonHighwater == 0) then { 1.0 } else { _currentHighwater / _garrisonHighwater };

			if (_reserves < 1e-4 || diag_tickTime > OO_GET(_objective,HeadquartersReinforcedCategory,_ReinforceGraceTime)) then
			{
				// If the east's reserves are depleted and west force in the infantry area holds an appropriate force superiority of infantry (no matter where the east infantry is), then west wins
				if (_reserves < 1e-4 && { _westRating >= _eastRating * OO_GET(_objective,HeadquartersReinforcedCategory,WestEastVictoryRatio) || _eastRating <= OO_GET(_objective,HeadquartersReinforcedCategory,EastVictoryRating) }) then
				{
					OO_SET(_objective,Category,UpdateTime,1e30);
					OO_SET(_objective,HeadquartersReinforcedCategory,_OperationPhase,"resolve");
					OO_SET(_objective,MissionObjective,State,"succeeded");
					private _description = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
					[_objective, [format ["%1 (completed)", _description select 0]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);

					private _operationMarker = OO_GET(_objective,HeadquartersReinforcedCategory,_Markers) select 0;
					_operationMarker setMarkerColor "colorblue";

					_flagpole forceFlagTexture "\A3\Data_F\Flags\Flag_NATO_CO.paa";
					_flagPosition = 1.0;

					private _commanded = OO_NULL;
					{
						_commanded = OO_INSTANCE(_x);
						["surrender", 10] call OO_METHOD(_commanded,Category,Command);
					} forEach OO_GET(_objective,HeadquartersCategory,Commanded);
				}
				else
				{
					// If the east has boots on the ground and west doesn't have at least 1 point of presence, east wins
					if (_eastRating > 0.0 && _westRating < 1.0) then
					{
						OO_SET(_objective,Category,UpdateTime,1e30);
						OO_SET(_objective,HeadquartersReinforcedCategory,_OperationPhase,"resolve");
						OO_SET(_objective,MissionObjective,State,"failed");
						private _description = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
						[_objective, [format ["%1 (failed)", _description select 0]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);

						_flagPosition = 1.0;
					};
				};
			};

			[_flagpole, _flagPosition, 0.5] call BIS_fnc_animateFlag;
		};
	};

	// If we're mobilizing with an active communication center, then add to the mobilized reinforcements.  They will either pile up if we haven't started
	// reinforcing or they'll be immediately placed into the infantry garrison's available reserve to be thrown in as soon as it wants to use them.
	if (OO_GET(_objective,HeadquartersReinforcedCategory,_MobilizeReinforcements)) then
	{
		private _pool = OO_GET(_objective,HeadquartersReinforcedCategory,ReinforcementPool);

		private _communicationCenter = OO_GETREF(_objective,HeadquartersReinforcedCategory,CommunicationCenter);

		if (_pool > 0.0 && OO_GET(_communicationCenter,CommunicationCenterCategory,CommunicationsOnline)) then
		{
			private _reinforcementTime = OO_GET(_objective,HeadquartersReinforcedCategory,_ReinforcementTime);
			if (_reinforcementTime == 0.0) then
			{
				OO_SET(_objective,HeadquartersReinforcedCategory,_ReinforcementTime,diag_tickTime);
			}
			else
			{
				private _elapsedTime = diag_tickTime - _reinforcementTime;
				private _addition = (OO_GET(_objective,HeadquartersReinforcedCategory,MobilizationRate) * _elapsedTime) min _pool;

				private _reinforcements = OO_GET(_objective,HeadquartersReinforcedCategory,_MobilizedReinforcements);
				OO_SET(_objective,HeadquartersReinforcedCategory,_MobilizedReinforcements,_reinforcements+_addition);
				OO_SET(_objective,HeadquartersReinforcedCategory,ReinforcementPool,_pool-_addition);
				OO_SET(_objective,HeadquartersReinforcedCategory,_ReinforcementTime,diag_tickTime);
			};
		};
	};
};

OO_BEGIN_SUBCLASS(HeadquartersReinforcedCategory,HeadquartersCategory);
	OO_OVERRIDE_METHOD(HeadquartersReinforcedCategory,Root,Create,SPM_HeadquartersReinforced_Create);
	OO_OVERRIDE_METHOD(HeadquartersReinforcedCategory,Root,Delete,SPM_HeadquartersReinforced_Delete);
	OO_OVERRIDE_METHOD(HeadquartersReinforcedCategory,Category,Command,SPM_HeadquartersReinforced_Command);
	OO_OVERRIDE_METHOD(HeadquartersReinforcedCategory,Category,Update,SPM_HeadquartersReinforced_Update);
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,CommunicationCenter,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,ReinforcementPool,"SCALAR",0); // Force that can be called on to reinforce the garrison
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,MobilizationRate,"SCALAR",0); // Rate at which reinforcements are made available
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,ReinforceRating,"SCALAR",0); // The level at which reinforcements will be triggered
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,WestEastVictoryRatio,"SCALAR",2.0); // The ratio of west:east forces where the west wins
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,EastVictoryRating,"SCALAR",3.0); // The east rating where west wins regardless of ratios
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_OperationPhase,"STRING","defend"); // defend, reinforce, resolve
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_MobilizedReinforcements,"SCALAR",0); // Currently-available reinforcements
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_MobilizeReinforcements,"BOOL",false); // Whether reinforcements should be mobilized
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_ReinforcementTime,"SCALAR",0); // Time of last reinforcement addition
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_ReinforceGraceTime,"SCALAR",0); // When the reinforcement grace period ends
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,ReinforceGraceDuration,"SCALAR",60); // How long after switching to the reinforcement period that the system will wait before checking victory/loss condition (used to catch the case of players not at the operation site)
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_InitialInfantryCount,"SCALAR",-1);
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_GarrisonHighwater,"SCALAR",-1);
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_Markers,"ARRAY",[]);
	OO_DEFINE_PROPERTY(HeadquartersReinforcedCategory,_TraceObject,"OBJECT",objNull);
OO_END_SUBCLASS(HeadquartersReinforcedCategory);