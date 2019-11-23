// [keyword name, human-readable-name, index-of-current-value, acceptable-values, human-readable-acceptable-values, mutable-after-startup]

JB_MP_GetParamIndex =
{
	params ["_name"];

	private _parameterIndex = -1;
	{ if (_x select 0 == _name) exitWith { _parameterIndex = _forEachIndex } } forEach JB_MP_Parameters;

	_parameterIndex;
};

JB_MP_GetParamValue =
{
	params ["_name"];

	private _parameterIndex = [_name] call JB_MP_GetParamIndex;
	if (_parameterIndex < 0) exitWith {};

	private _parameter = JB_MP_Parameters select _parameterIndex;

	_parameter select 3 select (_parameter select 2)
};

JB_MP_GetParamValueText =
{
	params ["_name"];

	private _parameterIndex = [_name] call JB_MP_GetParamIndex;
	if (_parameterIndex < 0) exitWith {};

	private _parameter = JB_MP_Parameters select _parameterIndex;

	_parameter select 4 select (_parameter select 2)
};

JB_MP_C_ParameterChanged =
{
	params ["_name", "_valueIndex"];

	if (isRemoteExecuted && remoteExecutedOwner != 2) exitWith {};

	private _parameterIndex = [_name] call JB_MP_GetParamIndex;

	private _parameter = JB_MP_Parameters select _parameterIndex;
	_parameter set [2, _valueIndex];

	disableSerialization;

	private _parameterDisplay = findDisplay 146;
	if (isNull _parameterDisplay) exitWith {};

	private _parameterListControl = _parameterDisplay displayCtrl 102;

	_parameterListControl lnbSetText [[_parameterIndex, 1], _parameter select 4 select (_parameter select 2)];
};

JB_MP_ChangeParameter =
{
	private _parameterListControl = (findDisplay 146 displayCtrl 102);
	private _selectedParameterIndex = lbCurSel _parameterListControl;
	private _parameter = JB_MP_Parameters select _selectedParameterIndex;

	private _selectedValueIndex = lbCurSel (findDisplay 147 displayCtrl 103);

	// Ask the server to change the value
	[_parameter select 0, _parameter select 3 select _selectedValueIndex] remoteExec ["JB_MP_S_SetParameter", 2];
};

JB_MP_EditParameter =
{
	private _selectedParameterIndex = lbCurSel (findDisplay 146 displayCtrl 102);

	if (_selectedParameterIndex == -1) exitWith {};

	private _parameter = JB_MP_Parameters select _selectedParameterIndex;

	if (_parameter select 5 == 0) exitWith {};

	disableSerialization;
	private _display = findDisplay 146 createDisplay "RscDisplayMultiplayerSetupParameter";
	private _parameterNameControl = _display displayCtrl 105;
	private _parameterValuesControl = _display displayCtrl 103;
	private _okButtonControl = _display displayCtrl 1;

	_parameterValuesControl ctrlSetEventHandler ["MouseButtonDblClick", "_this call JB_MP_ChangeParameter"];
	_okButtonControl ctrlSetEventHandler ["ButtonClick", "_this call JB_MP_ChangeParameter"];

	_parameterNameControl ctrlSetText (_parameter select 1);
	{
		_parameterValuesControl lbAdd _x;
	} forEach (_parameter select 4);

	_parameterValuesControl lbSetCurSel (_parameter select 2);
};

JB_MP_ShowParameterEditor =
{
	disableSerialization;
	private _display = findDisplay 46 createDisplay "RscDisplayMultiplayerSetupParams";
	private _parameterListControl = _display displayCtrl 102;
	private _editParameterControl = _display displayCtrl 104;

	_parameterListControl ctrlSetEventHandler ["MouseButtonDblClick", "_this call JB_MP_EditParameter"];
	_editParameterControl ctrlSetEventHandler ["ButtonClick", "_this call JB_MP_EditParameter"];

	{
		
		_parameterListControl lnbAddRow [_x select 1, (_x select 4) select (_x select 2)];
		if (_x select 5 == 0) then
		{
			_parameterListControl lnbSetColor [[_forEachIndex, 0], [0.5, 0.5, 0.5, 1.0]];
			_parameterListControl lnbSetColor [[_forEachIndex, 1], [0.5, 0.5, 0.5, 1.0]];
		};
	} forEach JB_MP_Parameters;

	_parameterListControl lbSetCurSel 0;
};

if (not isServer && hasInterface) exitWith {};

JB_MP_CS = call JB_fnc_criticalSectionCreate;

//WARNING: Parameters are not accessible via BIS_fnc_getParamValue until after "Object initialization fields are called"
// (https://community.bistudio.com/wiki/Initialization_Order).  ARMA 1.90.  As a result, this code relies on the unrecommended
// and older technique of paramsArray, which contains the parameter values.  Those values are only defined on the server at this
// point in execution.

JB_MP_Parameters = ("true" configClasses (missionConfigFile >> "Params")) apply { [configName _x, getText (_x >> "title"), "TBD", getArray (_x >> "values"), getArray (_x >> "texts"), getNumber (_x >> "mutable")] };
{
	_x set [2, (_x select 3) find (paramsArray select _forEachIndex)];
	if (count (_x select 4) == 0) then { _x set [4, (_x select 3) apply { str _x } ] };
} forEach JB_MP_Parameters;

// If a client connects, push the latest parameters to it
addMissionEventHandler ["PlayerConnected",
{
	params ["_id", "_uid", "_name", "_jip", "_owner"];

	if (_name == "__SERVER__") exitWith {};

	[JB_MP_Parameters, { JB_MP_Parameters = _this }] remoteExec ["call", _owner];
}];

JB_MP_S_SetParameter =
{
	params ["_name", "_value"];

	if (not (([] call SERVER_RemoteCallerCuratorType) in ["MC"])) exitWith {};

	JB_MP_CS call JB_fnc_criticalSectionEnter;

		private _parameterIndex = [_name] call JB_MP_GetParamIndex;

		if (_parameterIndex >= 0) then
		{
			private _parameter = JB_MP_Parameters select _parameterIndex;
		
			if (_parameter select 5 == 1) then // If mutable
			{
				private _parameterValueIndex = switch (typeName _value) do
				{
					case "SCALAR": { (_parameter select 3) find _value };
					case "STRING": { (_parameter select 4) find _value };
				};

				if (_parameterValueIndex >= 0) then
				{
					_parameter set [2, _parameterValueIndex];
					[_name, _parameter select 2] remoteExec ["JB_MP_C_ParameterChanged", 0];
				};
			};
		};

	JB_MP_CS call JB_fnc_criticalSectionLeave;
};