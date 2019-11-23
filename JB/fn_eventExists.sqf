params ["_namespace", "_eventName"];

not isNil { _namespace getVariable ("JB_EH_" + _eventName) }