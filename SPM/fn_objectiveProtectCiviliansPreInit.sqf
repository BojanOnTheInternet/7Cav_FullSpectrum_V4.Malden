/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

SPM_ObjectiveProtectCivilians_Description =
"The civilian population must be protected.  This is true even when the civilians have armed themselves.  Do not engage a civilian unless you are engaged by them.  If too many civilians are killed, you will have failed the mission.";

OO_TRACE_DECL(SPM_ObjectiveProtectCivilians_GetDescription) =
{
	params ["_objective"];

	["Protect civilian population", SPM_ObjectiveProtectCivilians_Description]
};

OO_TRACE_DECL(SPM_ObjectiveProtectCivilians_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _garrison = OO_GET(_objective,ObjectiveProtectCivilians,_Garrison);

			if (OO_ISNULL(_garrison)) then
			{
				private _mission = OO_GETREF(_objective,Category,Strongpoint);
				{
					if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) && { OO_GET(_x,ForceCategory,SideEast) == civilian }) exitWith { _garrison = _x };
				} forEach OO_GET(_mission,Strongpoint,Categories);

				OO_SET(_objective,MissionObjective,State,"active");

				if (not OO_ISNULL(_garrison)) then
				{
					OO_SET(_objective,ObjectiveProtectCivilians,_Garrison,_garrison);

					private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
					[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
				};

				OO_SET(_objective,MissionObjective,State,"succeeded"); // Optional objective.  Default to complete, but detect failure

				if (OO_ISNULL(_garrison)) then { OO_SET(_objective,Category,UpdateTime,1e30) }; // If no civilians, then we don't ever need to do anything else.  There's no possibility of failure.
			};
		};

		case "succeeded":
		{
			private _garrison = OO_GET(_objective,ObjectiveProtectCivilians,_Garrison);
			private _numberCivilians = OO_GET(_objective,ObjectiveProtectCivilians,_NumberCivilians);
			private _deathsPermitted = OO_GET(_objective,ObjectiveProtectCivilians,DeathsPermitted);

			private _civilians = OO_GET(_garrison,ForceCategory,ForceUnits);

			_numberCivilians = _numberCivilians max (count _civilians);
			OO_SET(_objective,ObjectiveProtectCivilians,_NumberCivilians,_numberCivilians);

			if (count _civilians + _deathsPermitted < _numberCivilians) then
			{
				OO_SET(_objective,MissionObjective,State,"failed");
				[_objective, ["Too many civilians have died", ""], "event"] call OO_METHOD(_objective,Category,SendNotification);
				OO_SET(_objective,Category,UpdateTime,1e30);
			};
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveProtectCivilians_Create) =
{
	params ["_objective"];

	OO_SET(_objective,Category,GetUpdateInterval,{2});
};

OO_BEGIN_SUBCLASS(ObjectiveProtectCivilians,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveProtectCivilians,Root,Create,SPM_ObjectiveProtectCivilians_Create);
	OO_OVERRIDE_METHOD(ObjectiveProtectCivilians,Category,Update,SPM_ObjectiveProtectCivilians_Update);
	OO_OVERRIDE_METHOD(ObjectiveProtectCivilians,MissionObjective,GetDescription,SPM_ObjectiveProtectCivilians_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveProtectCivilians,DeathsPermitted,"SCALAR",5);
	OO_DEFINE_PROPERTY(ObjectiveProtectCivilians,_Garrison,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveProtectCivilians,_NumberCivilians,"SCALAR",0);
OO_END_SUBCLASS(ObjectiveProtectCivilians);
