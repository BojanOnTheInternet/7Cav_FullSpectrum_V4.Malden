/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveInteractObjectSimple_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,ObjectiveInteractObject);

	private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
	if (isNull _object) then
	{
		private _mission = OO_GETREF(_objective,Category,Strongpoint);

		private _infantryGarrison = OO_NULL;
		{
			if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory)) exitWith { _infantryGarrison = _x };
		} forEach OO_GET(_mission,Strongpoint,Categories);

		if (not OO_ISNULL(_infantryGarrison)) then
		{
			private _housedUnits = OO_GET(_infantryGarrison,InfantryGarrisonCategory,HousedUnits);
			if (count _housedUnits > 0) then
			{
				private _position = [];

				private _housedUnits = +_housedUnits;
				while { count _housedUnits > 0 } do
				{
					private _unit = _housedUnits deleteAt (floor random count _housedUnits);
					private _unitZ = getPos _unit select 2;

					private _neighbors = _unit nearEntities ["Man", 5];
					_neighbors = _neighbors select { abs (((getPos _x) select 2) - _unitZ) < 0.5 };

					if (count _neighbors > 0) exitWith
					{
						_position = (getPos _unit vectorAdd getPos (_neighbors select 0)) vectorMultiply 0.5;
					};
				};

				if (count _position > 0) then
				{
					private _objectType = OO_GET(_objective,ObjectiveInteractObjectSimple,ObjectType);
					private _object = ([_objectType, _position, random 360] call SPM_fnc_spawnVehicle);
					[_objective, _object] call OO_GET(_objective,Category,InitializeObject);

					private _onObjectCreate = OO_GET(_objective,ObjectiveInteractObjectSimple,OnObjectCreate);
					[_object] call _onObjectCreate;

					OO_SET(_objective,MissionObjective,ObjectiveObject,_object);

					[_object, format ["OIOS-%1", OO_INSTANCE_ID(_objective)], "OBJECT"] call TRACE_SetObjectString;
				};
			};
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveInteractObjectSimple_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,ObjectiveInteractObjectSimple,ObjectiveDescription);
};

OO_TRACE_DECL(SPM_ObjectiveInteractObjectSimple_Delete) =
{
	params ["_objective"];

	private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
	if (not isNull _object) then
	{
		deleteVehicle _object;
	};
};

OO_TRACE_DECL(SPM_ObjectiveInteractObjectSimple_Create) =
{
	params ["_objective", "_objectType", "_onObjectCreate", "_interactionDescription", "_objectiveDescription"];

	OO_SET(_objective,ObjectiveInteractObject,InteractionDescription,_interactionDescription);
	OO_SET(_objective,ObjectiveInteractObjectSimple,ObjectType,_objectType);
	OO_SET(_objective,ObjectiveInteractObjectSimple,OnObjectCreate,_onObjectCreate);
	OO_SET(_objective,ObjectiveInteractObjectSimple,ObjectiveDescription,_objectiveDescription);
};

private _objectiveDescription = ["",""];

OO_BEGIN_SUBCLASS(ObjectiveInteractObjectSimple,ObjectiveInteractObject);
	OO_OVERRIDE_METHOD(ObjectiveInteractObjectSimple,Root,Create,SPM_ObjectiveInteractObjectSimple_Create);
	OO_OVERRIDE_METHOD(ObjectiveInteractObjectSimple,Root,Delete,SPM_ObjectiveInteractObjectSimple_Delete);
	OO_OVERRIDE_METHOD(ObjectiveInteractObjectSimple,Category,Update,SPM_ObjectiveInteractObjectSimple_Update);
	OO_OVERRIDE_METHOD(ObjectiveInteractObjectSimple,MissionObjective,GetDescription,SPM_ObjectiveInteractObjectSimple_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveInteractObjectSimple,ObjectType,"STRING","");
	OO_DEFINE_PROPERTY(ObjectiveInteractObjectSimple,OnObjectCreate,"CODE",{});
	OO_DEFINE_PROPERTY(ObjectiveInteractObjectSimple,ObjectiveDescription,"ARRAY",_objectiveDescription);
OO_END_SUBCLASS(ObjectiveInteractObjectSimple);
