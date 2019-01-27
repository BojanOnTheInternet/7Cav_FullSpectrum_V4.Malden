JB_HA_FIRST_PARAMETER = 0;
JB_HA_KEYS = 0;
JB_HA_LABEL = 1;
JB_HA_DURATION = 2;
JB_HA_INTERVAL = 3;
JB_HA_CALLBACK = 4;
JB_HA_PASSTHROUGH = 5;
JB_HA_START_TIME = 6;
JB_HA_PROGRESS_STEP = 7;
JB_HA_INTERVAL_STEP = 8;
JB_HA_STATE = 9; // active, keyup, stopped
JB_HA_FOREGROUND_ICON = 10;
JB_HA_FOREGROUND_ICON_SCALE = 11;
JB_HA_LAST_PARAMETER = 11;

JB_HA_FOREGROUND_ICON_SETVALUE = 12;
JB_HA_FOREGROUND_ICON_SCALE_SETVALUE = 13;

JB_HA_NUMBER_PROGRESS_STEPS = 24;
JB_HA_BACKGROUND_CONTROL_ID = 1977;
JB_HA_FOREGROUND_CONTROL_ID = 1978;

JB_HA_CurrentAction = [];

JB_HA_KeyUp =
{
	params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

	if (count JB_HA_CurrentAction == 0 || { not (_key in (JB_HA_CurrentAction select JB_HA_KEYS)) }) exitWith { false };

	JB_HA_CurrentAction set [JB_HA_STATE, "keyup"];

	true
};

JB_HA_MouseButtonUp =
{
	params ["_control", "_button", "_x", "_y", "_isShift", "_isControl", "_isAlt"];

	if (count JB_HA_CurrentAction == 0 || { not ((_button + 65536) in (JB_HA_CurrentAction select JB_HA_KEYS)) }) exitWith { false };

	JB_HA_CurrentAction set [JB_HA_STATE, "keyup"];

	true
};

JB_HA_GetUserActionText =
{
	params ["_unit", "_action", "_icon", "_iconScale"];

	private _key = actionKeysNames ["action", 1, "keyboard"];
	_key = _key select [1, count _key - 2];

	private _text = str parseText ((_unit actionParams _action) select 0);

	[(_unit actionParams _action) select 0, [_key, _text, 0.0] call JB_HA_GetBackgroundText, [_icon, _iconScale] call JB_HA_GetForegroundText];
};

JB_HA_GetForegroundText =
{
	params ["_icon", "_iconScale"];

	format ["<t align='center'><img size='%2' image='%1'/></t>", _icon, _iconScale];
};

JB_HA_GetBackgroundText =
{
	params ["_key", "_text", "_progress"];

	if (count _text > 0) then { _text = toLower (_text select [0,1]) + (_text select [1]) };
	private _hint = format [localize "STR_A3_HoldKeyTo", format ["<t color='#ffae00'>%1</t>", toUpper _key], _text];
	
	format ["<t size='0.8' align='center'><img size='1.7' image='\a3\ui_f\data\IGUI\Cfg\HoldActions\progress\progress_%1_ca.paa'/><br/><br/>%2</t>", floor (_progress * JB_HA_NUMBER_PROGRESS_STEPS), _hint];
};