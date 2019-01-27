params ["_position", "_areaPosition", "_areaWidth", "_areaHeight", "_areaAngle"];

private _distance = 0;

private _relative = _position vectorDiff _areaPosition;

private _xPosition = (_relative select 0) * cos _areaAngle - (_relative select 1) * sin _areaAngle;
private _yPosition = (_relative select 0) * sin _areaAngle + (_relative select 1) * cos _areaAngle;

_xPosition = abs _xPosition;
_yPosition = abs _yPosition;

if (_xPosition <= _areaWidth) exitWith
{
	(_yPosition - _areaHeight) max 0
};

if (_yPosition <= _areaHeight) exitWith
{
	(_xPosition - _areaWidth) max 0;
};

[_xPosition, _yPosition, 0] distance2D [_areaWidth, _areaHeight, 0]