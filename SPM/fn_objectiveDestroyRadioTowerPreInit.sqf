/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroyRadioTower_ObjectiveObjectReady) =
{
	params ["_objective"];

	private _category = OO_GET(_objective,ObjectiveDestroyRadioTower,_RadioTower);
	private _radioTower = OO_GET(_category,RadioTowerCategory,RadioTower);

	OO_SET(_objective,MissionObjective,ObjectiveObject,_radioTower);

	not isNull _radioTower
};

OO_TRACE_DECL(SPM_ObjectiveDestroyRadioTower_GetDescription) =
{
	params ["_objective"];

	["Destroy " + OO_GET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription), "Detonate explosives at the base of the radio tower"];
};

OO_TRACE_DECL(SPM_ObjectiveDestroyRadioTower_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,ObjectiveDestroyObject);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyRadioTower_Create) =
{
	params ["_objective", "_radioTowerCategory"];

	OO_SET(_objective,ObjectiveDestroyRadioTower,_RadioTower,_radioTowerCategory);
};

OO_BEGIN_SUBCLASS(ObjectiveDestroyRadioTower,ObjectiveDestroyObject);
	OO_OVERRIDE_METHOD(ObjectiveDestroyRadioTower,Root,Create,SPM_ObjectiveDestroyRadioTower_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyRadioTower,Root,Delete,SPM_ObjectiveDestroyRadioTower_Delete);
	OO_OVERRIDE_METHOD(ObjectiveDestroyRadioTower,MissionObjective,GetDescription,SPM_ObjectiveDestroyRadioTower_GetDescription);
	OO_OVERRIDE_METHOD(ObjectiveDestroyRadioTower,ObjectiveDestroyObject,ObjectiveObjectReady,SPM_ObjectiveDestroyRadioTower_ObjectiveObjectReady);
	OO_DEFINE_PROPERTY(ObjectiveDestroyRadioTower,_RadioTower,"#OBJ",OO_NULL);
OO_END_SUBCLASS(ObjectiveDestroyRadioTower);