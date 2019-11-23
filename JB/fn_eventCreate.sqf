params ["_namespace", "_eventName"];

private _handlers = _namespace getVariable ("JB_EH_" + _eventName);

if (not isNil "_handlers") exitWith { diag_log format ["ERROR: JB_fnc_eventCreate attempted to recreate an existing event (namespace: %1, event: '%2')", _namespace, _eventName] };

_namespace setVariable ["JB_EH_" + _eventName, []];