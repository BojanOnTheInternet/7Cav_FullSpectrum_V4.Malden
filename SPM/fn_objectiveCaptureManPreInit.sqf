/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define INTERACTION_DISTANCE 2.0

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_C_Accept) =
{
	params ["_target"];

	_target switchMove "AmovPercMstpSsurWnonDnon_AmovPercMstpSnonWnonDnon";
};

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_AcceptCondition) =
{
	params ["_target", "_caller"];

	if (not alive _target) exitWith { false };

	if (not (lifeState _caller in ["HEALTHY", "INJURED"])) exitWith { false };

	animationState _target == "AmovPercMstpSsurWnonDnon"
};

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_Accept) =
{
	params ["_target", "_caller"];

	[_target, _caller] remoteExec ["SPM_ObjectiveCaptureMan_S_Accept", 2];
};

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_C_SetupActions) =
{
	params ["_target", "_targetDescription", "_clientActionTest"];

	if (isNull _target) exitWith {};

	if (not ([] call _clientActionTest)) exitWith {};

	_target addAction ["Accept surrender of " + _targetDescription, { [_this select 0, _this select 1] call SPM_ObjectiveCaptureMan_Accept },  [], 10, true, true, "", "[_target, _this] call SPM_ObjectiveCaptureMan_AcceptCondition", INTERACTION_DISTANCE];
};

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_C_JoinTarget) =
{
	params ["_target", "_group"];

	[_target] join _group;
	doStop _target;
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_S_Accept) =
{
	params ["_target", "_caller"];

	[_target] remoteExec ["SPM_ObjectiveCaptureMan_C_Accept", 0, true]; //JIP

	_target enableAI "path"; // In case he was captured while garrisoned

	[_target, group _caller] remoteExec ["SPM_ObjectiveCaptureMan_C_JoinTarget", groupOwner group _caller];

	private _objective = (_target getVariable "OCM_S_State") select 0;
	OO_SET(_objective,MissionObjective,State,"succeeded");

	_target 
};

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_GetDescription) =
{
	params ["_objective"];

	private _unitProvider = OO_GET(_objective,ObjectiveCaptureMan,UnitProvider);
	private _unitDescription = OO_GET(_unitProvider,UnitProvider,UnitDescription);

	["Capture " + _unitDescription, SPM_ObjectiveCaptureMan_Description];
};

SPM_ObjectiveCaptureMan_Description =
"The target will surrender to any friendly that approaches him from the front.  Accept the target's surrender using the scroll wheel option.  Once surrendered, the target will join your group.  Note that enemies will then treat the target as hostile.";

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveCaptureMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (not isNil "_unit") then
			{
				OO_SET(_objective,MissionObjective,ObjectiveObject,_unit);

				_unit setVariable ["OCM_S_State", [_objective, false]];
				removeAllWeapons _unit;

				OO_SET(_objective,MissionObjective,State,"active");

				private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
				[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};

		case "active":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveCaptureMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (not alive _unit) exitWith
			{
				OO_SET(_objective,MissionObjective,State,"failed");
				[_objective, ["Capture failed.  Target has been killed", ""], "event"] call OO_METHOD(_objective,Category,SendNotification);
			};

			private _surrendered = (_unit getVariable "OCM_S_State") select 1;
			if (not _surrendered) then
			{
				private _unitEyePosition = eyePos _unit;
				private _unitEyeDirection = eyeDirection _unit;

				private _nearestSoldiers = nearestObjects [_unit, ["B_soldier_base_F"], 10];
				{
					if (alive _x) then
					{
						private _toSoldier = (getPos _unit) vectorFromTo (getPos _x);
						private _dotProduct = _toSoldier vectorDotProduct _unitEyeDirection;

						if (_dotProduct > 0) then
						{
							if ([_unit, "GEOM", _x] checkVisibility [_unitEyePosition, eyePos _x] > 0) exitWith
							{
								_unit action ["surrender"];
								(_unit getVariable "OCM_S_State") set [1, true];
								private _unitDescription = OO_GET(_unitProvider,UnitProvider,UnitDescription);
								private _clientActionTest = OO_GET(_objective,ObjectiveCaptureMan,ClientActionTest);
								[_unit, _unitDescription, _clientActionTest] remoteExec ["SPM_ObjectiveCaptureMan_C_SetupActions", 0, true]; //JIP
							};
						};
					};
				} forEach _nearestSoldiers;
			};
		};

		case "succeeded";
		case "failed":
		{
			[_objective, [format ["%1 (%2)", ([] call OO_METHOD(_objective,MissionObjective,GetDescription)) select 0, OO_GET(_objective,MissionObjective,State)]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);
		
			OO_SET(_objective,Category,UpdateTime,1e30);
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveCaptureMan_Create) =
{
	params ["_objective", "_unitProvider"];

	OO_SET(_objective,Category,GetUpdateInterval,{1});
	OO_SET(_objective,ObjectiveCaptureMan,UnitProvider,_unitProvider);
};

OO_BEGIN_SUBCLASS(ObjectiveCaptureMan,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveCaptureMan,Root,Create,SPM_ObjectiveCaptureMan_Create);
	OO_OVERRIDE_METHOD(ObjectiveCaptureMan,Category,Update,SPM_ObjectiveCaptureMan_Update);
	OO_OVERRIDE_METHOD(ObjectiveCaptureMan,MissionObjective,GetDescription,SPM_ObjectiveCaptureMan_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveCaptureMan,UnitProvider,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveCaptureMan,ClientActionTest,"CODE",{true}); // Run on clients to determine if the local player can see the capture action
OO_END_SUBCLASS(ObjectiveCaptureMan);
