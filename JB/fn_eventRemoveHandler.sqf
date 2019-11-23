params ["_namespace", "_eventName", "_index"];

private _handlers = _namespace getVariable ("JB_EH_" + _eventName);

if (isNil "_handlers") exitWith { diag_log format ["ERROR: JB_fnc_eventRemoveHandler referenced an unknown event (namespace: %1, event: '%2')", _namespace, _eventName] };

if (_index < 0 || _index >= count _handlers || { isNil { _handlers select _index } }) exitWith { diag_log format ["ERROR: JB_fnc_eventRemoveHandler referenced an invalid handler index (namespace: %1, event: '%2', index: %3)", _namespace, _eventName, _index] };

_handlers set [_index, nil];

while { count _handlers > 0 && { isNil { _handlers select (count _handlers - 1) } } } do
{
	_handlers deleteAt (count _handlers - 1);
};