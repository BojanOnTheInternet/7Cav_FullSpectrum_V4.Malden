params ["_namespace", "_eventName", ["_arguments", [], [[]]]];

private _handlers = _namespace getVariable ("JB_EH_" + _eventName);

if (isNil "_handlers") exitWith { diag_log format ["ERROR: JB_fnc_eventFire referenced an unknown event (namespace: %1, event: '%2')", _namespace, _eventName] };

{
	([_namespace] + _arguments + [_x select 1]) call (_x select 0);
} forEach +_handlers;