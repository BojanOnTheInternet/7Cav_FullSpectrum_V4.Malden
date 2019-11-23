// Implementation does not support any mouse interactions other than simple clicks

JB_AH_Displays = []; // All displays

// params ["_display", "_actionName", "_actionKey", "_change", "_passthrough"]

JB_AH_CallHandlers =
{
	params ["_displayObject", "_change", ["_actionKey", -1]];

	private _display = JB_AH_Displays select ((_displayObject getVariable "JB_AH_DisplayParameters") select 0);

	private _handlers = [];
	if (_actionKey == -1) then
	{
		_handlers = _display select 1 select { inputAction (_x select 0) > 0 };
	}
	else
	{
		_handlers = _display select 1 select { _actionKey in actionKeys (_x select 0) };
	};

	private _override = false;

	{
		_result = [_displayObject, _x select 0, _change, _x select 2] call (_x select 1);
		if (not isNil "_result") then { _override = _override || _result };
	} forEach _handlers;

	_override
};

JB_AH_MouseButtonDown =
{
	params ["_display", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

	if (_button == 1) exitWith { [_display, 1, 65665] call JB_AH_CallHandlers };

	[_display, 1, 65536 + _button] call JB_AH_CallHandlers
};

JB_AH_KeyDown =
{
	params ["_display"];

	[_display, 1] call JB_AH_CallHandlers
};

JB_AH_MouseWheelChanged =
{
	params ["_display", "_change"];

	private _actionKey = if (_change > 0) then { 1048580 } else { _change = -_change; 1048581 };

	[_display, _change, _actionKey] call JB_AH_CallHandlers
};

JB_AH_ActionHandlerAdd =
{
	params ["_displayID", "_action", "_handler", ["_passthrough", 0]];

	private _display = [];
	private _displayIndex = JB_AH_Displays findIf { _x select 0 == _displayID };
	if (_displayIndex != -1) then
	{
		_display = JB_AH_Displays select _displayIndex;
	}
	else
	{
		_display = [_displayID, []];
		_displayIndex = JB_AH_Displays pushBack _display;
	};

	if (not isNull (findDisplay _displayID)) then { [_display, _displayIndex] call JB_AH_ActivateDisplay };

	_display select 1 pushBack [_action, _handler, _passthrough]
};

JB_AH_ActionHandlerRemove =
{
	params ["_displayID", "_handlerIndex"];

	private _displayIndex = JB_AH_Displays findIf { _x select 0 == _displayID };
	if (_displayIndex == -1) exitWith {};

	private _display = JB_AH_Displays select _displayIndex;
	private _handlers = _display select 1;

	_handlers set [_handlerIndex, []];

	while { count _handlers > 0 && { count (_handlers select (count _handlers - 1)) == 0 } } do
	{
		_handlers deleteAt (count _handlers - 1);
	};
};

// Critical section to make sure that one display is not activated simultaneously by two threads (the monitor and an add)
JB_AH_CS = call JB_fnc_criticalSectionCreate;

JB_AH_ActivateDisplay =
{
	params ["_display", "_displayIndex"];

	if (count (_display select 1) == 0) exitWith {}; // If no action handlers, there's no need to install the event handlers

	private _displayID = _display select 0;

	JB_AH_CS call JB_fnc_criticalSectionEnter;

		private _parameters = (findDisplay _displayID) getVariable "JB_AH_DisplayParameters";
		if (isNil "_parameters") then
		{
			private _buttonDownHandler = (findDisplay _displayID) displayAddEventHandler ["MouseButtonDown", JB_AH_MouseButtonDown];
			private _keyDownHandler = (findDisplay _displayID) displayAddEventHandler ["KeyDown", JB_AH_KeyDown];
			private _wheelHandler = (findDisplay _displayID) displayAddEventHandler ["MouseZChanged", JB_AH_MouseWheelChanged];
		
			(findDisplay _displayID) setVariable ["JB_AH_DisplayParameters", [_displayIndex, [_buttonDownHandler, _keyDownHandler, _wheelHandler]]];
		};

	JB_AH_CS call JB_fnc_criticalSectionLeave;
};

// Monitor displays.  Every display with an active ARMA display must have its event handlers installed (JB_AH_ActivateDisplay defends against doing so multiple times).
[] spawn
{
	scriptName "JB_AH_MonitorDisplays";

	while { true } do
	{
		{
			if (not isNull (findDisplay (_x select 0))) then { [_x, _forEachIndex] call JB_AH_ActivateDisplay };
		} forEach JB_AH_Displays;

		sleep 0.5;
	};
};