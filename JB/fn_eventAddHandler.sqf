params ["_namespace", "_eventName", "_handler", "_passthrough"];

private _handlers = _namespace getVariable ("JB_EH_" + _eventName);

if (isNil "_handlers") exitWith { diag_log format ["ERROR: JB_fnc_eventAddHandler referenced an unknown event (namespace: %1, event: '%2')", _namespace, _eventName] };

(_namespace getVariable ("JB_EH_" + _eventName)) pushBack [_handler, _passthrough]