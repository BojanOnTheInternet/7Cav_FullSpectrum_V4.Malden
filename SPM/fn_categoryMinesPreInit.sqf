/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Mines_Create) =
{
	params ["_category"];
};

OO_TRACE_DECL(SPM_Mines_Delete) =
{
	params ["_category"];

	{
		deleteVehicle _x;
	} forEach OO_GET(_category,MinesCategory,_Mines);

	OO_SET(_category,MinesCategory,_Mines,[]);

//	private _area = OO_GET(_category,MinesCategory,Area);
//	call OO_DELETE(_area);
};

OO_TRACE_DECL(SPM_Mines_GetMinePositions) =
{
	params ["_center", "_innerRadius", "_outerRadius", "_mineSpacing", "_fieldSpacing", "_fieldMinimumWidth", "_fieldMaximumWidth"];

	private _halfShift = _mineSpacing * 0.25;
	private _shift = _mineSpacing * 0.50;

	private _positions = [_center, _innerRadius, _outerRadius, _mineSpacing] call SPM_Util_SampleAreaGrid;
	_positions = _positions apply { _x vectorAdd [-_halfShift + random _shift, -_halfShift + random _shift, 0] };

	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, _mineSpacing, ["BUILDING", "HOUSE", "ROCK"]] call SPM_Util_ExcludeSamplesByProximity;

	private _fields = [];
	private _startPosition = [];
	private _fieldRadius = 0;
	private _minePositions = [];

	while { count _positions > 0 } do
	{
		_startPosition = _positions deleteAt (floor random count _positions);
		if ({ _startPosition distance _x < _fieldSpacing} count _fields == 0) then
		{
			_fieldRadius = (_fieldMinimumWidth / 2) + random (_fieldMaximumWidth / 2 - _fieldMinimumWidth / 2);
			_minePositions pushBack _startPosition;
			for "_i" from count _positions - 1 to 0 step -1 do
			{
				if (_startPosition distance (_positions select _i) < _fieldRadius) then { _minePositions pushBack (_positions deleteAt _i) };
			};
			_fields pushBack _startPosition;
		};
	};

	_minePositions
};

OO_TRACE_DECL(SPM_Mines_Update) =
{
	params ["_category"];

	OO_SET(_category,Category,UpdateTime,1e30);

	// Creating the mines can be a time-consuming process, so spawn it out and complete the task at leisure
	[_category] spawn
	{
		params ["_category"];

		scriptName "SPM_Mines_Update";

		private _area = OO_GET(_category,MinesCategory,Area);
		private _center = OO_GET(_area,StrongpointArea,Position);
		private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
		private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

		private _mineSpacing = OO_GET(_category,MinesCategory,MineSpacing);
		private _fieldSpacing = OO_GET(_category,MinesCategory,FieldSpacing);
		private _fieldMinimumWidth = OO_GET(_category,MinesCategory,FieldMinimumWidth);
		private _fieldMaximumWidth = OO_GET(_category,MinesCategory,FieldMaximumWidth);

		private _positions = [_center, _innerRadius, _outerRadius, _mineSpacing, _fieldSpacing, _fieldMinimumWidth, _fieldMaximumWidth] call SPM_Mines_GetMinePositions;

		private _mines = _positions apply { sleep 0.001; createMine ["ATMine", _x, [], 0] };

		private _side = OO_GET(_category,MinesCategory,SideEast);
		{ _side revealMine _x } forEach _mines;

		OO_GET(_category,MinesCategory,_Mines) append _mines;
	};
};

OO_BEGIN_SUBCLASS(MinesCategory,Category);
	OO_OVERRIDE_METHOD(MinesCategory,Root,Create,SPM_Mines_Create);
	OO_OVERRIDE_METHOD(MinesCategory,Root,Delete,SPM_Mines_Delete);
	OO_OVERRIDE_METHOD(MinesCategory,Category,Update,SPM_Mines_Update);
	OO_DEFINE_PROPERTY(MinesCategory,SideEast,"SIDE",east);
	OO_DEFINE_PROPERTY(MinesCategory,Area,"ARRAY",[]); // StrongpointArea structure
	OO_DEFINE_PROPERTY(MinesCategory,MineSpacing,"SCALAR",7.5);
	OO_DEFINE_PROPERTY(MinesCategory,FieldSpacing,"SCALAR",200); // No two fields will have their centers closer than this distance
	OO_DEFINE_PROPERTY(MinesCategory,FieldMinimumWidth,"SCALAR",100);
	OO_DEFINE_PROPERTY(MinesCategory,FieldMaximumWidth,"SCALAR",200);
	OO_DEFINE_PROPERTY(MinesCategory,_Mines,"ARRAY",[]);
OO_END_SUBCLASS(MinesCategory);
