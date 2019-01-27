JBRC_CALL_TIMEOUT = 2.0;

JBRC_ERROR = -1;
JBRC_PENDING = 0;
JBRC_COMPLETE = 1;
JBRC_TIMEDOUT = 2;

JBRC_CriticalSection = call JB_fnc_criticalSectionCreate;

JBRC_PendingRemoteCalls = [];

//TODO: remoteExecutedOwner says who called remotely, allowing us to get rid of (_callData select 0)
JBRC_ClientCall =
{
	params ["_callData", "_arguments"];

	private _result = _arguments call compile format ["_this call %1", _callData select 2];;
	if (isNil "_result") then { _result = 0 };

	[_callData select 1, _result] remoteExec ["JBRC_RemoteCallResponse", _callData select 0];
};

JBRC_RemoteCallResponse =
{
	params ["_callIndex", "_result"];

	JBRC_CriticalSection call JB_fnc_criticalSectionEnter;

	JBRC_PendingRemoteCalls set [_callIndex, [JBRC_COMPLETE, _result]];

	JBRC_CriticalSection call JB_fnc_criticalSectionLeave;
};