params [["_arguments", [], [[]]], ["_function", {}, [{},""]], ["_target", 2, [0,objNull,[]]], ["_timeout", JBRC_CALL_TIMEOUT, [0]]];

if (not canSuspend) exitWith { [JBRC_ERROR, "Function was invoked in a non-scheduled environment."] };

JBRC_CriticalSection call JB_fnc_criticalSectionEnter;

private _callIndex = count JBRC_PendingRemoteCalls;
JBRC_PendingRemoteCalls pushBack [JBRC_PENDING];

JBRC_CriticalSection call JB_fnc_criticalSectionLeave;

private _callData = [clientOwner, _callIndex, _function];
([_callData] + [_arguments]) remoteExec ["JBRC_ClientCall", _target];

private _timeoutTime = diag_tickTime + _timeout;
waitUntil { diag_tickTime > _timeoutTime || ((JBRC_PendingRemoteCalls select _callIndex) select 0) == JBRC_COMPLETE };

private _callResult = JBRC_PendingRemoteCalls select _callIndex;
if (_callResult select 0 == JBRC_PENDING) then
{
	_callResult set [0, _timeout];
};

JBRC_CriticalSection call JB_fnc_criticalSectionEnter;

if (_callIndex == (count JBRC_PendingRemoteCalls) - 1) then
{
	for "_i" from (count JBRC_PendingRemoteCalls) - 1 to 0 step -1 do
	{
		if (((JBRC_PendingRemoteCalls select _i) select 0) == JBRC_PENDING) exitWith {};

		JBRC_PendingRemoteCalls deleteAt _i;
	};
};

JBRC_CriticalSection call JB_fnc_criticalSectionLeave;

_callResult;