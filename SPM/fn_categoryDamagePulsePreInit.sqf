/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_DamagePulseCategory_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	private _objective = OO_GET(_category,DamagePulseCategory,Objective);
	private _objectiveObject = OO_GET(_objective,MissionObjective,ObjectiveObject);

	if (not isNull _objectiveObject) then
	{
		[_objectiveObject, OO_GET(_category,DamagePulseCategory,DamageThreshhold), OO_GET(_category,DamagePulseCategory,DamageScale)] call JB_fnc_damagePulseInitObject;
//		[_objectiveObject, "CDP", "PULSE"] call TRACE_SetObjectString;

		OO_SET(_category,Category,UpdateTime,1e30);
	};
};

OO_TRACE_DECL(SPM_DamagePulseCategory_Create) =
{
	params ["_category", "_objective", "_damageThreshhold"];

	OO_SET(_category,DamagePulseCategory,Objective,_objective);
	OO_SET(_category,DamagePulseCategory,DamageThreshhold,_damageThreshhold);
};

OO_TRACE_DECL(SPM_DamagePulseCategory_Delete) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Root,Delete,Category);
};

OO_BEGIN_SUBCLASS(DamagePulseCategory,Category);
	OO_OVERRIDE_METHOD(DamagePulseCategory,Root,Create,SPM_DamagePulseCategory_Create);
	OO_OVERRIDE_METHOD(DamagePulseCategory,Root,Delete,SPM_DamagePulseCategory_Delete);
	OO_OVERRIDE_METHOD(DamagePulseCategory,Category,Update,SPM_DamagePulseCategory_Update);
	OO_DEFINE_PROPERTY(DamagePulseCategory,Objective,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(DamagePulseCategory,DamageThreshhold,"SCALAR",0);
	OO_DEFINE_PROPERTY(DamagePulseCategory,DamageScale,"SCALAR",1.0);
OO_END_SUBCLASS(DamagePulseCategory);
