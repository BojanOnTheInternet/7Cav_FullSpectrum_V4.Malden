#include "..\OO\oo.h"

JB_SL_SUCCESS = 0;
JB_SL_ERROR_NOLIST = 1;
JB_SL_ERROR_NOTYPE = 2;
JB_SL_ERROR_NOOPERATOR = 3;
JB_SL_ERROR_NOITEM = 4;
JB_SL_ERROR_LISTEXISTS = 5;
JB_SL_ERROR_TYPEEXISTS = 6;
JB_SL_ERROR_REPLACEMISMATCH = 7;

JB_SL_LIST_OBJECT = 0;
JB_SL_LIST_NAME = 1;
JB_SL_LIST_CONNECTIONS = 2;
JB_SL_LIST_TYPE = 3;
JB_SL_LIST_ITEMNAMES = 4;
JB_SL_LIST_ITEMVALUES = 5;

// CLIENT

// Create a list of a given type on an object with a specified list of item values.
OO_TRACE_DECL(JB_SL_ListCreate) =
{
	params ["_object", "_listName", "_typeName", "_items"];

	[_object, _listName, if (isNil "_typeName") then { nil } else { _typeName }, _items] remoteExec ["JB_SL_S_ListCreate", 2];
};

// Synchronous request of server to determine if a named list exists on an object
OO_TRACE_DECL(JB_SL_ListExists) =
{
	params ["_object", "_listName"];

	if ([_object, _listName] call JB_SL_ListIsOpen) exitWith { true };

	private _result = [[_object, _listName], "JB_SL_S_ListExists", 2] call JB_fnc_remoteCall;
	if (_result select 0 == JBRC_TIMEDOUT) exitWith {};
	
	_result select 1
};

// Open a list for use
OO_TRACE_DECL(JB_SL_ListOpen) =
{
	params ["_object", "_listName", "_callback"];

	private _variableName = "JB_SL_C_" + _listName;
	if (isNil { _object getVariable _variableName }) then { _object setVariable [_variableName, [_object, [], [], [], false]] }; // false indicates that the list doesn't have its initial values
	private _list = _object getVariable _variableName;

	_list select 1 pushBack (if (isNil "_callback") then { nil } else { _callback });

	[_object, _listName] remoteExec ["JB_SL_S_ListOpen", 2];

	count (_list select 1) // _connectionIndex
};

// Close a list when no longer in use
OO_TRACE_DECL(JB_SL_ListClose) =
{
	params ["_object", "_listName", "_connectionIndex"];

	private _variableName = "JB_SL_C_" + _listName;
	private _list = _object getVariable _variableName;

	if (isNil "_list") exitWith {};

	_list select 1 set [_connectionIndex, nil];

	[_object, _listName] remoteExec ["JB_SL_S_ListClose", 2];
};

// Determine if a list is open and ready for use (has initial values)
OO_TRACE_DECL(JB_SL_ListIsOpen) =
{
	params ["_object", "_listName"];

	private _variableName = "JB_SL_C_" + _listName;
	private _list = _object getVariable _variableName;
	if (isNil "_list") exitWith { false };

	_list select 4
};

OO_TRACE_DECL(JB_SL_ListGetItem) =
{
	params ["_object", "_listName", "_itemName"];

	private _variableName = "JB_SL_C_" + _listName;
	private _list = _object getVariable _variableName;

	private _itemIndex = [_list select 2, _itemName] call JB_SL_ItemIndex;
	if (_itemIndex == -1) exitWith { nil };

	private _itemValue = _list select 3 select _itemIndex;

	if (_itemValue isEqualType []) exitWith { +_itemValue };

	_itemValue
};

// _itemName of -1 will append
OO_TRACE_DECL(JB_SL_ListSetItem) =
{
	params ["_object", "_listName", "_itemName", "_itemValue"];

	[_object, _listName, _itemName, _itemValue] remoteExec ["JB_SL_S_ListSetItem", 2];
};

OO_TRACE_DECL(JB_SL_ListSetItemMember) =
{
	params ["_object", "_listName", "_itemName", "_memberIndex", "_memberValue"];

	[_object, _listName, _itemName, _memberIndex, _memberValue] remoteExec ["JB_SL_S_ListSetItemMember", 2];
};

OO_TRACE_DECL(JB_SL_ListReplaceItemMember) =
{
	params ["_object", "_listName", "_itemName", "_memberIndex", "_oldValue", "_newValue"];

	[_object, _listName, _itemName, _memberIndex, _oldValue, _newValue] remoteExec ["JB_SL_S_ListReplaceItemMember", 2];
};

OO_TRACE_DECL(JB_SL_ListOpItem) =
{
	params ["_object", "_listName", "_operatorName", "_parameters"];

	[_object, _listName, _operatorName, _parameters] remoteExec ["JB_SL_S_ListOpItem", 2];
};

OO_TRACE_DECL(JB_SL_CallbackNotifyInitialItems) =
{
	params ["_object", "_listName", "_itemNames", "_itemValues"];

	private _variableName = "JB_SL_C_" + _listName;
	private _list = _object getVariable _variableName;
	_list set [2, _itemNames];
	_list set [3, _itemValues];

	{
		if (not isNil "_x") then { [_object, _listName, "InitialItems"] call _x };
	} forEach (_list select 1);

	_list set [4, true]; // Populated and can be used
};

OO_TRACE_DECL(JB_SL_CallbackNotifyItemChanged) =
{
	params ["_object", "_listName", "_itemIndex", "_itemName", "_itemValue"];

	private _variableName = "JB_SL_C_" + _listName;
	private _list = _object getVariable _variableName;

	_list select 2 set [_itemIndex, _itemName];
	_list select 3 set [_itemIndex, _itemValue];

	{
		if (not isNil "_x") then { [_object, _listName, "ItemChanged"] call _x };
	} forEach (_list select 1);
};

OO_TRACE_DECL(JB_SL_CallbackNotifyItemMemberChanged) =
{
	params ["_object", "_listName", "_itemIndex", "_itemName", "_memberIndex", "_memberValue"];

	private _variableName = "JB_SL_C_" + _listName;
	private _list = _object getVariable _variableName;

	_list select 3 select _itemIndex set [_memberIndex, _memberValue];

	{
		if (not isNil "_x") then { [_object, _listName, "ItemMemberChanged"] call _x };
	} forEach (_list select 1);
};

OO_TRACE_DECL(JB_SL_CallbackNotifyListClosed) =
{
	params ["_object", "_listName"];

	private _variableName = "JB_SL_C_" + _listName;
	_object setVariable [_variableName, nil];
};

// CLIENT&SERVER

OO_TRACE_DECL(JB_SL_ItemIndex) =
{
	params ["_itemNames", "_itemName"];

	private _itemIndex = -1;

	switch (typeName _itemName) do
	{
		case typeName "":
		{
			_itemIndex = _list select JB_SL_LIST_ITEMNAMES findIf { _x == _itemName };
		};

		case typeName 0:
		{
			_itemIndex = _itemName;
		};
	};

	_itemIndex
};

// SERVER

JB_SL_S_CS_Global = call JB_fnc_criticalSectionCreate; // CS to ensure that only one thread creates a variable on an object
JB_SL_S_Types = []; // [["type", [operators]], ["type", [operators]], ...]

OO_TRACE_DECL(JB_SL_S_NotifyInitialItems) =
{
	params ["_connection", "_list"];

	[_list select JB_SL_LIST_OBJECT, _list select JB_SL_LIST_NAME, _list select JB_SL_LIST_ITEMNAMES, _list select JB_SL_LIST_ITEMVALUES] remoteExec ["JB_SL_CallbackNotifyInitialItems", _connection select 0];
};

OO_TRACE_DECL(JB_SL_S_NotifyListClosed) =
{
	params ["_connection", "_list"];

	[_list select JB_SL_LIST_OBJECT, _list select JB_SL_LIST_NAME] remoteExec ["JB_SL_CallbackNotifyListClosed", _connection select 0];
};

OO_TRACE_DECL(JB_SL_S_NotifyItemChanged) =
{
	params ["_list", "_itemIndex", "_itemName", "_itemValue"];

	private _contactedConnections = [];
	{
		if (not ((_x select 0) in _contactedConnections)) then // Contact each client only once, despite possibility of multiple connections from each
		{
			_contactedConnections pushBack (_x select 0);
			[_list select JB_SL_LIST_OBJECT, _list select JB_SL_LIST_NAME, _itemIndex, _itemName, _itemValue] remoteExec ["JB_SL_CallbackNotifyItemChanged", _x select 0];
		};
	} forEach (_list select JB_SL_LIST_CONNECTIONS);
};

OO_TRACE_DECL(JB_SL_S_NotifyItemMemberChanged) =
{
	params ["_list", "_itemIndex", "_itemName", "_memberIndex", "_memberValue"];

	private _contactedConnections = [];
	{
		if (not ((_x select 0) in _contactedConnections)) then // Contact each client only once, despite possibility of multiple connections from each
		{
			_contactedConnections pushBack (_x select 0);
			[_list select JB_SL_LIST_OBJECT, _list select JB_SL_LIST_NAME, _itemIndex, _itemName, _memberIndex, _memberValue] remoteExec ["JB_SL_CallbackNotifyItemMemberChanged", _x select 0];
		};
	} forEach (_list select JB_SL_LIST_CONNECTIONS);
};

OO_TRACE_DECL(JB_SL_S_NotifyMessage) =
{
	params ["_list", "_message"];

	private _contactedConnections = [];
	{
		if (not ((_x select 0) in _contactedConnections)) then // Contact each client only once, despite possibility of multiple connections from each
		{
			_contactedConnections pushBack (_x select 0);
			[_list select JB_SL_LIST_OBJECT, _list select JB_SL_LIST_NAME, _itemIndex, _itemName, _itemValue] remoteExec ["JB_SL_CallbackNotifyMessage", _x select 0];
		};
	} forEach (_list select JB_SL_LIST_CONNECTIONS);
};

OO_TRACE_DECL(JB_SL_S_FindConnections) =
{
	params ["_list", "_client"];

	(_list select JB_SL_LIST_CONNECTIONS) select { _x select 0 == _client }
};

OO_TRACE_DECL(JB_SL_S_GetCS) =
{
	// Avoid single-threading all list create/open operations
	private _cs = _object getVariable "JB_SL_CS";
	if (isNil "_cs") then
	{
		JB_SL_S_CS_Global call JB_fnc_criticalSectionEnter;
		_cs = _object getVariable "JB_SL_CS";
		if (isNil "_cs") then
		{
			_cs = call JB_fnc_criticalSectionCreate;
			_object setVariable ["JB_SL_CS", _cs];
		};
		JB_SL_S_CS_Global call JB_fnc_criticalSectionLeave;
	};

	_cs
};

OO_TRACE_DECL(JB_SL_S_TypeNotifyItemChanged) =
{
	params ["_object", "_listName", "_itemIndex", "_itemName", "_itemValue"];

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;

	[_list, _itemIndex, _itemName, _itemValue] call JB_SL_S_NotifyItemChanged;
};

OO_TRACE_DECL(JB_SL_S_TypeNotifyMessage) =
{
	params ["_object", "_listName", "_message"];

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;

	[_list, _message] call JB_SL_S_NotifyMessage;
};

OO_TRACE_DECL(JB_SL_S_TypeFind) =
{
	params ["_typeName"];

	private _typeIndex = JB_SL_S_Types findIf { _x select 0 == _typeName };
	if (_typeIndex == -1) exitWith { nil };

	JB_SL_S_Types select _typeIndex
};

OO_TRACE_DECL(JB_SL_S_TypeCreate) =
{
	params ["_typeName"];

	if (not isNil { [_typeName] call JB_SL_S_TypeFind }) exitWith { nil };

	private _type = [_typeName, []];
	JB_SL_S_Types pushBack _type;

	_type
};

OO_TRACE_DECL(JB_SL_S_TypeAddOperator) =
{
	params ["_type", "_operatorName", "_operator"];

	(_type select 1) pushBack [_operatorName, _operator];
};

OO_TRACE_DECL(JB_SL_S_TypeFindOperator) =
{
	params ["_type", "_operatorName"];

	private _operatorIndex = (_type select 1) findIf { _x select 0 == _operatorName };
	if (_operatorIndex == -1) exitWith { nil };

	_type select 1 select _operatorIndex select 1
};

OO_TRACE_DECL(JB_SL_S_Connect) =
{
	params ["_list", "_client"];

	private _alreadyConnected = (_list select JB_SL_LIST_CONNECTIONS) findIf { _x select 0 == _client } >= 0;

	private _connection = [_client];
	(_list select JB_SL_LIST_CONNECTIONS) pushBack _connection;

	if (not _alreadyConnected) then { [_connection, _list] call JB_SL_S_NotifyInitialItems };
};

OO_TRACE_DECL(JB_SL_S_ListExists) =
{
	params ["_object", "_listName"];
	
	private _variableName = "JB_SL_S_" + _listName;
	not isNil { _object getVariable _variableName };
};

// _items is an array of name/value pairs.  Name can be numeric or string.
OO_TRACE_DECL(JB_SL_S_ListCreate) =
{
	params ["_object", "_listName", "_typeName", "_items"];

	private _type = nil;
	if (not isNil "_typeName" && { _type = [_typeName] call JB_SL_S_TypeFind; isNil "_type" }) exitWith {};

	private _cs = [_object] call JB_SL_S_GetCS;

	private _result = JB_SL_ERROR_LISTEXISTS;

	_cs call JB_fnc_criticalSectionEnter;

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;
	if (isNil "_list") then
	{
		_list = [];
		_list set [JB_SL_LIST_OBJECT, _object];
		_list set [JB_SL_LIST_NAME, _listName];
		_list set [JB_SL_LIST_CONNECTIONS, []];
		_list set [JB_SL_LIST_TYPE, if (isNil "_type") then { nil } else { _type }];
		_list set [JB_SL_LIST_ITEMNAMES, []];
		_list set [JB_SL_LIST_ITEMVALUES, []];

		{
			[_list, _x select 0, _x select 1] call JB_SL_SetItemValue;
		} forEach _items;

		_object setVariable [_variableName, _list];

		_result = JB_SL_SUCCESS;
	};

	_cs call JB_fnc_criticalSectionLeave;

//	if (_result != JB_SL_SUCCESS) then { [remoteExecutedOwner, _object, _listName, _result] call JB_SL_S_NotifyError };
};

OO_TRACE_DECL(JB_SL_S_ListOpen) =
{
	params ["_object", "_listName", "_typeName"]; //TODO: Check _typeName

	JB_SL_S_CS_Global call JB_fnc_criticalSectionEnter;

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;
	if (isNil "_list" || { _list select JB_SL_LIST_OBJECT != _object }) then
	{
//		[remoteExecutedOwner, _object, _listName, JB_SL_ERROR_NOLIST] call JB_SL_S_NotifyError;
	}
	else
	{
		[_list, remoteExecutedOwner] call JB_SL_S_Connect;
	};

	JB_SL_S_CS_Global call JB_fnc_criticalSectionLeave;
};

OO_TRACE_DECL(JB_SL_S_ListClose) =
{
	params ["_object", "_listName"];

	private _cs = _object getVariable "JB_SL_CS";
	_cs call JB_fnc_criticalSectionEnter;

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;
	private _connections = _list select JB_SL_LIST_CONNECTIONS;

	private _connectionIndex = _connections findIf { _x == remoteExecutedOwner };
	_connections deleteAt _connectionIndex;

	if ({ _x == remoteExecutedOwner } count _connections == 0) then
	{
		[remoteExecutedOwner, _object, _list] call JB_SL_S_NotifyListClosed;
	};

	if (count _connections == 0) then { _object setVariable [_variableName, nil] };

	_cs call JB_fnc_criticalSectionLeave;
};

// Two arrays, names and values, are kept separate.  The names array is kept as long as the named item with the largest index, but no longer. For example,
// NAMES  [nil, nil, nil, nil, "bob"]
// VALUES [14,   27,  63,  18,   111, 2, 88, 6]
// List items 0, 1, 2, 3, 5, 6, 7 can be accessed only by index
// List item 4 can be accessed by index 4 or name "bob"
// Note that if items are always accessed by number, only the VALUES array is maintained
// Note that a list begins as an infinite array of nils

OO_TRACE_DECL(JB_SL_GetItemValue) =
{
	params ["_list", "_itemName"];

	private _itemIndex = [_list select JB_SL_LIST_ITEMNAMES, _itemName] call JB_SL_ItemIndex;
	if (_itemIndex == -1) exitWith { [nil, -1] };

	[_list select JB_SL_LIST_ITEMVALUES select _itemIndex, _itemIndex];
};

OO_TRACE_DECL(JB_SL_SetItemValue) =
{
	params ["_list", "_itemName", "_itemValue"];

	private _itemIndex = [_list select JB_SL_LIST_ITEMNAMES, _itemName] call JB_SL_ItemIndex;
	if (_itemIndex == -1) then
	{
		_itemIndex = count (_list select JB_SL_LIST_ITEMVALUES);
		_list select JB_SL_LIST_ITEMNAMES set [_itemIndex, _itemName];
	};

	_list select JB_SL_LIST_ITEMVALUES set [_itemIndex, _itemValue];

	[_itemValue, _itemIndex]
};

OO_TRACE_DECL(JB_SL_S_ListSetItem) =
{
	params ["_object", "_listName", "_itemName", "_itemValue"];

	private _result = JB_SL_SUCCESS;

	private _cs = _object getVariable "JB_SL_CS";
	_cs call JB_fnc_criticalSectionEnter;

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;

	private _item = [_list, _itemName, _itemValue] call JB_SL_SetItemValue;

	_cs call JB_fnc_criticalSectionLeave;

	if (_result != JB_SL_SUCCESS) then
	{
//		[remoteExecutedOwner, _object, _listName, _result] call JB_SL_S_NotifyError;
	}
	else
	{
		[_list, _item select 1, _itemName, _itemValue] call JB_SL_S_NotifyItemChanged;
	};
};

OO_TRACE_DECL(JB_SL_S_ListSetItemMember) =
{
	params ["_object", "_listName", "_itemName", "_memberIndex", "_memberValue"];

	private _result = JB_SL_SUCCESS;

	private _cs = _object getVariable "JB_SL_CS";
	_cs call JB_fnc_criticalSectionEnter;

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;

	private _result = JB_SL_ERROR_NOITEM;

	private _item = [_list, _itemName] call JB_SL_GetItemValue;

	if (_item select 1 >= 0) then
	{
		_result = JB_SL_SUCCESS;
		(_item select 0) set [_memberIndex, _memberValue];
	};

	_cs call JB_fnc_criticalSectionLeave;

	if (_result != JB_SL_SUCCESS) then
	{
//		[remoteExecutedOwner, _object, _listName, _result] call JB_SL_S_NotifyError;
	}
	else
	{
		[_list, _item select 1, _itemName, _memberIndex, _memberValue] call JB_SL_S_NotifyItemMemberChanged;
	};
};

OO_TRACE_DECL(JB_SL_S_ListReplaceItemMember) =
{
	params ["_object", "_listName", "_itemName", "_memberIndex", "_oldValue", "_newValue"];

	private _result = JB_SL_SUCCESS;

	private _cs = _object getVariable "JB_SL_CS";
	_cs call JB_fnc_criticalSectionEnter;

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;

	private _item = [_list, _itemName] call JB_SL_GetItemValue;

	private _result = JB_SL_SUCCESS;
	switch (true) do
	{
		case (_item select 1 == -1): { _result = JB_SL_ERROR_NOITEM };
		case (not ((_item select 0 select _memberIndex) isEqualTo _oldValue)): { _result = JB_SL_ERROR_REPLACEMISMATCH };
		default { (_item select 0) set [_memberIndex, _newValue] };
	};

	_cs call JB_fnc_criticalSectionLeave;

	if (_result != JB_SL_SUCCESS) then
	{
//		[remoteExecutedOwner, _object, _listName, _result] call JB_SL_S_NotifyError;
	}
	else
	{
		[_list, _item select 1, _itemName, _memberIndex, _newValue] call JB_SL_S_NotifyItemMemberChanged;
	};
};

OO_TRACE_DECL(JB_SL_S_ListCreateItem) =
{
	params ["_object", "_listName", "_itemName"];

	private _result = JB_SL_SUCCESS;

	private _cs = _object getVariable "JB_SL_CS";
	_cs call JB_fnc_criticalSectionEnter;

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;

	private _itemIndex = -1;

	switch (typeName _itemName) do
	{
		case typeName "":
		{
			_itemIndex = _list select JB_SL_LIST_ITEMNAMES findIf { _x == _itemName };
		};

		case typeName 0:
		{
			_itemIndex = _itemName;
		};
	};

	if (itemIndex == -1) then
	{
		_result = JB_SL_ERROR_NOITEM;
	}
	else
	{
		_itemValue = _list select JB_SL_LIST_ITEMVALUES select _itemIndex;
	};

	_cs call JB_fnc_criticalSectionLeave;

	[_itemValue, _result]
};

OO_TRACE_DECL(JB_SL_S_ListOpItem) =
{
	params ["_object", "_listName", "_operatorName", "_parameters"];

	private _variableName = "JB_SL_S_" + _listName;
	private _list = _object getVariable _variableName;
	private _type = _list select JB_SL_LIST_TYPE;

	if (isNil "_type") then
	{
//		[remoteExecutedOwner, _object, _listName, JB_SL_ERROR_NOTYPE] call JB_SL_S_NotifyError;
	}
	else
	{
		private _operator = [_type, _operatorName] call JB_SL_S_TypeFindOperator;
		if (isNil "_operator") then
		{
//			[remoteExecutedOwner, _object, _listName, JB_SL_ERROR_NOOPERATOR] call JB_SL_S_NotifyError;
		}
		else
		{
			private _cs = _object getVariable "JB_SL_CS";
			_cs call JB_fnc_criticalSectionEnter;

				([_object, _listName] + _parameters) call _operator;

			_cs call JB_fnc_criticalSectionEnter;
		};
	};
};