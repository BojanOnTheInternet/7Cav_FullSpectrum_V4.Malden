private _group = param [0, grpNull, [grpNull]];
private _building = param [1, objNull, [objNull]];
private _method = param [2, "simultaneous", [""]];

[_group, _building, toLower _method] call SPM_Occupy_EnterBuilding;
