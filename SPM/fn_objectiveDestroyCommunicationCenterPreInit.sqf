/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationCenter_Create) =
{
	params ["_objective", "_center"];

	OO_SETREF(_objective,ObjectiveDestroyCommunicationCenter,CommunicationCenter,_center);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationCenter_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,Category);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _center = OO_GETREF(_objective,ObjectiveDestroyCommunicationCenter,CommunicationCenter);
			if (OO_GET(_center,CommunicationCenterCategory,CommunicationsOnline)) then
			{
				private _communicationDevice = OO_GET(_center,CommunicationCenterCategory,CommunicationDevice);
				OO_SET(_objective,MissionObjective,ObjectiveObject,_communicationDevice);
				OO_SET(_objective,MissionObjective,State,"active");

				private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
				[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};

		case "active":
		{
			private _center = OO_GETREF(_objective,ObjectiveDestroyCommunicationCenter,CommunicationCenter);
			if (not OO_GET(_center,CommunicationCenterCategory,CommunicationsOnline)) then
			{
				OO_SET(_objective,MissionObjective,State,"succeeded");
			};
		};

		case "succeeded":
		{
			[_objective, [format ["%1 (%2)", ([] call OO_METHOD(_objective,MissionObjective,GetDescription)) select 0, "succeeded"]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);
			OO_SET(_objective,Category,UpdateTime,1e30);
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationCenter_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,ObjectiveDestroyCommunicationCenter,Description)
};

private _description = ["Destroy the communications center", ""];

OO_BEGIN_SUBCLASS(ObjectiveDestroyCommunicationCenter,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveDestroyCommunicationCenter,Root,Create,SPM_ObjectiveDestroyCommunicationCenter_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyCommunicationCenter,Category,Update,SPM_ObjectiveDestroyCommunicationCenter_Update);
	OO_OVERRIDE_METHOD(ObjectiveDestroyCommunicationCenter,MissionObjective,GetDescription,SPM_ObjectiveDestroyCommunicationCenter_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationCenter,CommunicationCenter,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationCenter,Description,"ARRAY",_description);
OO_END_SUBCLASS(ObjectiveDestroyCommunicationCenter);
