JB_RE_C_Calls = [];

JB_RE_C_OrderedCallsArrived =
{
	params ["_groups"];

	private _arrived = true;

	private _groupID = -1;
	private _callCount = -1;
	{
		_groupID = _x select 0;
		_callCount = _x select 1;
		if ({ _x select 0 == _groupID } count JB_RE_C_Calls < _callCount) exitWith { _arrived = false };
	} forEach _groups;

	_arrived	
};

JB_RE_C_Exec =
{
	params ["_groupID", "_callID", "_code", "_parameters"];

	if (typeName _code == typeName "") then
	{
		_parameters call compile format ["_this call %1", _code]
	}
	else // code
	{
		_parameters call _code;
	};
};

JB_RE_C_CallInOrder =
{
	params ["_groups"];

	waitUntil { sleep 0.1; [_groups] call JB_RE_C_OrderedCallsArrived };

	JB_RE_C_Calls sort true;

	{
		{
			_x call JB_RE_C_Exec;
		} forEach (_x select 1);
	} forEach JB_RE_C_Calls;
};

//TODO: Order calls that are not JIP.  So if I call 1,2,3 with a normal remoteExec, they get executed 1,2,3.  So change this implementation such that it calls as soon as it has the next call in order.
JB_RE_C_RemoteExec =
{
	if (isRemoteExecutedJIP) exitWith { JB_RE_C_Calls pushBack _this };

	_this call JB_RE_C_Exec;
};

if (hasInterface && not isServer) exitWith {};

JB_RE_S_GetPlayerByUID =
{
	params ["_uid"];

	private _players = +allPlayers;
	private _index = _players findIf { getPlayerUID _x == _uid };
	if (_index == -1) then { objNull } else { _players select _index }
};

JB_RE_CS = call JB_fnc_criticalSectionCreate;
JB_RE_S_GroupID = 0;
JB_RE_S_Groups = [];

JB_RE_GROUP_ID = 0;
JB_RE_GROUP_ISJIP = 1;
JB_RE_GROUP_ISORDERED = 2;
JB_RE_GROUP_CALLS = 3;

JB_RE_S_DefaultGroup = [-1, false, false, []]; // [group-id, is-JIP, is-ordered, [JIP-id,...]]

JB_RE_S_PlayerConnected =
{
	params ["_id", "_uid", "_name", "_isJIP", "_owner"];

	private _player = objNull;
	[{ _player = [_uid] call JB_RE_S_GetPlayerByUID; not isNull _player }, 30, 1] call JB_fnc_timeoutWaitUntil;

	if (isNull _player) exitWith {};

	private _ordering = JB_RE_S_Groups select { (_x select JB_RE_GROUP_ISORDERED) && (_x select JB_RE_GROUP_ISJIP) } apply { [_x select JB_RE_GROUP_ID, count (_x select JB_RE_GROUP_CALLS)] };
	if (count _ordering > 0) then { [_ordering] remoteExec ["JB_RE_C_CallInOrder", _player] };
};

JB_RE_GroupCreate =
{
	params ["_isJIP", "_isOrdered"];

	JB_RE_CS call JB_fnc_criticalSectionEnter;
	JB_RE_S_GroupID = JB_RE_S_GroupID + 1;
	private _groupID = JB_RE_S_GroupID;
	JB_RE_CS call JB_fnc_criticalSectionLeave;
	
	private _group = [];
	_group set [JB_RE_GROUP_ID, _groupID];
	_group set [JB_RE_GROUP_ISJIP, _isJIP];
	_group set [JB_RE_GROUP_ISORDERED, _isOrdered];
	_group set [JB_RE_GROUP_CALLS, []];

	JB_RE_S_Groups pushBack _group;

	_group
};

JB_RE_Execute =
{
	params ["_code", "_parameters", "_recipients", ["_group", JB_RE_S_DefaultGroup, [[]]]];

	if (not (_group select JB_RE_GROUP_ISJIP)) exitWith
	{
		if (_code isEqualType "") then
		{
			_parameters remoteExec [_code, _recipients]
		}
		else
		{
			[_parameters, _code] remoteExec ["call", _recipients]
		};
	};

	private _callID = (_group select JB_RE_GROUP_CALLS) pushBack "";

	private _jip = [_group select JB_RE_GROUP_ID, _callID, _code, _parameters] remoteExec ["JB_RE_C_RemoteExec", _recipients, true];

	(_group select JB_RE_GROUP_CALLS) set [_callID, _jip];

	_callID
};

JB_RE_GroupDelete =
{
	params ["_group"];

	{
		remoteExec ["", _x];
	} forEach (_group select JB_RE_GROUP_CALLS);

	private _groupID = _group select JB_RE_GROUP_ID;

	JB_RE_CS call JB_fnc_criticalSectionEnter;
	private _index = JB_RE_S_Groups findIf { _x select JB_RE_GROUP_ID == _groupID };
	if (_index >= 0) then { JB_RE_S_Groups deleteAt _index };
	JB_RE_CS call JB_fnc_criticalSectionLeave;

	while { count _group > 0 } do { _group deleteAt 0 };
};

addMissionEventHandler ["PlayerConnected", { _this spawn JB_RE_S_PlayerConnected }];