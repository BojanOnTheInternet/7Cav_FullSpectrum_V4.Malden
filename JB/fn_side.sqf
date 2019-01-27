params ["_source"];

if (_source isEqualType "") exitWith
{
	private _sides =
	[
		["UNKNOWN", sideUnknown],
		["EAST", east],
		["WEST", west],
		["GUER", resistance],
		["CIV", civilian],
		["EMPTY", sideEmpty],
		["ENEMY", sideEnemy],
		["FRIENDLY", sideFriendly],
		["LOGIC", sideLogic]
	];

	_source = toUpper _source;
	{
		if (_x select 0 == _source) exitWith { _x select 1 };
	} forEach _sides;
};

if (_source isEqualType 0) exitWith
{
	private _sides =
	[
		[-1, sideUnknown],
		[0, east],
		[1, west],
		[2, resistance],
		[3, civilian],
		[4, sideEmpty],
		[5, sideEnemy],
		[6, sideFriendly],
		[7, sideLogic]
	];

	{
		if (_x select 0 == _source) exitWith { _x select 1 };
	} forEach _sides;
};