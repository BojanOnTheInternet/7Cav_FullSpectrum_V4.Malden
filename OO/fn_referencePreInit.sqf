REF_CreateTable =
{
	params ["_name", "_key"];

	private _root = [-1, _name, _key]; // Key is the position in the values (which are arrays) where the value index is stored

	[_root]
};

REF_AddValue =
{
	params ["_table", "_value"];

	private _root = _table select 0;
	private _key = _root select 2;

	if (_value select _key != -1) exitWith { diag_log format ["REF_AddValue: %1: attempt to add %1 multiple times", _root select 1, _value select _key] };

	private _index = _root select 0;
	private _entry = [0, _value];

	if (_index == -1) then
	{
		_index = count _table;
		_table pushBack _entry;
		_value set [_key, _index];
	}
	else
	{
		_root set [0, _table select _index];
		_value set [_key, _index];
		_table set [_index, _entry];
	};

	_index
};

REF_RemoveValue =
{
	params ["_table", "_value"];

	private _root = _table select 0;
	private _key = _root select 2;
	private _index = _value select _key;

	if (_index < 0 || _index >= count _table) exitWith { diag_log format ["REF_RemoveValue: %1: supplied value has invalid table index (%2).", _root select 1, _index] };

	private _entry = _table select _index;

	if (_entry select 0 != 0) then { diag_log format ["REF_RemoveValue: %1: reference value %2 when removed.", _root select 1, _entry select 1] };

	_table set [_index, _root select 0];
	_root set [0, _index];
	_value set [_key, -1];
};

REF_GetValue =
{
	params ["_table", "_index"];

	private _root = _table select 0;

	if (_index < 0 || _index >= count _table) exitWith { diag_log format ["REF_GetValue: %1: supplied index is out of range (%2).", _root select 1, _index] };

	private _entry = _table select _index;

	if (typeName _entry == "SCALAR") exitWith { diag_log format ["REF_GetValue: %1: supplied index references a deleted instance (%2).", _root select 1, _index] };

	_entry select 1;
};

REF_ForEachValue =
{
	params ["_table", "_parameters", "_code"];

	private _stopOnValue = nil;
	
	for "_i" from 1 to (count _table - 1) do
	{
		private _entry = _table select _i;
		if (typeName _entry == "ARRAY" && { ((_entry select 1) call { private _x = _this; _parameters call _code }) }) exitWith { _stopOnValue = (_entry select 1) };
	};

	if (isNil "_stopOnValue") exitWith {};

	_stopOnValue
};

REF_Reference =
{
	params ["_table", "_value"];

	private _root = _table select 0;
	private _key = _root select 2;

	private _index = _value select _key;
	private _entry = _table select _index;

	_entry set [0, (_entry select 0) + 1];

	_entry select 0
};


REF_Release =
{
	params ["_table", "_value"];

	private _root = _table select 0;
	private _key = _root select 2;

	private _index = _value select _key;
	private _entry = _table select _index;

	_entry set [0, (_entry select 0) - 1];

	_entry select 0
};