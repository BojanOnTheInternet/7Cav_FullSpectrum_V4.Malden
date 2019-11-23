/*
Copyright (c) 2019, John Buehler & Bojan
Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroySAM_GetDescription) =
{
	params ["_objective"];

	["Destroy SAM site", "The enemy has deployed a long range surface-to-air missile site in the vicinity of the AO. Destroy all associated SAM equipment."];
};

OO_TRACE_DECL(SPM_ObjectiveDestroySAM_Create) =
{
	params ["_objective", "_samSite"];
	OO_SETREF(_objective,ObjectiveDestroySAM,SAMSite,_samSite);
};

OO_TRACE_DECL(SPM_ObjectiveDestroySAM_Delete) =
{
	params ["_objective"];

};

OO_TRACE_DECL(SPM_ObjectiveDestroySAM_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,Category);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			OO_SET(_objective,MissionObjective,State,"active");

			private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
			[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
		};

		case "active": {
			private _samSite = OO_GETREF(_objective,ObjectiveDestroySAM,SAMSite);
			private _samObjects =  OO_GET(_samSite,SAMCategory,SAMObjects);
			private _aliveObjects = [];
			{
				if (alive _x) then {
					_aliveObjects pushBack _x;
				};
			} forEach _samObjects;
			if (count _aliveObjects == 0) then {
				OO_SET(_objective,MissionObjective,State,"succeeded");
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

OO_BEGIN_SUBCLASS(ObjectiveDestroySAM,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveDestroySAM,Root,Create,SPM_ObjectiveDestroySAM_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroySAM,Root,Delete,SPM_ObjectiveDestroySAM_Delete);
	OO_OVERRIDE_METHOD(ObjectiveDestroySAM,Category,Update,SPM_ObjectiveDestroySAM_Update);
	OO_OVERRIDE_METHOD(ObjectiveDestroySAM,MissionObjective,GetDescription,SPM_ObjectiveDestroySAM_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveDestroySAM,SAMSite,"#REF",OO_NULL);
OO_END_SUBCLASS(ObjectiveDestroySAM);