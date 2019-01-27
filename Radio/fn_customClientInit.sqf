params ["_showRadiosAction"];

Radio_Custom_ShowRadiosAction = _showRadiosAction;

Radio_Custom_SavedChannel = -1;

Radio_Custom_RadioSpeak =
{
	params ["_radioNumber"];

	private _override = false;

	if (Radio_Custom_SavedChannel != -1) exitWith { _override };

	private _channelIndex = [_radioNumber] call Radio_Custom_GetTunedChannelIndex;

	if (_channelIndex < 0) then
	{
		_override = true; // Don't do anything if the radio isn't tuned to a channel
	}
	else
	{
		private _radio = Radio_Custom_Radios select _radioNumber;
		if (_radio select 3 select _channelIndex select 2 != currentChannel) then
		{
			Radio_Custom_SavedChannel = currentChannel;
			setCurrentChannel (_radio select 3 select _channelIndex select 2);
		};
	};

	_override;
};

Radio_Custom_GetTunedChannelIndex =
{
	params ["_radioNumber"];

	private _radioSettings = (player getVariable "Radio_Custom_RadioSettings") select _radioNumber;

	_radioSettings select 0;
};

Radio_Custom_GetChannelText =
{
	params ["_radioNumber"];

	private _channelIndex = [_radioNumber] call Radio_Custom_GetTunedChannelIndex;

	if (_channelIndex < 0) then { "OFF" } else { Radio_Custom_Radios select _radioNumber select 3 select _channelIndex select 0 }
};

Radio_Custom_GetRadioName =
{
	params ["_radioNumber"];

	Radio_Custom_Radios select _radioNumber select 1;
};

Radio_Custom_SetRadioName =
{
	params ["_radioNumber", "_radioName"];

	(Radio_Custom_Radios select _radioNumber) set [1, _radioName];
};

Radio_Custom_RadioChannelNext =
{
	params ["_radioNumber"];

	private _override = true;

	private _radio = Radio_Custom_Radios select _radioNumber;
	private _radioSettings = (player getVariable "Radio_Custom_RadioSettings") select _radioNumber;
	private _channelIndex = _radioSettings select 0;

	if (_channelIndex == -2) exitWith { _override };

	if (_channelIndex == count (_radio select 3) - 1) exitWith { _override };

	if (_channelIndex == -1) then
	{
		_channelIndex = 0;
	}
	else
	{
		((_radio select 3 select _channelIndex select 2) - 5) radioChannelRemove [player];
		_channelIndex = _channelIndex + 1;
	};

	((_radio select 3 select _channelIndex select 2) - 5) radioChannelAdd [player];
	_radioSettings set [0, _channelIndex];

	_override;
};

Radio_Custom_RadioChannelPrev =
{
	params ["_radioNumber"];

	private _override = true;

	private _radio = Radio_Custom_Radios select _radioNumber;
	private _radioSettings = (player getVariable "Radio_Custom_RadioSettings") select _radioNumber;
	private _channelIndex = _radioSettings select 0;

	if (_channelIndex < 0) exitWith { _override };

	if (_channelIndex == 0) then
	{
		((_radio select 3 select _channelIndex select 2) - 5) radioChannelRemove [player];
		_channelIndex = -1;
	}
	else
	{
		((_radio select 3 select _channelIndex select 2) - 5) radioChannelRemove [player];
		_channelIndex = _channelIndex - 1;
		((_radio select 3 select _channelIndex select 2) - 5) radioChannelAdd [player];
	};

	_radioSettings set [0, _channelIndex];

	_override
};

Radio_Custom_RadioKeyDown =
{
	params ["_display", "_keyCode", "_shift", "_control", "_alt"];

	if (lifeState player in ["HEALTHY", "INJURED"] && { _keyCode in actionKeys Radio_Custom_ShowRadiosAction }) exitWith
	{
		[] call Radio_Custom_ShowDialog;

		true
	};

	// Restrict channel cycling to the first five channels
	// TODO: Skip whatever channels that we're using.  Other custom channels may be used by other tools.

	if (_keyCode in actionKeys "nextChannel") exitWith
	{
		private _newChannel = currentChannel;
		while { _newChannel = (_newChannel + 1) mod 6; (channelEnabled _newChannel) isEqualTo [false, false] } do {};
		setCurrentChannel _newChannel;

		true
	};

	if (_keyCode in actionKeys "prevChannel") exitWith
	{
		private _newChannel = currentChannel;
		while { _newChannel = (_newChannel + 5) mod 6; (channelEnabled _newChannel) isEqualTo [false, false] } do {};
		setCurrentChannel _newChannel;

		true
	};

	private _override = false;

	if (lifeState player in ["HEALTHY", "INJURED"]) then
	{
		{
			if (_keyCode in actionKeys (_x select 4)) exitWith { _override = [_forEachIndex] call Radio_Custom_RadioSpeak };
		} forEach Radio_Custom_Radios;
	};

	_override
};

Radio_Custom_RadioKeyUp =
{
	params ["_display", "_keyCode", "_shift", "_control", "_alt"];

	private _override = false;

	if (Radio_Custom_SavedChannel != -1) then
	{
		{
			if (_keyCode in actionKeys (_x select 4)) exitWith
			{
				[] spawn
				{
					sleep 0.1;
					setCurrentChannel Radio_Custom_SavedChannel;
					Radio_Custom_SavedChannel = -1;
				};
			};
		} forEach Radio_Custom_Radios;
	};

	_override
};

// Dialog management

#define RADIO_RADIO_CONTROL(radio) (((radio) + 1) * 1000 + 0)
#define RADIO_BACKGROUND_CONTROL(radio) (((radio) + 1) * 1000 + 1)
#define RADIO_CHANNELTEXT_CONTROL(radio) (((radio) + 1) * 1000 + 2)
#define RADIO_CHANNELNEXT_CONTROL(radio) (((radio) + 1) * 1000 + 3)
#define RADIO_CHANNELPREV_CONTROL(radio) (((radio) + 1) * 1000 + 4)
#define RADIO_NAMETEXT_CONTROL(radio) (((radio) + 1) * 1000 + 5)
#define RADIO_COLORBAND_CONTROL(radio) (((radio) + 1) * 1000 + 6)

Radio_Custom_ChannelClick =
{
	params ["_control", "_button", "_x", "_y", "_ctrl", "_shift", "_alt"];

	if (_button != 0 || { _ctrl } || { _shift } || { _alt }) exitWith {};

	private _id = ctrlIDC _control;
	private _radioNumber = floor (_id / 1000) - 1;
	private _button = _id - ((_radioNumber + 1) * 1000);

	switch (_button) do
	{
		case 3: { [_radioNumber] call Radio_Custom_RadioChannelNext};
		case 4: { [_radioNumber] call Radio_Custom_RadioChannelPrev};
	};

	private _text = [_radioNumber] call Radio_Custom_GetChannelText;

	ctrlSetText [RADIO_CHANNELTEXT_CONTROL(_radioNumber), _text];
};

Radio_Custom_MoveControl =
{
	params ["_controlID", "_shiftX"];

	private _position = ctrlPosition (findDisplay 3300 displayCtrl _controlID);
	_position set [0, (_position select 0) + _shiftX];
	(findDisplay 3300 displayCtrl _controlID) ctrlSetPosition _position;
	(findDisplay 3300 displayCtrl _controlID) ctrlCommit 0;
};

Radio_Custom_ShowRadio =
{
	params ["_radioNumber", "_shiftX"];

	(findDisplay 3300) ctrlCreate ["Radio_Radio", RADIO_RADIO_CONTROL(_radioNumber)];
	(findDisplay 3300) ctrlCreate ["Radio_ChannelBackground", RADIO_BACKGROUND_CONTROL(_radioNumber)];
	(findDisplay 3300) ctrlCreate ["Radio_ChannelText", RADIO_CHANNELTEXT_CONTROL(_radioNumber)];
	(findDisplay 3300) ctrlCreate ["Radio_ChannelNext", RADIO_CHANNELNEXT_CONTROL(_radioNumber)];
	(findDisplay 3300) ctrlCreate ["Radio_ChannelPrev", RADIO_CHANNELPREV_CONTROL(_radioNumber)];
	(findDisplay 3300) ctrlCreate ["Radio_NameText", RADIO_NAMETEXT_CONTROL(_radioNumber)];
	(findDisplay 3300) ctrlCreate ["Radio_ColorBand", RADIO_COLORBAND_CONTROL(_radioNumber)];

	[RADIO_RADIO_CONTROL(_radioNumber), _shiftX] call Radio_Custom_MoveControl;
	[RADIO_BACKGROUND_CONTROL(_radioNumber), _shiftX] call Radio_Custom_MoveControl;
	[RADIO_CHANNELTEXT_CONTROL(_radioNumber), _shiftX] call Radio_Custom_MoveControl;
	[RADIO_CHANNELNEXT_CONTROL(_radioNumber), _shiftX] call Radio_Custom_MoveControl;
	[RADIO_CHANNELPREV_CONTROL(_radioNumber), _shiftX] call Radio_Custom_MoveControl;
	[RADIO_NAMETEXT_CONTROL(_radioNumber), _shiftX] call Radio_Custom_MoveControl;
	[RADIO_COLORBAND_CONTROL(_radioNumber), _shiftX] call Radio_Custom_MoveControl;

	private _text = [_radioNumber] call Radio_Custom_GetChannelText;
	ctrlSetText [RADIO_CHANNELTEXT_CONTROL(_radioNumber), _text];

	private _text = [_radioNumber] call Radio_Custom_GetRadioName;
	ctrlSetText [RADIO_NAMETEXT_CONTROL(_radioNumber), _text];

	private _color = Radio_Custom_Radios select _radioNumber select 2;
	ctrlSetText [RADIO_COLORBAND_CONTROL(_radioNumber), format ["#(argb,8,8,3)color(%1,%2,%3,%4)", _color select 0, _color select 1, _color select 2, _color select 3]];
};

Radio_Custom_ShowDialog =
{
	if (dialog) exitWith {};

	private _dialogShown = false;

	private _offset = 0.0;
	{
		if ([_forEachIndex] call Radio_Custom_GetTunedChannelIndex != -2) then
		{
			if (not _dialogShown) then { createDialog "Radio_Radios"; _dialogShown = true };
			[_forEachIndex, _offset] call Radio_Custom_ShowRadio;
			_offset = _offset - 0.2;
		};
	} forEach Radio_Custom_Radios;
};

Radio_Custom_Unload =
{
	{
		if ([_forEachIndex] call Radio_Custom_GetTunedChannelIndex != -2) then { [_forEachIndex, ctrlText (findDisplay 3300 displayCtrl RADIO_NAMETEXT_CONTROL(_forEachIndex))] call Radio_Custom_SetRadioName };
	} forEach Radio_Custom_Radios;
};

[] spawn
{
	private _item = "";
	private _itemCount = 0;
	private _radioSettings = [];
	private _inventory = [];
	private _newInventory = [];
	private _channelIndex = 0;

	waitUntil { not isNull player };

	waitUntil { not isNull (findDisplay 46) };
	(findDisplay 46) displayAddEventHandler ["KeyDown", { _this call Radio_Custom_RadioKeyDown }];
	(findDisplay 46) displayAddEventHandler ["KeyUp", { _this call Radio_Custom_RadioKeyUp }];

	waitUntil { not isNil "Radio_Custom_Radios" }; // The server sends this to us
	// -2 Radio not carried
	// -1 Radio carried, off
	// >= 0 Radio carried, on, and tuned to a channel
	player setVariable ["Radio_Custom_RadioSettings", Radio_Custom_Radios apply { [-2] }];

	Radio_Custom_InventoryChanged = false;

	player addEventHandler ["Take", { Radio_Custom_InventoryChanged = true }];
	player addEventHandler ["Put", { Radio_Custom_InventoryChanged = true }];

	while { [{ Radio_Custom_InventoryChanged }, 10] call JB_fnc_timeoutWaitUntil; true } do
	{
		Radio_Custom_InventoryChanged = false;

		_newInventory = uniformItems player + vestItems player + backpackItems player + assignedItems player;
		if (not (_newInventory isEqualTo _inventory)) then
		{
			_inventory = _newInventory;
			{
				_item = _x select 0;
				_itemCount = { _x == _item } count _inventory;

				_radioSettings = (player getVariable "Radio_Custom_RadioSettings") select _forEachIndex;
				_channelIndex = _radioSettings select 0;

				if (_itemCount > 0) then
				{
					if (_channelIndex == -2) then { _radioSettings set [0, -1] }; // A radio is initially off when picked up
				}
				else
				{
					if (_channelIndex >= 0) then
					{
						if (_channelIndex >= 0) then { (_channelIndex - 5) radioChannelRemove [player] };
					};
					_radioSettings set [0, -2]; // Not carrying this radio
				};
			} forEach Radio_Custom_Radios;
		};
	};
};