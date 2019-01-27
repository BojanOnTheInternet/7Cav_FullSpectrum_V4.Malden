params ["_object", "_damageThreshhold", "_damageScale", ["_damageFilter", {true}, [{}]]];

_object setVariable ["JB_DP_Data", [_damageThreshhold, _damageScale, _damageFilter], true];

private _code =
{
	(_this select 0) addEventHandler ["HandleDamage", JB_DP_HandleDamage]
};

[[_object], _code] remoteExec ["call", 0, true]; // JIP