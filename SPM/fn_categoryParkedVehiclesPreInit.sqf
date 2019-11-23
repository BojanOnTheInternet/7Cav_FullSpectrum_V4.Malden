/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ParkedVehicles_CaptureVehicle) =
{
	params ["_category", "_vehicle"];

	private _vehicles = OO_GET(_category,ParkedVehiclesCategory,Vehicles);

	private _index = _vehicles find _vehicle;
	if (_index == -1) exitWith {};

	_vehicles deleteAt _index;
};

OO_TRACE_DECL(SPM_ParkedVehicles_Update) =
{
	params ["_category"];

	private _position = OO_GET(_category,ParkedVehiclesCategory,Position);
	private _types = OO_GET(_category,ParkedVehiclesCategory,Types);
	private _spacing = OO_GET(_category,ParkedVehiclesCategory,Spacing);
	private _vehicles = OO_GET(_category,ParkedVehiclesCategory,Vehicles);

	private _fieldPosition = [];
	private _fieldDirection = 0;
	private _fieldAdjust = [];

	for "_i" from 1 to count _types do
	{
		private _parking = [_position, 100, "closest", 10] call SPM_CivilianVehiclesCategory_ParkingPosition;

		if (count _parking == 0) then
		{
			if (count _fieldPosition == 0) then
			{
				private _positions = [_position, 0, 100, 10.0] call SPM_Util_SampleAreaGrid;
				[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
				[_positions, 15, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
				[_positions, (count _types - _i + 1) * _spacing, ["WALL", "BUILDING", "HOUSE", "ROCK", "TREE", "ROAD", "ENTITY"]] call SPM_Util_ExcludeSamplesByProximity;

				if (count _positions > 0) then
				{
					_fieldPosition = _positions deleteAt (floor random count _positions);
					_fieldDirection = [_fieldPosition, _fieldPosition getDir _position] call SPM_Util_EnvironmentAlignedDirection;

					_fieldAdjust = _fieldPosition vectorFromTo _position;
					_fieldAdjust = [(_fieldAdjust select 1) * _spacing, -(_fieldAdjust select 0) * _spacing, 0];

					_fieldPosition = _fieldPosition vectorAdd (_fieldAdjust vectorMultiply -((count _types - _i) / 2));
				};
			};

			if (count _fieldPosition > 0) then
			{
				_parking = [_fieldPosition vectorAdd [-0.5 + random 1.0, -0.5 + random 1.0, 0], _fieldDirection];
				_fieldPosition = _fieldPosition vectorAdd _fieldAdjust;
			};
		};

		if (count _parking > 0) then
		{
			private _vehicle = [_types select (_i - 1), _parking select 0, _parking select 1] call SPM_fnc_spawnVehicle;
			[_category, _vehicle] call OO_GET(_category,Category,InitializeObject);
			_vehicles pushBack _vehicle;
		};
	};

	OO_SET(_category,Category,UpdateTime,1e30);
};

OO_TRACE_DECL(SPM_ParkedVehicles_Delete) =
{
	params ["_category"];

	private _vehicles = OO_GET(_category,ParkedVehiclesCategory,Vehicles);

	while { count _vehicles > 0 } do
	{
		deleteVehicle (_vehicles deleteAt 0);
	};
};

OO_TRACE_DECL(SPM_ParkedVehicles_Create) =
{
	params ["_category", "_position", "_types", "_spacing"];

	OO_SET(_category,ParkedVehiclesCategory,Position,_position);
	OO_SET(_category,ParkedVehiclesCategory,Types,_types);
	OO_SET(_category,ParkedVehiclesCategory,Spacing,_spacing);
};

OO_BEGIN_SUBCLASS(ParkedVehiclesCategory,Category);
	OO_OVERRIDE_METHOD(ParkedVehiclesCategory,Root,Create,SPM_ParkedVehicles_Create);
	OO_OVERRIDE_METHOD(ParkedVehiclesCategory,Root,Delete,SPM_ParkedVehicles_Delete);
	OO_OVERRIDE_METHOD(ParkedVehiclesCategory,Category,Update,SPM_ParkedVehicles_Update);
	OO_DEFINE_METHOD(ParkedVehiclesCategory,CaptureVehicle,SPM_ParkedVehicles_CaptureVehicle);
	OO_DEFINE_PROPERTY(ParkedVehiclesCategory,Position,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ParkedVehiclesCategory,Types,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ParkedVehiclesCategory,Spacing,"SCALAR",0.0);
	OO_DEFINE_PROPERTY(ParkedVehiclesCategory,Vehicles,"ARRAY",[]);
OO_END_SUBCLASS(ParkedVehiclesCategory);
