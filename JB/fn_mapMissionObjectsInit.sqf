params [["_typeFilter", ["all", true], [[]]]];

CLIENT_MissionObjectRectangles = [];

private _texture = "#(rgb,8,8,3)color(0.5,0.5,0.5,1.0)";

_addObjectRectangle =
{
	params ["_object"];

	_boundingBox = boundingBoxReal _object;
	_corner1 = _boundingBox select 0;
	_corner2 = _boundingBox select 1;
	_width = (_corner2 select 0) - (_corner1 select 0);
	_length = (_corner2 select 1) - (_corner1 select 1);

	CLIENT_MissionObjectRectangles pushBack [getPos _object, _width / 2, _length / 2, getDir _object, [1,1,1,1], _texture];
};

{
	private _result = [typeOf _x, _typeFilter] call JB_fnc_passesTypeFilter;

	if (_result) then
	{
		[_x] call _addObjectRectangle;
	};
} forEach (allMissionObjects "");