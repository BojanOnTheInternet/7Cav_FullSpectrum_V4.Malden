private _match =
{
	params ["_criteria", "_value"];

	if (_criteria isEqualType "") exitWith { _criteria == "*" || { _value == _criteria } };

	_value in _criteria
};

private _animationState = param [0, "", [""]];
private _A = param [1, "*", ["", []]];
private _P = param [2, "*", ["", []]];
private _M = param [3, "*", ["", []]];
private _S = param [4, "*", ["", []]];
private _W = param [5, "*", ["", []]];
private _D = param [6, "*", ["", []]];

if (not ([_A, _animationState select [ 1, 3]] call _match)) exitWith { false };
if (not ([_P, _animationState select [ 5, 3]] call _match)) exitWith { false };
if (not ([_M, _animationState select [ 9, 3]] call _match)) exitWith { false };
if (not ([_S, _animationState select [13, 3]] call _match)) exitWith { false };
if (not ([_W, _animationState select [17, 3]] call _match)) exitWith { false };
if (not ([_D, _animationState select [21, 3]] call _match)) exitWith { false };

true;