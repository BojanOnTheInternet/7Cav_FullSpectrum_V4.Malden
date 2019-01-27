private _classes = param [0, [], [[]]];

if (count _classes == 0) exitWith { [] };

private _firstUnitClass = _classes select 0;

private _side = sideUnknown;
if (_firstUnitClass find "LOP_US_" == 0) then { _side = east };
if (_firstUnitClass find "LOP_PMC_" == 0) then { _side = independent };
if (_firstUnitClass find "rhsusf_" == 0) then { _side = west };
if (_firstUnitClass find "C_" == 0) then { _side = civilian };

private _descriptor = [];
{
	_descriptor pushBack [_x, "PRIVATE", [0, 0, 0], 0, nil];
} forEach _classes;

[_side, _descriptor]