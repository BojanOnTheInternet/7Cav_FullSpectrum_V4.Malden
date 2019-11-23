/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroyObject_ObjectiveKilled) =
{
	params ["_object", "_killer", "_instigator"];

	private _objective = (_object getVariable "SPM_ObjectiveDestroyObject_Objective") select 0;
	private _objectiveDescription = OO_GET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription);
	private _instigatorName = if (not isNull _instigator) then { name _instigator } else { "A series of unfortunate events" };

	private _message = format ["%1 has destroyed the %2", _instigatorName, _objectiveDescription];

	[_objective, [_message], "event"] call OO_METHOD(_objective,Category,SendNotification);
};

SPM_ObjectiveDestroyObject_Update =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			if ([] call OO_METHOD(_objective,ObjectiveDestroyObject,ObjectiveObjectReady)) then
			{
				private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);

				if (isNull _object) then
				{
					OO_SET(_objective,MissionObjective,State,"error");
				}
				else
				{
					private _eventHandler = _object addEventHandler ["Killed", SPM_ObjectiveDestroyObject_ObjectiveKilled];
					_object setVariable ["SPM_ObjectiveDestroyObject_Objective", [_objective, _eventHandler]];

					if (_object isKindOf "AllVehicles") then
					{
						private _captureDistance = OO_GET(_objective,ObjectiveDestroyObject,CaptureDistance);
						private _secureArea = OO_GET(_objective,ObjectiveDestroyObject,SecureArea);
						if (_captureDistance != 1e30 || count _secureArea > 0) then
						{
							private _parameters = [_object, west] call OO_CREATE(VehicleCaptureParameters); //TODO: west is hardcoded.  Because the garrison is optional, we can't use that
							OO_SET(_parameters,VehicleCaptureParameters,CaptureDistance,_captureDistance);
							OO_SET(_parameters,VehicleCaptureParameters,SecureArea,_secureArea);
							OO_SET(_objective,ObjectiveDestroyObject,_VehicleCaptureParameters,_parameters);
						};
					};

					OO_SET(_objective,MissionObjective,State,"active");
					[_object, "ODO", "DESTROY"] call TRACE_SetObjectString;

					private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
					[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
				};
			};
		};

		case "active":
		{
			private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);

			if (not alive _object) then
			{
				OO_SET(_objective,MissionObjective,State,"succeeded");
			}
			else
			{
				private _parameters = OO_GET(_objective,ObjectiveDestroyObject,_VehicleCaptureParameters);
				if ((count _parameters > 0) && { [] call OO_METHOD(_parameters,VehicleCaptureParameters,IsCaptured) }) then
				{
					private _objectData = _object getVariable "SPM_ObjectiveDestroyObject_Objective";
					if (not isNil "_objectData") then
					{
						_object removeEventHandler ["Killed", _objectData select 1];
						_object setVariable ["SPM_ObjectiveDestroyObject_Objective", nil];
					};

					[_object] call JB_fnc_respawnVehicleInitialize;
					[_object, 300, 5, 0, true] call JB_fnc_respawnVehicleWhenAbandoned;

					OO_SET(_objective,MissionObjective,State,"succeeded");
				};
			};

			if (OO_GET(_objective,MissionObjective,State) == "succeeded") then
			{
				OO_SET(_objective,Category,UpdateTime,1e30);

				private _parameters = OO_GET(_objective,ObjectiveDestroyObject,_VehicleCaptureParameters);
				if (count _parameters > 0) then
				{
					[] call OO_METHOD(_parameters,VehicleCaptureParameters,Delete);
					OO_SET(_objective,ObjectiveDestroyObject,_VehicleCaptureParameters,[]);
				};

				[_objective, [format ["%1 (%2)", ([] call OO_METHOD(_objective,MissionObjective,GetDescription)) select 0, OO_GET(_objective,MissionObjective,State)]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveDestroyObject_Create) =
{
	params ["_objective"];

	OO_SET(_objective,Category,GetUpdateInterval,{1});
};

OO_BEGIN_SUBCLASS(ObjectiveDestroyObject,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveDestroyObject,Root,Create,SPM_ObjectiveDestroyObject_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyObject,Category,Update,SPM_ObjectiveDestroyObject_Update);
	OO_DEFINE_METHOD(ObjectiveDestroyObject,ObjectiveObjectReady,{});
	OO_DEFINE_PROPERTY(ObjectiveDestroyObject,ObjectiveObjectDescription,"STRING","");
	OO_DEFINE_PROPERTY(ObjectiveDestroyObject,SecureArea,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDestroyObject,CaptureDistance,"SCALAR",1e30);
	OO_DEFINE_PROPERTY(ObjectiveDestroyObject,_VehicleCaptureParameters,"ARRAY",[]);
OO_END_SUBCLASS(ObjectiveDestroyObject);