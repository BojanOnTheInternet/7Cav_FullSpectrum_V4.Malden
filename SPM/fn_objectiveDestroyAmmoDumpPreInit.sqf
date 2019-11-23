/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_ObjectiveObjectReady) =
{
	params ["_objective"];

	private _category = OO_GET(_objective,ObjectiveDestroyAmmoDump,_AmmoDump);
	private _ammoDump = OO_GET(_category,AmmoDumpCategory,TriggerObject);

	OO_SET(_objective,MissionObjective,ObjectiveObject,_ammoDump);

	not isNull _ammoDump
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_GetDescription) =
{
	params ["_objective"];

	["Destroy ammunition dump", "Detonate a satchel charge or large IED by the barrel in the ammunition dump to destroy the stored ammunition.  Be sure that the area is clear of friendly forces."]
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,ObjectiveDestroyObject);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyAmmoDump_Create) =
{
	params ["_objective", "_ammoDumpCategory"];

	OO_SET(_objective,ObjectiveDestroyAmmoDump,_AmmoDump,_ammoDumpCategory);
};

OO_BEGIN_SUBCLASS(ObjectiveDestroyAmmoDump,ObjectiveDestroyObject);
	OO_OVERRIDE_METHOD(ObjectiveDestroyAmmoDump,Root,Create,SPM_ObjectiveDestroyAmmoDump_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyAmmoDump,Root,Delete,SPM_ObjectiveDestroyAmmoDump_Delete);
	OO_OVERRIDE_METHOD(ObjectiveDestroyAmmoDump,MissionObjective,GetDescription,SPM_ObjectiveDestroyAmmoDump_GetDescription);
	OO_OVERRIDE_METHOD(ObjectiveDestroyAmmoDump,ObjectiveDestroyObject,ObjectiveObjectReady,SPM_ObjectiveDestroyAmmoDump_ObjectiveObjectReady);
	OO_DEFINE_PROPERTY(ObjectiveDestroyAmmoDump,_AmmoDump,"#OBJ",OO_NULL);
OO_END_SUBCLASS(ObjectiveDestroyAmmoDump);