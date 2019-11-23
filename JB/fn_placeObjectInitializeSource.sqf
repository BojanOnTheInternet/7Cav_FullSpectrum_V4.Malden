params [["_source", objNull, [objNull]], ["_range", 50, [0]], ["_capacity", 0, [0]], ["_types", [], [[]]]];

if (isNull _source) exitWith {};
if (_range <= 0) exitWith {};
if (_capacity <= 0) exitWith {};
if (count _types == 0) exitWith {};

[_source, _range, _capacity, _types] call JB_PO_InitializeSource;