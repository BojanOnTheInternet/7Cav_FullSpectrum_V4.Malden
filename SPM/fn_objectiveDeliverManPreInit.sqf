/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDeliverMan_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,ObjectiveDeliverMan,ObjectiveDescription);
};

OO_TRACE_DECL(SPM_ObjectiveDeliverMan_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveDeliverMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (not isNil "_unit") then
			{
				OO_SET(_objective,MissionObjective,ObjectiveObject,_unit);
				OO_SET(_objective,ObjectiveDeliverMan,StartPosition,getPos _unit);

				OO_SET(_objective,MissionObjective,State,"active");

				private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
				[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};

		case "active":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveDeliverMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (not alive _unit) exitWith
			{
				OO_SET(_objective,MissionObjective,State,"failed");
				[_objective, ["Delivery failed.  Target has been killed", ""], "event"] call OO_METHOD(_objective,Category,SendNotification);
			};

			if (vehicle _unit == _unit) then
			{
				private _isDelivered = false;

				private _deliverDistance = OO_GET(_objective,ObjectiveDeliverMan,DeliverDistance);
				if (_deliverDistance < 1e30) then
				{
					private _startPosition = OO_GET(_objective,ObjectiveDeliverMan,StartPosition);
					if (_startPosition distance _unit > _deliverDistance) then
					{
						_isDelivered = true;
					};
				};

				private _deliveryArea = OO_GET(_objective,ObjectiveDeliverMan,DeliveryArea);
				if (count _deliveryArea > 0 && { [getPos _vehicle, _deliveryArea] call SPM_Util_PositionInArea }) then
				{
					_isDelivered = true;
				};

				if (_isDelivered) then
				{
					private _group = createGroup [civilian, true];
					[_unit] join _group;

					doStop _unit;

					OO_SET(_objective,MissionObjective,State,"succeeded");
				};
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

OO_TRACE_DECL(SPM_ObjectiveDeliverMan_Create) =
{
	params ["_objective", "_unitProvider", "_objectiveDescription"];

	OO_SET(_objective,Category,GetUpdateInterval,{5});
	OO_SET(_objective,ObjectiveDeliverMan,UnitProvider,_unitProvider);
	OO_SET(_objective,ObjectiveDeliverMan,ObjectiveDescription,_objectiveDescription);
};

private _objectiveDescription = ["",""];

OO_BEGIN_SUBCLASS(ObjectiveDeliverMan,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveDeliverMan,Root,Create,SPM_ObjectiveDeliverMan_Create);
	OO_OVERRIDE_METHOD(ObjectiveDeliverMan,Category,Update,SPM_ObjectiveDeliverMan_Update);
	OO_OVERRIDE_METHOD(ObjectiveDeliverMan,MissionObjective,GetDescription,SPM_ObjectiveDeliverMan_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveDeliverMan,UnitProvider,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveDeliverMan,ObjectiveDescription,"ARRAY",_objectiveDescription);
	OO_DEFINE_PROPERTY(ObjectiveDeliverMan,StartPosition,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDeliverMan,DeliveryArea,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDeliverMan,DeliverDistance,"SCALAR",1e30);
OO_END_SUBCLASS(ObjectiveDeliverMan);
